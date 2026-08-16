-- Hyprland configuration (Lua format).
-- Migrated from hyprland.conf; the .conf format is removed in Hyprland 0.57.
-- Refer to the wiki: https://wiki.hypr.land/Configuring/Start/
--
-- Split config: host-specific overrides live in host-<hostname>.lua and are
-- required at the bottom of this file.


------------------
---- MONITORS ----
------------------

-- Monitors are configured per host, see host-*.lua at the bottom of this file.

-- FIXME: this doesn't work. manually run the lid open script
-- hl.monitor({ output = "", mode = "preferred", position = "auto" })
-- hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto-down" })  -- laptop screen below externals

-- Enable clamshell mode: turn off laptop monitor when lid is closed
-- hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("/home/graham/.utils/hypr_lid.sh close"), { locked = true })
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("/home/graham/.utils/hypr_lid.sh open"),  { locked = true })

-- Monitor hotplug detection
-- hl.on("monitor.added",   function() hl.exec_cmd("/home/graham/.utils/hypr_lid.sh check") end)
-- hl.on("monitor.removed", function() hl.exec_cmd("/home/graham/.utils/hypr_lid.sh check") end)


---------------------
---- MY PROGRAMS ----
---------------------

local terminal         = "kitty"
local terminal_trusted = [[kitty -o clipboard_control="write-clipboard write-primary read-clipboard read-primary no-ask"]]
local fileManager      = "dolphin"
local menu             = "wofi --show drun"
local dropterm         = os.getenv("HOME") .. "/.utils/quake-term.sh"
local dropperp         = os.getenv("HOME") .. "/.utils/quake-perp.sh"
local dropnote         = os.getenv("HOME") .. "/.utils/quake-note.sh"
local dropbook         = os.getenv("HOME") .. "/.utils/quake-book.sh"
local dropclip         = os.getenv("HOME") .. "/.utils/quake-clip.sh"
local browser          = "firefox-bin"
local screenshot       = [[sh -c 'file=/home/graham/Downloads/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png; slurp | grim -g - "$file" && wl-copy < "$file"']]


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd(terminal)
    hl.exec_cmd("/home/graham/.utils/tmux-at-startup.sh")
    -- need a firefox instance open for quake-perp to work right
    -- hl.exec_cmd(browser, { workspace = "1", silent = true })
    hl.exec_cmd("hyprpaper")
    -- watch for clipboard changes and record with 'cliphist'
    hl.exec_cmd("wl-paste --type text --watch cliphist store")

    hl.exec_cmd("hyprctl setcursor Adwaita 24")
    -- set new mouse cursors for gtk/gnome applications
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Adwaita")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 9,
        gaps_out = 12,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before turning this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = 5,

        -- Change transparency of focused and unfocused windows
        active_opacity     = 0.90,
        inactive_opacity   = 0.90,
        fullscreen_opacity = 0.90,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size    = 4,
            passes  = 1,
            -- vibrancy          = 0.2,
            -- vibrancy_darkness = 0.1,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Curves, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- "Smart gaps" / "No gaps when only" -- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]"   }, border_size = 0, rounding = 0 })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
-- NOTE: dwindle.pseudotile no longer exists (removed in 0.56). Pseudotiling is
-- now purely per-window via the pseudo dispatcher, bound to SUPER + P below.
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})


---------------
---- INPUT ----
---------------

-- alternative kb_options group-switch triggers
-- grp:win_space_toggle   -> Super (Win) + Space
-- grp:alt_space_toggle   -> Alt + Space
-- grp:shifts_toggle      -> both Shift keys together
-- grp:alts_toggle        -> both Alt keys together
-- grp:ctrls_toggle       -> both Ctrl keys together
-- grp:caps_toggle        -> Caps Lock
-- grp:shift_caps_toggle  -> Shift + Caps Lock
-- grp:alt_caps_toggle    -> Alt + Caps Lock
-- grp:lwin_toggle / grp:rwin_toggle -> left or right Super key
--
-- NOTE: the old .conf had two separate `kb_options` lines (ctrl:nocaps and
-- grp:win_space_toggle); the second silently overrode the first, so only
-- grp:win_space_toggle was ever active. That behaviour is preserved here.
-- ctrl:nocaps is redundant anyway: keyd already maps capslock to
-- overload(control, esc) in /etc/keyd/default.conf. To enable both xkb options
-- anyway, use a single comma-separated string: "ctrl:nocaps,grp:win_space_toggle"
hl.config({
    input = {
        kb_layout  = "us,gr",
        kb_variant = ",polytonic",
        kb_model   = "",
        kb_options = "grp:win_space_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        -- A shown special workspace normally swallows all focus, which is what
        -- used to make a visible dropdown block the windows behind it. With
        -- special_fallthrough, a special workspace holding only floating windows
        -- (which is exactly what the dropdowns are) lets focus fall through to
        -- the regular workspace underneath, so follow_mouse works as usual and
        -- you can mouse onto a window behind the dropdown and use it.
        special_fallthrough = true,

        -- Keep focus where a dispatcher put it until the mouse actually crosses
        -- a window boundary. Without this, showing a dropdown while the cursor
        -- happens to rest over a background window hands focus straight back to
        -- that window; with it, a freshly shown dropdown always starts focused
        -- no matter where the pointer is sitting.
        mouse_refocus = false,

        sensitivity = 0.5, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },

        repeat_delay = 500, -- try 500-700 instead of the default ~300
        repeat_rate  = 30,  -- slower repeats (defaults are often 30-40)
    },
})

