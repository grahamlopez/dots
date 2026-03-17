/**
 * Web Fetch Extension
 *
 * Provides a `web_fetch` tool that fetches a URL and returns clean Markdown.
 *
 * Pipeline: fetch → parse HTML (linkedom) → extract article (Readability) → convert to Markdown (Turndown)
 *
 * Falls back gracefully:
 * - If Readability can't extract an article, converts the full <body> to Markdown
 * - If the response isn't HTML (JSON, plain text, etc.), returns it directly
 *
 * Output is truncated to 2000 lines / 50KB to stay within context limits.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
} from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { Readability } from "@mozilla/readability";
import { parseHTML } from "linkedom";
import TurndownService from "turndown";

interface FetchDetails {
	url: string;
	status: number;
	contentType: string;
	title?: string;
	byline?: string;
	excerpt?: string;
	siteName?: string;
	truncated: boolean;
}

function htmlToMarkdown(html: string, url: string): { markdown: string; title?: string; byline?: string; excerpt?: string; siteName?: string } {
	const { document } = parseHTML(html);

	// Remove script, style, nav, footer, and other non-content elements before Readability runs
	for (const tag of ["script", "style", "noscript", "svg", "iframe"]) {
		for (const el of document.querySelectorAll(tag)) {
			el.remove();
		}
	}

	// Try Readability first — extracts the main article content
	const reader = new Readability(document, { charThreshold: 100 });
	const article = reader.parse();

	const turndown = new TurndownService({
		headingStyle: "atx",
		codeBlockStyle: "fenced",
		bulletListMarker: "-",
	});

	// Drop images — they're noise for an LLM
	turndown.addRule("removeImages", {
		filter: "img",
		replacement: () => "",
	});

	let markdown: string;
	let title: string | undefined;
	let byline: string | undefined;
	let excerpt: string | undefined;
	let siteName: string | undefined;

	if (article?.content) {
		markdown = turndown.turndown(article.content);
		title = article.title ?? undefined;
		byline = article.byline ?? undefined;
		excerpt = article.excerpt ?? undefined;
		siteName = article.siteName ?? undefined;
	} else {
		// Readability couldn't extract an article — fall back to full body
		const body = document.querySelector("body");
		title = document.querySelector("title")?.textContent ?? undefined;
		markdown = body ? turndown.turndown(body.innerHTML) : "(empty page)";
	}

	// Build a header with metadata
	const parts: string[] = [];
	if (title) parts.push(`# ${title}`);
	if (byline) parts.push(`*${byline}*`);
	if (siteName) parts.push(`Source: ${siteName}`);
	parts.push(`URL: ${url}`);
	parts.push("---");
	parts.push(markdown);

	return { markdown: parts.join("\n\n"), title, byline, excerpt, siteName };
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			`Fetch a URL and return its content as clean Markdown. ` +
			`Works well for documentation, articles, blog posts, API references, and other text-heavy pages. ` +
			`Does not execute JavaScript, so single-page apps that require JS to render will return minimal content. ` +
			`Output is truncated to ${DEFAULT_MAX_LINES} lines or ${formatSize(DEFAULT_MAX_BYTES)}.`,
		promptGuidelines: [
			"Use web_fetch to look up documentation, references, or any web content the user points you to.",
			"web_fetch does not execute JavaScript — if a page requires JS to render, try finding a raw/plain version of the URL instead.",
		],
		parameters: Type.Object({
			url: Type.String({ description: "URL to fetch (must include protocol, e.g. https://)" }),
		}),

		async execute(_toolCallId, params, signal) {
			const { url } = params;

			// Fetch with a reasonable timeout and a browser-like User-Agent
			const controller = new AbortController();
			if (signal) {
				signal.addEventListener("abort", () => controller.abort());
			}
			const timeout = setTimeout(() => controller.abort(), 30_000);

			let resp: Response;
			try {
				resp = await fetch(url, {
					signal: controller.signal,
					headers: {
						"User-Agent": "Mozilla/5.0 (compatible; pi-coding-agent/1.0)",
						Accept: "text/html, application/xhtml+xml, application/json, text/plain, */*",
					},
					redirect: "follow",
				});
			} catch (err: any) {
				if (err.name === "AbortError") {
					throw new Error(`Request timed out or was cancelled for: ${url}`);
				}
				throw new Error(`Failed to fetch ${url}: ${err.message}`);
			} finally {
				clearTimeout(timeout);
			}

			if (!resp.ok) {
				throw new Error(`HTTP ${resp.status} ${resp.statusText} for ${url}`);
			}

			const contentType = resp.headers.get("content-type") ?? "unknown";
			const body = await resp.text();

			let output: string;
			let title: string | undefined;
			let byline: string | undefined;
			let excerpt: string | undefined;
			let siteName: string | undefined;

			if (contentType.includes("html") || contentType.includes("xhtml")) {
				const result = htmlToMarkdown(body, url);
				output = result.markdown;
				title = result.title;
				byline = result.byline;
				excerpt = result.excerpt;
				siteName = result.siteName;
			} else if (contentType.includes("json")) {
				// Pretty-print JSON
				try {
					output = JSON.stringify(JSON.parse(body), null, 2);
				} catch {
					output = body;
				}
			} else {
				// Plain text, XML, etc. — return as-is
				output = body;
			}

			// Truncate
			const truncation = truncateHead(output, {
				maxLines: DEFAULT_MAX_LINES,
				maxBytes: DEFAULT_MAX_BYTES,
			});

			let resultText = truncation.content;
			if (truncation.truncated) {
				resultText += `\n\n[Output truncated: showing ${truncation.outputLines} of ${truncation.totalLines} lines`;
				resultText += ` (${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}).`;
				resultText += ` Use web_fetch on a more specific URL or ask the user for the relevant section.]`;
			}

			const details: FetchDetails = {
				url,
				status: resp.status,
				contentType,
				title,
				byline,
				excerpt,
				siteName,
				truncated: truncation.truncated,
			};

			return {
				content: [{ type: "text", text: resultText }],
				details,
			};
		},

		renderCall(args, theme) {
			let text = theme.fg("toolTitle", theme.bold("web_fetch "));
			text += theme.fg("accent", args.url ?? "");
			return new Text(text, 0, 0);
		},

		renderResult(result, { expanded, isPartial }, theme) {
			const details = result.details as FetchDetails | undefined;

			if (isPartial) {
				return new Text(theme.fg("warning", "Fetching..."), 0, 0);
			}

			if (result.isError) {
				const errText = result.content[0]?.type === "text" ? result.content[0].text : "Unknown error";
				return new Text(theme.fg("error", errText), 0, 0);
			}

			if (!details) {
				return new Text(theme.fg("dim", "No details"), 0, 0);
			}

			// Summary line
			let text = theme.fg("success", `${details.status} OK`);
			if (details.title) {
				text += theme.fg("dim", " — ") + theme.fg("fg", details.title);
			}
			if (details.truncated) {
				text += " " + theme.fg("warning", "(truncated)");
			}

			if (expanded) {
				const content = result.content[0];
				if (content?.type === "text") {
					const lines = content.text.split("\n").slice(0, 30);
					for (const line of lines) {
						text += `\n${theme.fg("dim", line)}`;
					}
					if (content.text.split("\n").length > 30) {
						text += `\n${theme.fg("muted", "...")}`;
					}
				}
			}

			return new Text(text, 0, 0);
		},
	});
}
