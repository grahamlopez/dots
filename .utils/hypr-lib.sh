#!/bin/env bash
# Shared Hyprland helpers for the quake-*.sh dropdowns and hypr_lid.sh.
#
# Hyprland 0.56 added the Lua config format; the .conf format is removed in
# 0.57. Under a Lua config `hyprctl dispatch` evaluates Lua, so the legacy
# "hyprctl dispatch <name> <args>" strings no longer parse, and `hyprctl keyword`
# is rejected outright ("keyword can't work with non-legacy parsers. Use eval.").
#
# These wrappers detect which config format the running compositor uses and emit
# the matching syntax, so the scripts keep working before and after the switch,
# and if you ever roll back to hyprland.conf.

# --- format detection -------------------------------------------------------
# hl.dsp.no_op() is a no-op dispatcher that only exists in the Lua bindings; the
# legacy parser answers "Invalid dispatcher".
_HYPR_IS_LUA=

_hypr_is_lua() {
    if [ -z "$_HYPR_IS_LUA" ]; then
        if [ "$(hyprctl dispatch 'hl.dsp.no_op()' 2>&1 | head -1)" = "ok" ]; then
            _HYPR_IS_LUA=yes
        else
            _HYPR_IS_LUA=no
        fi
    fi
    [ "$_HYPR_IS_LUA" = yes ]
}

# Quote a value for Lua: bare if it is an integer, otherwise a quoted string.
_hypr_lua_val() {
    if [[ $1 =~ ^-?[0-9]+$ ]]; then printf '%s' "$1"; else printf '"%s"' "$1"; fi
}

# --- dispatchers ------------------------------------------------------------

# hypr_exec <command...>
# Float, size and placement come from the window rules in hyprland.lua, so the
# exec rules the quake-*.sh scripts used to pass ("[float; size W H]") are gone.
hypr_exec() {
    if _hypr_is_lua; then
        hyprctl dispatch "hl.dsp.exec_cmd([[$*]])"
    else
        hyprctl dispatch -- exec "$@"
    fi
}

# hypr_move_to_workspace <workspace> <selector>
# was: hyprctl dispatch movetoworkspace "<workspace>,<selector>"
hypr_move_to_workspace() {
    if _hypr_is_lua; then
        hyprctl dispatch "hl.dsp.window.move({ workspace = $(_hypr_lua_val "$1"), window = \"$2\" })"
    else
        hyprctl dispatch movetoworkspace "$1,$2"
    fi
}

# There is deliberately no hypr_move_to_workspace_silent: the Lua bindings have
# no silent variant of hl.dsp.window.move (a `silent` key is accepted and then
# ignored), so a "silent" move showed the target workspace instead of hiding the
# window. hypr_dropdown below toggles the special workspace instead.
#
# hypr_center_and_raise is gone too -- centring and raising are window rules in
# hyprland.lua now, so they apply as the window maps rather than after the fact.

# hypr_toggle_special <name>
# was: hyprctl dispatch togglespecialworkspace <name>
hypr_toggle_special() {
    if _hypr_is_lua; then
        hyprctl dispatch "hl.dsp.workspace.toggle_special(\"$1\")"
    else
        hyprctl dispatch togglespecialworkspace "$1"
    fi
}

# hypr_focus_window <selector>      e.g. address:0x..., class:foo
# was: hyprctl dispatch focuswindow <selector>
hypr_focus_window() {
    if _hypr_is_lua; then
        hyprctl dispatch "hl.dsp.focus({ window = \"$1\" })"
    else
        hyprctl dispatch focuswindow "$1"
    fi
}

# hypr_dropdown <class> <command...>
#
# The whole quake-*.sh toggle. Each dropdown lives on the special workspace named
# after its window class, so:
#   not running        -> launch it; the window rules float, size, place it and
#                         put it on special:<class>, which shows it
#   on special:<class> -> toggle that special workspace (show <-> hide)
#   anywhere else      -> someone dragged it out of the dropdown; adopt it back
#                         onto special:<class>, which also brings it into view
#
# Whenever the window ends up visible we focus it explicitly. The dropdowns no
# longer carry a `stay_focused` rule -- that pinned focus to them and was what
# stopped you using windows behind them -- so this is what makes focus reliably
# *start* on the dropdown. input.special_fallthrough then lets focus follow the
# mouse onto whatever is underneath.
hypr_dropdown() {
    local class=$1 ws was_shown; shift
    ws=$(hyprctl clients -j | jq -r --arg c "$class" \
        'first(.[] | select(.class == $c) | .workspace.name) // ""')
    if [ -z "$ws" ]; then
        hypr_exec "$@"                                          # new window takes focus itself
    elif [ "$ws" != "special:$class" ]; then
        hypr_move_to_workspace "special:$class" "class:$class"
        hypr_focus_window "class:$class"
    else
        was_shown=$(hyprctl monitors -j | jq -r \
            'first(.[] | select(.focused) | .specialWorkspace.name) // ""')
        hypr_toggle_special "$class"
        [ "$was_shown" = "special:$class" ] || hypr_focus_window "class:$class"
    fi
}

# --- keywords ---------------------------------------------------------------

# hypr_monitor <output> <mode> <position> <scale>
# was: hyprctl keyword monitor "<output>, <mode>, <position>, <scale>"
hypr_monitor() {
    if _hypr_is_lua; then
        hyprctl eval "hl.monitor({ output = \"$1\", mode = \"$2\", position = \"$3\", scale = $4 })"
    else
        hyprctl keyword monitor "$1, $2, $3, $4"
    fi
}

# hypr_monitor_disable <output>
# was: hyprctl keyword monitor "<output>, disable"
hypr_monitor_disable() {
    if _hypr_is_lua; then
        hyprctl eval "hl.monitor({ output = \"$1\", disabled = true })"
    else
        hyprctl keyword monitor "$1, disable"
    fi
}