-- Per-device config, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name        = "logitech-m510",
    sensitivity = 0.3,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- ALT + tab cycles through every window *visible* on the focused monitor: the
-- ones on its active workspace, plus -- when a dropdown is showing -- the ones on
-- the special workspace it is displaying.
--
-- The built-in cycle_next() only ever walks the active workspace, and while a
-- dropdown is up that workspace *is* the dropdown's special workspace, so it
-- could only ever find the dropdown itself and there was no keyboard way back to
-- the window behind it. With no dropdown showing this behaves exactly like
-- cycle_next() did.
local function cycle_visible(step)
    return function()
        local mon = hl.get_active_monitor()
        if not mon then return end

        -- Special workspace first, so tabbing off a dropdown lands on the
        -- workspace behind it rather than wrapping around within the dropdown.
        -- Append conditionally rather than building {special, active} and
        -- iterating that: with nothing showing the first element is nil, and
        -- ipairs would stop dead on the hole and find no windows at all.
        local workspaces = {}
        local special = hl.get_active_special_workspace(mon)
        if special then workspaces[#workspaces + 1] = special end
        local current = hl.get_active_workspace(mon)
        if current then workspaces[#workspaces + 1] = current end

        local windows = {}
        for _, ws in ipairs(workspaces) do
            for _, w in ipairs(hl.get_workspace_windows(ws)) do
                windows[#windows + 1] = w
            end
        end
        if #windows < 2 then return end

        local active, index = hl.get_active_window(), 1
        if active then
            for i, w in ipairs(windows) do
                if w.address == active.address then index = i break end
            end
        end

        hl.dispatch(hl.dsp.focus({ window = windows[(index - 1 + step) % #windows + 1] }))
    end
end

hl.bind("ALT + tab",         cycle_visible(1))
hl.bind("ALT + SHIFT + tab", cycle_visible(-1))

hl.bind(mainMod .. " + X",         hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd(terminal_trusted))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Q",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + M",         hl.dsp.exit())
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T",         hl.dsp.window.set_prop({ prop = "opaque", value = "toggle" }))
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",         hl.dsp.window.pseudo()) -- dwindle
-- hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit")) -- dwindle

-- The old .conf wrote these as `Control_L`, which Hyprland parsed as the plain
-- CTRL modifier (not specifically the left key), so CTRL is the exact equivalent.
hl.bind("CTRL + 0", hl.dsp.exec_cmd(dropclip))
hl.bind("CTRL + 9", hl.dsp.exec_cmd(dropterm))
hl.bind("CTRL + 8", hl.dsp.exec_cmd(dropbook))
hl.bind("CTRL + 7", hl.dsp.exec_cmd(dropperp))
-- this may need to be customized per machine
hl.bind("Print", hl.dsp.exec_cmd(screenshot))

-- Move focus with mainMod + hjkl
-- hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
-- hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
-- hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
-- hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.window.move({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging (was bindm).
-- NOTE: the upstream example config passes `{ mouse = true }` here, but there is
-- no such bind option -- it is silently ignored, so the bare form below is what
-- upstream actually runs. Do not use `{ drag = true }`: that is a different
-- feature which only fires the bind after the pointer travels
-- binds:drag_threshold pixels.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                        { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Kitty always fully opaque.
-- The opacity string is "<active> [override] <inactive> [override] [<fullscreen> [override]]".
hl.window_rule({
    name    = "kitty-opaque",
    match   = { class = "^(kitty)$" },
    opacity = "1.0 override 1.0 override",
})
-- The above rule doesn't override fullscreen opacity, so kitty falls back to the
-- global fullscreen_opacity (0.90) when fullscreened. To fix, use instead:
-- opacity = "1.0 override 1.0 override 1.0 override",


---- Dropdown ("quake") windows ----
--
-- Each dropdown now lives permanently on its own special workspace, and
-- ~/.utils/quake-*.sh shows/hides it with hl.dsp.workspace.toggle_special().
--
-- That replaces the old shuffle between the current workspace and
-- special:<class>, which depended on the legacy `movetoworkspacesilent`
-- dispatcher. hl.dsp.window.move has no silent variant -- a `silent` key is
-- accepted and ignored -- so the "hide" step moved the window to the special
-- workspace *and pulled that workspace into view*, which is why pressing the
-- key a second time stopped hiding the window.
--
-- Size and position are rules now instead of a post-spawn `centerwindow` +
-- `moveactive -N%` dance, and are fractions of the monitor rather than fixed
-- pixels, so the windows keep their proportions on any machine / monitor /
-- resolution. The fractions below reproduce the previous pixel geometry on this
-- 2880x1800 logical desktop. `raise` is the old hypr_center_and_raise argument:
-- 0 = centred, 1 = flush with the top of the monitor.
--
-- `size` and `move` take an "expression vec2": two expressions separated by
-- whitespace, so the expressions themselves must not contain spaces.
-- monitor_w/monitor_h are the monitor's logical size. Note that plain
-- percentages ("50% 25%") are accepted but silently have no effect here, unlike
-- the legacy `windowrulev2 = size 50% 25%`.
local function dropdown_geometry(class, fw, fh, raise)
    local match = { class = "^(" .. class .. ")$" }
    hl.window_rule({ name = class .. "-float", match = match, float = true })
    hl.window_rule({
        name  = class .. "-size",
        match = match,
        size  = ("monitor_w*%.6f monitor_h*%.6f"):format(fw, fh),
    })
    hl.window_rule({
        name  = class .. "-move",
        match = match,
        move  = ("monitor_w*%.6f monitor_h*%.6f"):format((1 - fw) / 2, (1 - fh) / 2 * (1 - raise)),
    })
end

local function dropdown(class, fw, fh, raise)
    dropdown_geometry(class, fw, fh, raise)
    hl.window_rule({
        name      = class .. "-workspace",
        match     = { class = "^(" .. class .. ")$" },
        workspace = "special:" .. class,
    })
end

dropdown("dropdown",  1200 / 2880,  600 / 1800, 0.80)  -- CTRL + 9, quake-term.sh
dropdown("notesdown", 1200 / 2880,  800 / 1800, 0.80)  --           quake-note.sh
dropdown("booksdown", 1200 / 2880,  800 / 1800, 0.80)  -- CTRL + 8, quake-book.sh
dropdown("perpdown",  1400 / 2880, 1300 / 1800, 0.50)  -- CTRL + 7, quake-perp.sh

-- CTRL + 0, quake-clip.sh: a one-shot picker that exits once you choose, so it
-- gets the geometry but no special workspace of its own.
dropdown_geometry("clipdown", 1200 / 2880, 600 / 1800, 0.80)

-- The dropdown terminal is additionally fully opaque.
hl.window_rule({
    name    = "dropdown-opaque",
    match   = { class = "^(dropdown)$" },
    opacity = "1.0 override 1.0 override",
})
-- There used to be a `stay_focused` rule here. It pinned focus to the dropdown
-- for as long as the window was visible, which is what stopped you mousing onto
-- a window behind it. quake-*.sh focuses the dropdown explicitly when it shows
-- it instead, so it still *starts* focused, and input.mouse_refocus = false
-- keeps that focus until you deliberately move the pointer off it.

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland: do not focus initially
hl.window_rule({
    name              = "fix-xwayland-drags",
    match             = { class = "^$", title = "^$", xwayland = true },
    no_initial_focus  = true,
})


-------------------------------
---- HOST SPECIFIC OVERRIDES --
-------------------------------

-- Replaces the old `ln -sf hypr-$HOSTNAME.conf hostname-specific.conf` +
-- `source =` dance: read the hostname directly and require host-<hostname>.lua.
local function hostname()
    local f = io.open("/proc/sys/kernel/hostname", "r")
    if not f then return nil end
    local h = f:read("l")
    f:close()
    return h
end

local host = hostname()
if host then
    -- expose ${HOSTNAME} to the environment for child processes
    hl.env("HOSTNAME", host)

    local ok, err = pcall(require, "host-" .. host)
    if not ok then
        print("no host config for '" .. host .. "': " .. tostring(err))
    end
end
