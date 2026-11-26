"""
AngelHub v3.0
Platform : Windows (Dear PyGui overlay) + Android (Kivy overlay, root or Termux)
Requires :
  Windows  — pip install dearpygui pymem Pillow
  Android  — pip install kivy pillow (via Termux or APK runner)
Run as Administrator on Windows for SendInput + pymem.
FILL markers show every game-specific value Sam needs to supply.
"""

import sys, os, math, json, threading, time, platform

PLATFORM = platform.system()   # "Windows" or "Linux" (Android Termux = Linux)
IS_WIN   = PLATFORM == "Windows"
IS_AND   = not IS_WIN           # treat Linux/Android as Android path

DISCORD_LINK = "https://discord.gg/d8gpXNGknP"
CFG_PATH     = "angelhub_cfg.json"

# ══════════════════════════════════════════════════════════════════════════════
# CONFIG
# ══════════════════════════════════════════════════════════════════════════════
cfg = {
    # Combat
    "aimbot_enabled":      False,
    "aimbot_smoothness":   45,
    "fov_radius":          120,
    "fov_filled":          False,
    "fov_color":           [0, 200, 230, 80],
    "target_bone":         "Head",
    "team_check":          True,
    "draw_fov":            True,
    "aimbot_key":          0x56,      # V  (Windows only)

    "silent_aim_enabled":  False,
    "silent_fov":          90,
    "silent_smoothness":   30,
    "silent_bone":         "Head",
    "silent_key":          0x58,      # X

    # Visuals
    "esp_enabled":         False,
    "box_esp":             True,
    "name_esp":            True,
    "health_bar":          True,
    "skeleton_esp":        False,
    "distance_esp":        True,
    "tracer_esp":          False,
    "esp_color":           [0, 220, 255, 255],
    "enemy_color":         [255, 60, 60, 255],
    "team_color":          [60, 255, 100, 255],
    "chams_enabled":       False,

    # Misc
    "noclip":              False,
    "speed_boost":         False,
    "speed_value":         16,        # studs/s Roblox default=16
    "jump_boost":          False,
    "jump_value":          50,        # Roblox JumpPower default=50
    "infinite_jump":       False,
    "fly_enabled":         False,
    "fly_speed":           50,
    "anti_ragdoll":        False,
    "auto_rejoin":         False,
    "spin_bot":            False,
    "spin_speed":          10,

    # World
    "no_flash":            False,
    "fullbright":          False,
    "radar":               False,
    "remove_fog":          False,
    "time_of_day":         "Default",

    # Settings
    "menu_key":            0x2D,      # INSERT
    "panic_key":           0x23,      # END
    "fps_limit":           240,
    "ui_scale":            1.0,
    "mobile_btn_x":        40,
    "mobile_btn_y":        40,
    "target_process":      "RobloxPlayerBeta.exe",
}

BONES    = ["Head","Neck","Chest","Pelvis","Left Shoulder","Right Shoulder","Left Knee","Right Knee"]
TOD_OPTS = ["Default","Morning","Noon","Evening","Night"]

def save_cfg():
    with open(CFG_PATH, "w") as f:
        json.dump(cfg, f, indent=2)

def load_cfg():
    if os.path.exists(CFG_PATH):
        try:
            with open(CFG_PATH) as f:
                cfg.update(json.load(f))
        except Exception:
            pass

# ══════════════════════════════════════════════════════════════════════════════
# LOGO — generates an AngelHub logo PNG via Pillow (no external asset needed)
# ══════════════════════════════════════════════════════════════════════════════
LOGO_PATH = "angelhub_logo.png"

