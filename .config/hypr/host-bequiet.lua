-- Host overrides: bequiet (NVIDIA desktop)

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })

hl.env("WLR_NO_HARDWARE_CURSORS", "1")

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
