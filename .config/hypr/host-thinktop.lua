-- Host overrides: thinktop (ThinkPad laptop)

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.33 })

hl.config({
    decoration = {
        rounding = 5,

        -- Change transparency of focused and unfocused windows
        active_opacity     = 0.80,
        inactive_opacity   = 0.80,
        fullscreen_opacity = 0.80,
    },
})

hl.device({
    name          = "tpps/2-elan-trackpoint",
    sensitivity   = -0.30,
    accel_profile = "adaptive",
})