def generate_logo():
    try:
        from PIL import Image, ImageDraw, ImageFont
        size = 128
        img  = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        d    = ImageDraw.Draw(img)

        # outer glow ring
        for i in range(6, 0, -1):
            alpha = int(40 * (i / 6))
            d.ellipse([i, i, size - i, size - i],
                      outline=(0, 200, 230, alpha), width=1)

        # main circle
        d.ellipse([10, 10, size - 10, size - 10],
                  outline=(0, 200, 230, 255), width=3)
        d.ellipse([14, 14, size - 14, size - 14],
                  fill=(8, 18, 32, 220))

        # angel wings — two arcs left and right
        d.arc([12, 30, 58, 90],  start=200, end=340, fill=(0, 200, 230, 200), width=4)
        d.arc([70, 30, 116, 90], start=200, end=340, fill=(0, 200, 230, 200), width=4)

        # halo
        d.arc([44, 10, 84, 30], start=0, end=180, fill=(0, 230, 255, 255), width=3)

        # "AH" text center
        try:
            font = ImageFont.truetype("arialbd.ttf", 28)
        except Exception:
            font = ImageFont.load_default()
        bbox = d.textbbox((0, 0), "AH", font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text(((size - tw) // 2, (size - th) // 2 + 6),
               "AH", font=font, fill=(0, 220, 255, 255))

        img.save(LOGO_PATH)
        return LOGO_PATH
    except Exception:
        return None

# ══════════════════════════════════════════════════════════════════════════════
# GAME BRIDGE — stubs, wire per-game below
# ══════════════════════════════════════════════════════════════════════════════
pm = None

def try_attach():
    global pm
    if not IS_WIN:
        return
    try:
        import pymem
        pm = pymem.Pymem(cfg["target_process"])
    except Exception:
        pm = None

def read_entity_head() -> tuple[int,int] | None:
    """
    Return (screen_x, screen_y) of nearest visible enemy head or None.
    FILL: walk DataModel->Players->Character->Head CFrame, run W2S.
    """
    return None

def silent_aim_patch(target: tuple[int,int] | None):
    """
    FILL: compute angle delta screen_center->target, write to view angles.
    Roblox: write Camera.CFrame via memory or executor.
    """
    pass

def apply_noclip(state: bool):
    """FILL: toggle Roblox character CanCollide."""
    pass

def apply_speed(value: int):
    """FILL: write Humanoid.WalkSpeed."""
    pass

def apply_jump(value: int):
    """FILL: write Humanoid.JumpPower."""
    pass

def apply_fly(state: bool, speed: int):
    """FILL: toggle BodyVelocity fly hack."""
    pass

def apply_fullbright(state: bool):
    """FILL: write Lighting.Brightness / Ambient."""
    pass

def apply_fog(state: bool):
    """FILL: write Lighting.FogEnd to max."""
    pass

# ══════════════════════════════════════════════════════════════════════════════
# WINDOWS INPUT
# ══════════════════════════════════════════════════════════════════════════════
if IS_WIN:
    import ctypes
    from ctypes import wintypes
    GAS    = ctypes.windll.user32.GetAsyncKeyState
    user32 = ctypes.windll.user32

    def screen_center():
        return user32.GetSystemMetrics(0)//2, user32.GetSystemMetrics(1)//2

    def move_mouse(dx: int, dy: int):
        class MI(ctypes.Structure):
            _fields_ = [("dx",wintypes.LONG),("dy",wintypes.LONG),
                        ("mouseData",wintypes.DWORD),("dwFlags",wintypes.DWORD),
                        ("time",wintypes.DWORD),("dwExtraInfo",ctypes.POINTER(ctypes.c_ulong))]
        class INP(ctypes.Structure):
            _fields_ = [("type",wintypes.DWORD),("mi",MI)]
        ex = ctypes.c_ulong(0)
        i  = INP(type=0, mi=MI(dx=dx,dy=dy,mouseData=0,dwFlags=0x0001,
                               time=0,dwExtraInfo=ctypes.pointer(ex)))
        user32.SendInput(1, ctypes.pointer(i), ctypes.sizeof(i))
else:
    def screen_center():
        return 540, 1170     # rough 1080p phone center; FILL for device res

    def move_mouse(dx, dy):
        pass   # Android: inject via /dev/input or Frida touch hook

# ══════════════════════════════════════════════════════════════════════════════
# COMBAT LOOP
# ══════════════════════════════════════════════════════════════════════════════
def aimbot_tick():
    if not cfg["aimbot_enabled"]:
        return
    if IS_WIN and not (GAS(cfg["aimbot_key"]) & 0x8000):
        return
    t = read_entity_head()
    if t is None:
        return
    tx, ty = t
    cx, cy = screen_center()
    dx, dy = tx - cx, ty - cy
    if math.hypot(dx, dy) > cfg["fov_radius"]:
        return
    s = max(1, cfg["aimbot_smoothness"]) / 10.0
    move_mouse(int(dx/s), int(dy/s))

def silent_aim_tick():
    if not cfg["silent_aim_enabled"]:
        return
    if IS_WIN and not (GAS(cfg["silent_key"]) & 0x8000):
        return
    t = read_entity_head()
    if t is None:
        return
    tx, ty = t
    cx, cy = screen_center()
    if math.hypot(tx-cx, ty-cy) > cfg["silent_fov"]:
        return
    silent_aim_patch(t)

def misc_tick():
    if cfg["noclip"]:      apply_noclip(True)
    if cfg["speed_boost"]: apply_speed(cfg["speed_value"])
    if cfg["jump_boost"]:  apply_jump(cfg["jump_value"])
    if cfg["fly_enabled"]: apply_fly(True, cfg["fly_speed"])

def combat_loop():
    while True:
        try:
            aimbot_tick()
            silent_aim_tick()
            misc_tick()
        except Exception:
            pass
        time.sleep(1 / max(1, cfg["fps_limit"]))

# ══════════════════════════════════════════════════════════════════════════════
# KEY LOOP (Windows only)
# ══════════════════════════════════════════════════════════════════════════════
menu_visible = True

def toggle_menu_win():
    global menu_visible
    menu_visible = not menu_visible
    import dearpygui.dearpygui as dpg
    if menu_visible:
        dpg.show_item("main_window")
        dpg.hide_item("mobile_btn_win")
    else:
        dpg.hide_item("main_window")
        dpg.show_item("mobile_btn_win")

def key_loop():
    while True:
        if GAS(cfg["panic_key"]) & 0x8000:
            os._exit(0)
        if GAS(cfg["menu_key"]) & 1:
            toggle_menu_win()
        time.sleep(0.05)

# ══════════════════════════════════════════════════════════════════════════════
# WINDOWS UI  (Dear PyGui)
# ══════════════════════════════════════════════════════════════════════════════
def run_windows_ui():
    import dearpygui.dearpygui as dpg

    logo_path = generate_logo()

    def apply_theme(scale=1.0):
        pad = max(4, int(8*scale))
        r   = max(3, int(8*scale))
        with dpg.theme() as t:
            with dpg.theme_component(dpg.mvAll):
                C = dpg.add_theme_color
                S = dpg.add_theme_style
                C(dpg.mvThemeCol_WindowBg,         (8,12,22,245))
                C(dpg.mvThemeCol_ChildBg,           (12,18,30,200))
                C(dpg.mvThemeCol_PopupBg,           (10,16,28,240))
                C(dpg.mvThemeCol_TitleBg,           (0,30,50,255))
                C(dpg.mvThemeCol_TitleBgActive,     (0,50,80,255))
                C(dpg.mvThemeCol_TitleBgCollapsed,  (0,20,35,200))
                C(dpg.mvThemeCol_Tab,               (0,40,60,200))
                C(dpg.mvThemeCol_TabActive,         (0,170,210,255))
                C(dpg.mvThemeCol_TabHovered,        (0,130,170,220))
                C(dpg.mvThemeCol_Button,            (0,80,120,200))
                C(dpg.mvThemeCol_ButtonHovered,     (0,150,200,230))
                C(dpg.mvThemeCol_ButtonActive,      (0,200,240,255))
                C(dpg.mvThemeCol_SliderGrab,        (0,200,230,255))
                C(dpg.mvThemeCol_SliderGrabActive,  (0,230,255,255))
                C(dpg.mvThemeCol_CheckMark,         (0,230,255,255))
                C(dpg.mvThemeCol_FrameBg,           (15,25,40,210))
                C(dpg.mvThemeCol_FrameBgHovered,    (25,40,60,230))
                C(dpg.mvThemeCol_FrameBgActive,     (30,55,80,255))
                C(dpg.mvThemeCol_Header,            (0,70,100,200))
                C(dpg.mvThemeCol_HeaderHovered,     (0,120,160,220))
                C(dpg.mvThemeCol_HeaderActive,      (0,170,210,255))
                C(dpg.mvThemeCol_Text,              (170,235,255,255))
                C(dpg.mvThemeCol_TextDisabled,      (80,130,150,180))
                C(dpg.mvThemeCol_Border,            (0,160,210,140))
                C(dpg.mvThemeCol_BorderShadow,      (0,0,0,0))
                C(dpg.mvThemeCol_ScrollbarBg,       (8,12,22,180))
                C(dpg.mvThemeCol_ScrollbarGrab,     (0,130,170,200))
                C(dpg.mvThemeCol_ScrollbarGrabHov,  (0,170,210,220))
                C(dpg.mvThemeCol_ScrollbarGrabAct,  (0,200,240,255))
                C(dpg.mvThemeCol_Separator,         (0,120,160,150))
                C(dpg.mvThemeCol_SeparatorHovered,  (0,170,210,200))
                C(dpg.mvThemeCol_SeparatorActive,   (0,200,240,255))
                S(dpg.mvStyleVar_WindowRounding,    r)
                S(dpg.mvStyleVar_FrameRounding,     max(1,r-2))
                S(dpg.mvStyleVar_TabRounding,       max(1,r-2))
                S(dpg.mvStyleVar_ScrollbarRounding, r)
                S(dpg.mvStyleVar_GrabRounding,      r)
                S(dpg.mvStyleVar_WindowPadding,     pad, pad)
                S(dpg.mvStyleVar_FramePadding,      pad-2, max(1,pad-4))
                S(dpg.mvStyleVar_ItemSpacing,       pad, pad-2)
                S(dpg.mvStyleVar_ItemInnerSpacing,  pad-2, pad-2)
        dpg.bind_theme(t)

    # drag state
    _drag_start_m = [0,0]
    _drag_start_p = [0,0]
    _dragging     = [False]

    def drag_start(s, a):
        _dragging[0]     = True
        _drag_start_p[:] = dpg.get_item_pos("mobile_btn_win")
        _drag_start_m[:] = list(dpg.get_mouse_pos(local=False))

    def drag_move(s, a):
        if not _dragging[0]:
            return
        cur = dpg.get_mouse_pos(local=False)
        nx  = max(0, _drag_start_p[0] + cur[0] - _drag_start_m[0])
        ny  = max(0, _drag_start_p[1] + cur[1] - _drag_start_m[1])
        dpg.set_item_pos("mobile_btn_win", [nx, ny])
        cfg["mobile_btn_x"] = nx
        cfg["mobile_btn_y"] = ny

    def drag_stop(s, a):
        _dragging[0] = False

    def scale_cb(s, a):
        cfg["ui_scale"] = round(a, 2)
        sc = cfg["ui_scale"]
        dpg.set_item_width("main_window",  int(800*sc))
        dpg.set_item_height("main_window", int(540*sc))
        apply_theme(sc)

    def sec(label):
        dpg.add_spacer(height=5)
        dpg.add_text(f"  {label}", color=(0,190,220,255))
        dpg.add_separator()
        dpg.add_spacer(height=3)

    dpg.create_context()
    apply_theme(cfg["ui_scale"])

    with dpg.handler_registry():
        dpg.add_mouse_drag_handler(callback=drag_move)
        dpg.add_mouse_release_handler(callback=drag_stop)

    # load logo texture
    logo_id = None
    if logo_path and os.path.exists(logo_path):
        try:
            w_img, h_img, _, data = dpg.load_image(logo_path)
            with dpg.texture_registry():
                logo_id = dpg.add_static_texture(w_img, h_img, data)
        except Exception:
            logo_id = None

    # mobile toggle button
    with dpg.window(tag="mobile_btn_win", no_title_bar=True, no_resize=True,
                    no_scrollbar=True, no_collapse=True, width=110, height=38,
                    pos=[cfg["mobile_btn_x"], cfg["mobile_btn_y"]], show=False):
        dpg.add_button(label="  AngelHub", width=106, height=30,
                       callback=lambda: toggle_menu_win())
        with dpg.item_handler_registry() as bhr:
            dpg.add_item_clicked_handler(button=0, callback=drag_start)
        dpg.bind_item_handler_registry(dpg.last_item(), bhr)

    sc = cfg["ui_scale"]
    W  = int(800*sc)
    H  = int(540*sc)

    with dpg.window(label="", tag="main_window", width=W, height=H,
                    no_close=True, pos=[80, 60], no_title_bar=True):

        # ── header ──────────────────────────────────────────────────────────
        with dpg.group(horizontal=True):
            if logo_id:
                dpg.add_image(logo_id, width=36, height=36)
                dpg.add_spacer(width=6)
            dpg.add_text("AngelHub", color=(0,210,240,255))
            dpg.add_text(" | v3.0", color=(0,140,170,200))
            dpg.add_spacer(width=16)
            dpg.add_text("Discord:", color=(120,190,210,180))
            dpg.add_spacer(width=4)
            dpg.add_input_text(tag="disc_field", default_value=DISCORD_LINK,
                               width=230, readonly=True)
            dpg.add_button(label="Copy",
                           callback=lambda: dpg.set_clipboard_text(DISCORD_LINK))
            dpg.add_spacer(width=12)
            dpg.add_button(label="  X  ", callback=lambda: toggle_menu_win())

        dpg.add_separator()
        dpg.add_spacer(height=3)

        with dpg.tab_bar():

            # COMBAT ─────────────────────────────────────────────────────────
            with dpg.tab(label=" Combat "):
                with dpg.child_window(height=-1, border=False):
                    sec("AIMBOT")
                    dpg.add_checkbox(label="Enabled",
                        default_value=cfg["aimbot_enabled"],
                        callback=lambda s,a: cfg.update({"aimbot_enabled":a}))
                    dpg.add_slider_int(label="Smoothness", min_value=1, max_value=100,
                        default_value=cfg["aimbot_smoothness"], format="%d%%",
                        callback=lambda s,a: cfg.update({"aimbot_smoothness":a}))
                    dpg.add_slider_int(label="FOV Radius", min_value=10, max_value=500,
                        default_value=cfg["fov_radius"], format="%d px",
                        callback=lambda s,a: cfg.update({"fov_radius":a}))
                    dpg.add_checkbox(label="Draw FOV",
                        default_value=cfg["draw_fov"],
                        callback=lambda s,a: cfg.update({"draw_fov":a}))
                    dpg.add_checkbox(label="Fill FOV",
                        default_value=cfg["fov_filled"],
                        callback=lambda s,a: cfg.update({"fov_filled":a}))
                    dpg.add_color_edit(label="FOV Color",
                        default_value=cfg["fov_color"], alpha_preview=True,
                        callback=lambda s,a: cfg.update({"fov_color":list(a)}))
                    dpg.add_combo(label="Target Bone", items=BONES,
                        default_value=cfg["target_bone"],
                        callback=lambda s,a: cfg.update({"target_bone":a}))
                    dpg.add_checkbox(label="Team Check",
                        default_value=cfg["team_check"],
                        callback=lambda s,a: cfg.update({"team_check":a}))
                    dpg.add_text(f"Hold [V] to aim  |  key 0x{cfg['aimbot_key']:02X}",
                                 color=(100,170,190,180))

                    sec("SILENT AIM")
                    dpg.add_checkbox(label="Silent Aim",
                        default_value=cfg["silent_aim_enabled"],
                        callback=lambda s,a: cfg.update({"silent_aim_enabled":a}))
                    dpg.add_slider_int(label="Silent FOV", min_value=10, max_value=500,
                        default_value=cfg["silent_fov"], format="%d px",
                        callback=lambda s,a: cfg.update({"silent_fov":a}))
                    dpg.add_slider_int(label="Silent Smoothness", min_value=1, max_value=100,
                        default_value=cfg["silent_smoothness"], format="%d%%",
                        callback=lambda s,a: cfg.update({"silent_smoothness":a}))
                    dpg.add_combo(label="Silent Bone", items=BONES,
                        default_value=cfg["silent_bone"],
                        callback=lambda s,a: cfg.update({"silent_bone":a}))
                    dpg.add_text(f"Hold [X] to silent aim  |  key 0x{cfg['silent_key']:02X}",
                                 color=(100,170,190,180))

            # VISUALS ────────────────────────────────────────────────────────
            with dpg.tab(label=" Visuals "):
                with dpg.child_window(height=-1, border=False):
                    sec("ESP")
                    dpg.add_checkbox(label="ESP Master",
                        default_value=cfg["esp_enabled"],
                        callback=lambda s,a: cfg.update({"esp_enabled":a}))
                    dpg.add_checkbox(label="Box ESP",
                        default_value=cfg["box_esp"],
                        callback=lambda s,a: cfg.update({"box_esp":a}))
                    dpg.add_checkbox(label="Name ESP",
                        default_value=cfg["name_esp"],
                        callback=lambda s,a: cfg.update({"name_esp":a}))
                    dpg.add_checkbox(label="Health Bar",
                        default_value=cfg["health_bar"],
                        callback=lambda s,a: cfg.update({"health_bar":a}))
                    dpg.add_checkbox(label="Skeleton ESP",
                        default_value=cfg["skeleton_esp"],
                        callback=lambda s,a: cfg.update({"skeleton_esp":a}))
                    dpg.add_checkbox(label="Distance ESP",
                        default_value=cfg["distance_esp"],
                        callback=lambda s,a: cfg.update({"distance_esp":a}))
                    dpg.add_checkbox(label="Tracer Lines",
                        default_value=cfg["tracer_esp"],
                        callback=lambda s,a: cfg.update({"tracer_esp":a}))
                    dpg.add_checkbox(label="Chams",
                        default_value=cfg["chams_enabled"],
                        callback=lambda s,a: cfg.update({"chams_enabled":a}))
                    dpg.add_spacer(height=4)
                    dpg.add_color_edit(label="ESP Color",
                        default_value=cfg["esp_color"], alpha_preview=True,
                        callback=lambda s,a: cfg.update({"esp_color":list(a)}))
                    dpg.add_color_edit(label="Enemy Color",
                        default_value=cfg["enemy_color"], alpha_preview=True,
                        callback=lambda s,a: cfg.update({"enemy_color":list(a)}))
                    dpg.add_color_edit(label="Team Color",
                        default_value=cfg["team_color"], alpha_preview=True,
                        callback=lambda s,a: cfg.update({"team_color":list(a)}))

            # MISC ───────────────────────────────────────────────────────────
            with dpg.tab(label=" Misc "):
                with dpg.child_window(height=-1, border=False):
                    sec("MOVEMENT")
                    dpg.add_checkbox(label="Noclip",
                        default_value=cfg["noclip"],
                        callback=lambda s,a: cfg.update({"noclip":a}))
                    dpg.add_checkbox(label="Speed Boost",
                        default_value=cfg["speed_boost"],
                        callback=lambda s,a: cfg.update({"speed_boost":a}))
                    dpg.add_slider_int(label="Walk Speed", min_value=1, max_value=500,
                        default_value=cfg["speed_value"], format="%d studs/s",
                        callback=lambda s,a: cfg.update({"speed_value":a}))
                    dpg.add_checkbox(label="Jump Boost",
                        default_value=cfg["jump_boost"],
                        callback=lambda s,a: cfg.update({"jump_boost":a}))
                    dpg.add_slider_int(label="Jump Power", min_value=1, max_value=500,
                        default_value=cfg["jump_value"], format="%d",
                        callback=lambda s,a: cfg.update({"jump_value":a}))
                    dpg.add_checkbox(label="Infinite Jump",
                        default_value=cfg["infinite_jump"],
                        callback=lambda s,a: cfg.update({"infinite_jump":a}))
                    dpg.add_checkbox(label="Fly",
                        default_value=cfg["fly_enabled"],
                        callback=lambda s,a: cfg.update({"fly_enabled":a}))
                    dpg.add_slider_int(label="Fly Speed", min_value=1, max_value=500,
                        default_value=cfg["fly_speed"], format="%d",
                        callback=lambda s,a: cfg.update({"fly_speed":a}))

                    sec("PLAYER")
                    dpg.add_checkbox(label="Anti Ragdoll",
                        default_value=cfg["anti_ragdoll"],
                        callback=lambda s,a: cfg.update({"anti_ragdoll":a}))
                    dpg.add_checkbox(label="Auto Rejoin",
                        default_value=cfg["auto_rejoin"],
                        callback=lambda s,a: cfg.update({"auto_rejoin":a}))
                    dpg.add_checkbox(label="Spin Bot",
                        default_value=cfg["spin_bot"],
                        callback=lambda s,a: cfg.update({"spin_bot":a}))
                    dpg.add_slider_int(label="Spin Speed", min_value=1, max_value=100,
                        default_value=cfg["spin_speed"], format="%d",
                        callback=lambda s,a: cfg.update({"spin_speed":a}))

            # WORLD ──────────────────────────────────────────────────────────
            with dpg.tab(label=" World "):
                with dpg.child_window(height=-1, border=False):
                    sec("WORLD")
                    dpg.add_checkbox(label="No Flash",
                        default_value=cfg["no_flash"],
                        callback=lambda s,a: cfg.update({"no_flash":a}))
                    dpg.add_checkbox(label="Fullbright",
                        default_value=cfg["fullbright"],
                        callback=lambda s,a: (cfg.update({"fullbright":a}),
                                              apply_fullbright(a)))
                    dpg.add_checkbox(label="Remove Fog",
                        default_value=cfg["remove_fog"],
                        callback=lambda s,a: (cfg.update({"remove_fog":a}),
                                              apply_fog(a)))
                    dpg.add_checkbox(label="Radar",
                        default_value=cfg["radar"],
                        callback=lambda s,a: cfg.update({"radar":a}))
                    dpg.add_combo(label="Time of Day", items=TOD_OPTS,
                        default_value=cfg["time_of_day"],
                        callback=lambda s,a: cfg.update({"time_of_day":a}))

            # SETTINGS ───────────────────────────────────────────────────────
            with dpg.tab(label=" Settings "):
                with dpg.child_window(height=-1, border=False):
                    sec("KEYS")
                    dpg.add_text(f"Menu:   INSERT  0x{cfg['menu_key']:02X}",
                                 color=(150,210,230,220))
                    dpg.add_text(f"Panic:  END     0x{cfg['panic_key']:02X}",
                                 color=(220,80,80,220))

                    sec("PROCESS")
                    dpg.add_input_text(label="Target Process",
                        default_value=cfg["target_process"], width=240,
                        callback=lambda s,a: cfg.update({"target_process":a}))
                    dpg.add_button(label="Reattach",
                        callback=lambda: try_attach())

                    sec("PERFORMANCE")
                    dpg.add_slider_int(label="FPS Limit", min_value=30, max_value=360,
                        default_value=cfg["fps_limit"], format="%d fps",
                        callback=lambda s,a: cfg.update({"fps_limit":a}))

                    sec("UI SCALE")
                    dpg.add_slider_float(label="Scale", min_value=0.6, max_value=2.5,
                        default_value=cfg["ui_scale"], format="%.2fx",
                        callback=scale_cb)

                    sec("MOBILE BUTTON")
                    dpg.add_slider_int(label="Btn X", min_value=0, max_value=3840,
                        default_value=cfg["mobile_btn_x"],
                        callback=lambda s,a: (cfg.update({"mobile_btn_x":a}),
                            dpg.set_item_pos("mobile_btn_win",[a,cfg["mobile_btn_y"]])))
                    dpg.add_slider_int(label="Btn Y", min_value=0, max_value=2160,
                        default_value=cfg["mobile_btn_y"],
                        callback=lambda s,a: (cfg.update({"mobile_btn_y":a}),
                            dpg.set_item_pos("mobile_btn_win",[cfg["mobile_btn_x"],a])))

                    sec("CONFIG")
                    with dpg.group(horizontal=True):
                        dpg.add_button(label="Save", width=110, callback=save_cfg)
                        dpg.add_button(label="Load", width=110, callback=load_cfg)
                        dpg.add_button(label="Reset", width=90,
                            callback=lambda: (os.remove(CFG_PATH)
                                              if os.path.exists(CFG_PATH) else None))

    dpg.create_viewport(title="AngelHub v3.0", width=W+24, height=H+24,
                        always_on_top=True, decorated=True)
    dpg.setup_dearpygui()
    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()

# ══════════════════════════════════════════════════════════════════════════════
# ANDROID UI  (Kivy)
# ══════════════════════════════════════════════════════════════════════════════
def run_android_ui():
    os.environ.setdefault("KIVY_NO_ENV_CONFIG", "1")

    from kivy.app import App
    from kivy.uix.boxlayout import BoxLayout
    from kivy.uix.floatlayout import FloatLayout
    from kivy.uix.scrollview import ScrollView
    from kivy.uix.tabbedpanel import TabbedPanel, TabbedPanelItem
    from kivy.uix.label import Label
    from kivy.uix.button import Button
    from kivy.uix.togglebutton import ToggleButton
    from kivy.uix.slider import Slider
    from kivy.uix.textinput import TextInput
    from kivy.uix.widget import Widget
    from kivy.graphics import Color, Rectangle, RoundedRectangle, Line
    from kivy.core.clipboard import Clipboard
    from kivy.metrics import dp
    from kivy.clock import Clock

    TEAL   = (0, 0.78, 0.9, 1)
    DARK   = (0.03, 0.05, 0.09, 0.97)
    DARKM  = (0.05, 0.07, 0.12, 0.85)
    BORDER = (0, 0.63, 0.82, 0.55)
    TEXT   = (0.67, 0.92, 1, 1)
    DIM    = (0.31, 0.51, 0.59, 0.7)
    RED    = (0.85, 0.22, 0.22, 1)

    def styled_btn(text, callback=None, bg=None, fg=TEXT, h=dp(44)):
        bg = bg or (0, 0.31, 0.47, 0.85)
        b  = Button(text=text, size_hint_y=None, height=h,
                    background_normal="", background_color=bg,
                    color=fg, font_size=dp(13), bold=True)
        if callback:
            b.bind(on_press=lambda *a: callback())
        return b

    def toggle_row(label_text, key):
        row = BoxLayout(size_hint_y=None, height=dp(44), spacing=dp(8))
        lbl = Label(text=label_text, color=TEXT, font_size=dp(13),
                    size_hint_x=0.75, halign="left", valign="middle")
        lbl.bind(size=lbl.setter("text_size"))

        state = "down" if cfg[key] else "normal"
        tb = ToggleButton(text="ON" if cfg[key] else "OFF",
                          state=state, size_hint_x=0.25,
                          background_normal="",
                          background_color=TEAL if cfg[key] else (0.2,0.2,0.3,1),
                          color=(0,0,0,1) if cfg[key] else TEXT,
                          font_size=dp(12), bold=True)

        def on_toggle(btn, *a):
            on = btn.state == "down"
            cfg[key] = on
            btn.text             = "ON" if on else "OFF"
            btn.background_color = TEAL if on else (0.2,0.2,0.3,1)
            btn.color            = (0,0,0,1) if on else TEXT
        tb.bind(on_press=on_toggle)
        row.add_widget(lbl)
        row.add_widget(tb)
        return row

    def slider_row(label_text, key, mn, mx, fmt="{:.0f}"):
        col = BoxLayout(orientation="vertical", size_hint_y=None, height=dp(66))
        hdr = BoxLayout(size_hint_y=None, height=dp(22))
        lbl = Label(text=label_text, color=DIM, font_size=dp(11),
                    size_hint_x=0.7, halign="left", valign="middle")
        lbl.bind(size=lbl.setter("text_size"))
        val_lbl = Label(text=fmt.format(cfg[key]), color=TEAL,
                        font_size=dp(11), size_hint_x=0.3,
                        halign="right", valign="middle")
        val_lbl.bind(size=val_lbl.setter("text_size"))
        sl = Slider(min=mn, max=mx, value=cfg[key],
                    size_hint_y=None, height=dp(36),
                    cursor_size=(dp(20), dp(20)))

        def on_val(sl, v, *a):
            v = int(v) if fmt == "{:.0f}" else round(v, 2)
            cfg[key]       = v
            val_lbl.text   = fmt.format(v)
        sl.bind(value=on_val)

        hdr.add_widget(lbl)
        hdr.add_widget(val_lbl)
        col.add_widget(hdr)
        col.add_widget(sl)
        return col

    def section_header(text):
        lbl = Label(text=f"  {text}", color=TEAL, font_size=dp(12),
                    bold=True, size_hint_y=None, height=dp(30),
                    halign="left", valign="middle")
        lbl.bind(size=lbl.setter("text_size"))
        sep = Widget(size_hint_y=None, height=dp(1))
        with sep.canvas:
            Color(*BORDER)
            Rectangle(pos=sep.pos, size=sep.size)
        sep.bind(pos=lambda w,p: setattr(w.canvas.children[-1], "pos", p),
                 size=lambda w,s: setattr(w.canvas.children[-1], "size", s))
        col = BoxLayout(orientation="vertical", size_hint_y=None,
                        height=dp(34), spacing=0)
        col.add_widget(lbl)
        col.add_widget(sep)
        return col

    def scrollable_tab(widgets):
        sv  = ScrollView(do_scroll_x=False)
        col = BoxLayout(orientation="vertical", size_hint_y=None,
                        padding=[dp(8), dp(6)], spacing=dp(4))
        col.bind(minimum_height=col.setter("height"))
        for w in widgets:
            col.add_widget(w)
        sv.add_widget(col)
        return sv

    # ── build tab contents ────────────────────────────────────────────────────
    def combat_tab():
        items = [
            section_header("AIMBOT"),
            toggle_row("Aimbot Enabled", "aimbot_enabled"),
            slider_row("Smoothness", "aimbot_smoothness", 1, 100),
            slider_row("FOV Radius (px)", "fov_radius", 10, 500),
            toggle_row("Draw FOV", "draw_fov"),
            toggle_row("Fill FOV", "fov_filled"),
            toggle_row("Team Check", "team_check"),
            section_header("SILENT AIM"),
            toggle_row("Silent Aim", "silent_aim_enabled"),
            slider_row("Silent FOV (px)", "silent_fov", 10, 500),
            slider_row("Silent Smoothness", "silent_smoothness", 1, 100),
        ]
        return scrollable_tab(items)

    def visuals_tab():
        items = [
            section_header("ESP"),
            toggle_row("ESP Master", "esp_enabled"),
            toggle_row("Box ESP", "box_esp"),
            toggle_row("Name ESP", "name_esp"),
            toggle_row("Health Bar", "health_bar"),
            toggle_row("Skeleton ESP", "skeleton_esp"),
            toggle_row("Distance ESP", "distance_esp"),
            toggle_row("Tracer Lines", "tracer_esp"),
            toggle_row("Chams", "chams_enabled"),
        ]
        return scrollable_tab(items)

    def misc_tab():
        items = [
            section_header("MOVEMENT"),
            toggle_row("Noclip", "noclip"),
            toggle_row("Speed Boost", "speed_boost"),
            slider_row("Walk Speed (studs/s)", "speed_value", 1, 500),
            toggle_row("Jump Boost", "jump_boost"),
            slider_row("Jump Power", "jump_value", 1, 500),
            toggle_row("Infinite Jump", "infinite_jump"),
            toggle_row("Fly", "fly_enabled"),
            slider_row("Fly Speed", "fly_speed", 1, 500),
            section_header("PLAYER"),
            toggle_row("Anti Ragdoll", "anti_ragdoll"),
            toggle_row("Auto Rejoin", "auto_rejoin"),
            toggle_row("Spin Bot", "spin_bot"),
            slider_row("Spin Speed", "spin_speed", 1, 100),
        ]
        return scrollable_tab(items)

    def world_tab():
        items = [
            section_header("WORLD"),
            toggle_row("No Flash", "no_flash"),
            toggle_row("Fullbright", "fullbright"),
            toggle_row("Remove Fog", "remove_fog"),
            toggle_row("Radar", "radar"),
        ]
        return scrollable_tab(items)

    def settings_tab(app_ref):
        items = [
            section_header("CONFIG"),
            styled_btn("Save Config", callback=save_cfg),
            styled_btn("Load Config", callback=load_cfg),
            section_header("CLOSE"),
            styled_btn("Close Menu", callback=app_ref.hide_menu,
                       bg=(0.3,0.1,0.1,0.9), fg=TEXT),
        ]
        return scrollable_tab(items)

    # ── Kivy App ──────────────────────────────────────────────────────────────
    class AngelHubApp(App):
        def __init__(self):
            super().__init__()
            self._menu_visible = True
            self._root = None
            self._panel = None
            self._toggle_btn = None

        def build(self):
            root = FloatLayout()
            self._root = root

            # floating toggle button (draggable)
            tb = Button(text="AngelHub",
                        size_hint=(None, None), size=(dp(110), dp(40)),
                        pos=(cfg["mobile_btn_x"], cfg["mobile_btn_y"]),
                        background_normal="", background_color=(*TEAL[:3], 0.9),
                        color=(0,0,0,1), font_size=dp(13), bold=True)
            self._toggle_btn = tb
            tb.bind(on_press=self.toggle_menu)
            # drag
            self._tdrag = False
            self._tdrag_offset = (0,0)
            tb.bind(on_touch_down=self._tb_down,
                    on_touch_move=self._tb_move,
                    on_touch_up=self._tb_up)

            # main panel
            panel = BoxLayout(orientation="vertical",
                              size_hint=(None, None),
                              size=(dp(360), dp(560)),
                              pos=(dp(20), dp(60)))
            self._panel = panel

            # dark background
            with panel.canvas.before:
                Color(*DARK)
                self._panel_bg = RoundedRectangle(
                    pos=panel.pos, size=panel.size, radius=[dp(12)])
                Color(*BORDER)
                self._panel_border = Line(
                    rounded_rectangle=[*panel.pos, *panel.size, dp(12)],
                    width=1.2)
            panel.bind(pos=self._update_panel_bg, size=self._update_panel_bg)

            # header
            hdr = BoxLayout(size_hint_y=None, height=dp(48),
                            padding=[dp(8),dp(4)], spacing=dp(6))
            with hdr.canvas.before:
                Color(0, 0.19, 0.31, 1)
                self._hdr_bg = RoundedRectangle(
                    pos=hdr.pos, size=hdr.size,
                    radius=[dp(12), dp(12), 0, 0])
            hdr.bind(pos=lambda w,p: setattr(self._hdr_bg,"pos",p),
                     size=lambda w,s: setattr(self._hdr_bg,"size",s))

            title_lbl = Label(text="AngelHub  v3.0",
                              color=TEAL, font_size=dp(15), bold=True,
                              size_hint_x=0.55, halign="left", valign="middle")
            title_lbl.bind(size=title_lbl.setter("text_size"))

            disc_inp = TextInput(text=DISCORD_LINK, readonly=True,
                                 size_hint_x=0.35, size_hint_y=None,
                                 height=dp(32), multiline=False,
                                 background_color=(0.05,0.09,0.15,1),
                                 foreground_color=TEAL,
                                 font_size=dp(10))
            copy_btn = styled_btn("Copy", h=dp(32), bg=(0,0.31,0.47,0.9),
                callback=lambda: Clipboard.copy(DISCORD_LINK))
            copy_btn.size_hint_x = None
            copy_btn.width       = dp(52)

            close_btn = styled_btn("X", h=dp(32), bg=(0.6,0.1,0.1,0.9))
            close_btn.size_hint_x = None
            close_btn.width       = dp(36)
            close_btn.bind(on_press=lambda *a: self.hide_menu())

            hdr.add_widget(title_lbl)
            hdr.add_widget(disc_inp)
            hdr.add_widget(copy_btn)
            hdr.add_widget(close_btn)

            # tabs
            tp = TabbedPanel(do_default_tab=False,
                             tab_width=dp(68), tab_height=dp(36))
            self._tp = tp

            tabs = [
                ("Combat",   combat_tab()),
                ("Visuals",  visuals_tab()),
                ("Misc",     misc_tab()),
                ("World",    world_tab()),
                ("Settings", settings_tab(self)),
            ]
            for name, content in tabs:
                ti = TabbedPanelItem(text=name, font_size=dp(12))
                ti.add_widget(content)
                tp.add_widget(ti)

            panel.add_widget(hdr)
            panel.add_widget(tp)

            root.add_widget(panel)
            root.add_widget(tb)
            return root

        def _update_panel_bg(self, w, *a):
            self._panel_bg.pos    = w.pos
            self._panel_bg.size   = w.size
            self._panel_border.rounded_rectangle = [*w.pos, *w.size, dp(12)]

        def _tb_down(self, btn, touch):
            if btn.collide_point(*touch.pos):
                self._tdrag = True
                self._tdrag_offset = (btn.x - touch.x, btn.y - touch.y)

        def _tb_move(self, btn, touch):
            if self._tdrag:
                btn.pos = (touch.x + self._tdrag_offset[0],
                           touch.y + self._tdrag_offset[1])
                cfg["mobile_btn_x"] = btn.x
                cfg["mobile_btn_y"] = btn.y

        def _tb_up(self, btn, touch):
            self._tdrag = False

        def toggle_menu(self, *a):
            if self._menu_visible:
                self.hide_menu()
            else:
                self.show_menu()

        def hide_menu(self):
            self._menu_visible   = False
            self._panel.opacity  = 0
            self._panel.disabled = True

        def show_menu(self):
            self._menu_visible   = True
            self._panel.opacity  = 1
            self._panel.disabled = False

    AngelHubApp().run()

# ══════════════════════════════════════════════════════════════════════════════
# ENTRY
# ══════════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    load_cfg()
    generate_logo()
    try_attach()
    threading.Thread(target=combat_loop, daemon=True).start()
    if IS_WIN:
        threading.Thread(target=key_loop, daemon=True).start()
        run_windows_ui()
    else:
        run_android_ui()
