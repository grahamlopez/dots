/**
 * Research Extension
 *
 * Provides a `research` tool that asks Perplexity a question via the NVIDIA inference API.
 * Stateless single-shot: one question in, one answer out. The main agent handles follow-up
 * logic by asking sharper standalone questions based on prior answers already in its context.
 */

import { complete } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";

const PROVIDER = "nvinf-perplexity";
const MODEL_ID = "perplexity/perplexity/sonar-pro";

const SYSTEM_PROMPT = `You are a research assistant. Answer questions thoroughly and concisely.
Include sources and citations when available. Structure your response with clear headings
when the answer has multiple parts. If you're uncertain about something, say so explicitly.`;

interface ResearchDetails {
	model: string;
	stopReason: string | undefined;
	inputTokens: number;
	outputTokens: number;
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "research",
		label: "Research",
		description:
			"Ask Perplexity an open-ended research question. Returns a single comprehensive answer. " +
			"Best for questions where you don't know where to look — broad research, comparisons, " +
			"best practices, tradeoff analysis, or exploring unfamiliar topics.",
		promptGuidelines: [
			"Use `research` for open-ended questions where you don't have a specific URL — e.g. 'what are the tradeoffs between X and Y', 'how do people typically handle Z', 'what's the current best practice for W'.",
			"Do NOT use `research` when you already know the URL or documentation page — use `web_fetch` instead.",
			"Do NOT use `research` for questions answerable from the project's own code, files, or context already in the conversation.",
			"Ask one well-formed, self-contained question per call. Include relevant context in the question itself (e.g. library versions, language, constraints) so the answer is targeted.",
		],
		parameters: Type.Object({
			question: Type.String({ description: "A clear, self-contained research question" }),
		}),

		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const model = ctx.modelRegistry.find(PROVIDER, MODEL_ID);
			if (!model) {
				throw new Error(
					`Model ${MODEL_ID} not found on provider ${PROVIDER}. ` +
					`Check that nvinf-perplexity is configured in models.json.`,
				);
			}

			const apiKey = await ctx.modelRegistry.getApiKey(model);
			if (!apiKey) {
				throw new Error(`No API key available for provider ${PROVIDER}. Check NVINF_KEY is set.`);
			}

			const response = await complete(
				model,
				{
					systemPrompt: SYSTEM_PROMPT,
					messages: [
						{
							role: "user",
							content: [{ type: "text", text: params.question }],
							timestamp: Date.now(),
						},
					],
				},
				{ apiKey, signal },
			);

			if (response.stopReason === "aborted") {
				throw new Error("Research request was cancelled.");
			}

			const answer = response.content
				.filter((c): c is { type: "text"; text: string } => c.type === "text")
				.map((c) => c.text)
				.join("\n");

			const details: ResearchDetails = {
				model: model.id,
				stopReason: response.stopReason,
				inputTokens: response.usage?.input ?? 0,
				outputTokens: response.usage?.output ?? 0,
			};

			return {
				content: [{ type: "text", text: answer || "(no response from Perplexity)" }],
				details,
			};
		},

		renderCall(args, theme) {
			const question = args.question ?? "...";
			const preview = question.length > 80 ? `${question.slice(0, 80)}...` : question;
			return new Text(
				theme.fg("toolTitle", theme.bold("research ")) + theme.fg("dim", preview),
				0, 0,
			);
		},

		renderResult(result, { expanded }, theme) {
			const details = result.details as ResearchDetails | undefined;

			if (result.isError) {
				const errText = result.content[0]?.type === "text" ? result.content[0].text : "Unknown error";
				return new Text(theme.fg("error", errText), 0, 0);
			}

			const content = result.content[0];
			const text = content?.type === "text" ? content.text : "(no output)";
			const lines = text.split("\n");

			let header = theme.fg("success", "✓");
			if (details) {
				const tokens = `↑${details.inputTokens} ↓${details.outputTokens}`;
				header += theme.fg("dim", ` ${tokens}`);
			}

			if (expanded) {
				return new Text(header + "\n" + text, 0, 0);
			}

			// Collapsed: show first few lines
			const preview = lines.slice(0, 6).join("\n");
			let collapsed = header + "\n" + theme.fg("fg", preview);
			if (lines.length > 6) {
				collapsed += "\n" + theme.fg("muted", `... ${lines.length - 6} more lines (Ctrl+O to expand)`);
			}
			return new Text(collapsed, 0, 0);
		},
	});
}
