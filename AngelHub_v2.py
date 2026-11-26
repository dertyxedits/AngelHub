# AngelHub v2.0 | Python 3.11+ | dearpygui==1.11.1
# pip install dearpygui pymem
# Run as Administrator — SendInput + pymem need elevated perms
# FILL: TARGET_PROCESS, read_entity_head() with your game's entity+W2S

import dearpygui.dearpygui as dpg
import pymem, pymem.process
import math, threading, time, json, os, ctypes, sys
from ctypes import wintypes

# ── config ────────────────────────────────────────────────────────────────────
CFG_PATH = "angelhub_cfg.json"

cfg = {
    # Combat / Aimbot
    "aimbot_enabled":     True,
    "aimbot_smoothness":  45,
    "fov_radius":         120,
    "fov_filled":         False,
    "fov_color":          [0, 200, 230, 80],
    "target_bone":        "Head",
    "team_check":         True,
    "draw_fov":           False,
    "aimbot_key":         0x56,

    # Combat / Silent Aim
    "silent_aim_enabled": False,
    "silent_fov":         90,
    "silent_smoothness":  30,
    "silent_bone":        "Head",
    "silent_key":         0x58,       # X

    # Visuals
    "esp_enabled":        False,
    "box_esp":            True,
    "name_esp":           True,
    "health_bar":         True,
    "skeleton_esp":       False,
    "esp_color":          [0, 220, 255, 255],

    # World
    "no_flash":           False,
    "radar":              False,
    "fullbright":         False,

    # Settings
    "menu_key":           0x2D,
    "panic_key":          0x23,
    "fps_limit":          240,
    "ui_scale":           1.0,
    "mobile_btn_x":       40,
    "mobile_btn_y":       40,

    # Misc
    "bhop":               False,
    "auto_strafe":        False,
    "long_jump":          False,
    "clantag_spoof":      False,
    "clantag_text":       "AngelHub",
}

BONES = ["Head", "Neck", "Chest", "Pelvis",
         "Left Shoulder", "Right Shoulder", "Left Knee", "Right Knee"]

DISCORD_LINK = "discord.gg/ojailbreaks"

# ── save / load ───────────────────────────────────────────────────────────────
def save_cfg():
    with open(CFG_PATH, "w") as f:
        json.dump(cfg, f, indent=2)

def load_cfg():
    if os.path.exists(CFG_PATH):
        with open(CFG_PATH) as f:
            cfg.update(json.load(f))

# ── pymem attach ──────────────────────────────────────────────────────────────
pm = None
TARGET_PROCESS = "FILL_PROCESS_NAME.exe"   # FILL

def try_attach():
    global pm
    try:
        pm = pymem.Pymem(TARGET_PROCESS)
    except Exception:
        pm = None

# ── stubs — wire these to your game ──────────────────────────────────────────
def read_entity_head() -> tuple[int, int] | None:
    """Return (screen_x, screen_y) of nearest visible enemy head, or None."""
    return None

def silent_aim_patch(target: tuple[int, int] | None):
    """
    For silent aim: write corrected angle directly to view-angle memory.
    target — (screen_x, screen_y) or None.
    FILL: calc angle delta from screen_center -> target, write to view angles.
    """
    pass

# ── mouse move via SendInput ──────────────────────────────────────────────────
def screen_center() -> tuple[int, int]:
    u = ctypes.windll.user32
    return u.GetSystemMetrics(0) // 2, u.GetSystemMetrics(1) // 2

def move_mouse(dx: int, dy: int):
    class MI(ctypes.Structure):
        _fields_ = [("dx", wintypes.LONG), ("dy", wintypes.LONG),
                    ("mouseData", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
                    ("time", wintypes.DWORD),
                    ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong))]
    class INP(ctypes.Structure):
        _fields_ = [("type", wintypes.DWORD), ("mi", MI)]
    extra = ctypes.c_ulong(0)
    i = INP(type=0, mi=MI(dx=dx, dy=dy, mouseData=0,
                          dwFlags=0x0001, time=0,
                          dwExtraInfo=ctypes.pointer(extra)))
    ctypes.windll.user32.SendInput(1, ctypes.pointer(i), ctypes.sizeof(i))

# ── combat loop ───────────────────────────────────────────────────────────────
GAS = ctypes.windll.user32.GetAsyncKeyState

def aimbot_tick():
    if not cfg["aimbot_enabled"]:
        return
    if not (GAS(cfg["aimbot_key"]) & 0x8000):
        return
    target = read_entity_head()
    if target is None:
        return
    tx, ty = target
    cx, cy = screen_center()
    dx, dy = tx - cx, ty - cy
    if math.hypot(dx, dy) > cfg["fov_radius"]:
        return
    smooth = max(1, cfg["aimbot_smoothness"]) / 10.0
    move_mouse(int(dx / smooth), int(dy / smooth))

def silent_aim_tick():
    if not cfg["silent_aim_enabled"]:
        return
    if not (GAS(cfg["silent_key"]) & 0x8000):
        return
    target = read_entity_head()
    if target is None:
        return
    tx, ty = target
    cx, cy = screen_center()
    if math.hypot(tx - cx, ty - cy) > cfg["silent_fov"]:
        return
    silent_aim_patch(target)

def combat_loop():
    while True:
        try:
            aimbot_tick()
            silent_aim_tick()
        except Exception:
            pass
        time.sleep(1 / max(1, cfg["fps_limit"]))

# ── key / panic loop ──────────────────────────────────────────────────────────
menu_visible = True

def key_loop():
    global menu_visible
    while True:
        if GAS(cfg["panic_key"]) & 0x8000:
            os._exit(0)
        if GAS(cfg["menu_key"]) & 1:
            toggle_menu()
        time.sleep(0.05)

def toggle_menu():
    global menu_visible
    menu_visible = not menu_visible
    if menu_visible:
        dpg.show_item("main_window")
        dpg.hide_item("mobile_toggle_window")
    else:
        dpg.hide_item("main_window")
        dpg.show_item("mobile_toggle_window")

# ── theme ─────────────────────────────────────────────────────────────────────
def apply_theme(scale: float = 1.0):
    pad = max(4, int(8 * scale))
    rounding = max(3, int(8 * scale))

    with dpg.theme() as t:
        with dpg.theme_component(dpg.mvAll):
            dpg.add_theme_color(dpg.mvThemeCol_WindowBg,          (8, 12, 22, 245))
            dpg.add_theme_color(dpg.mvThemeCol_ChildBg,           (12, 18, 30, 200))
            dpg.add_theme_color(dpg.mvThemeCol_PopupBg,           (10, 16, 28, 240))
            dpg.add_theme_color(dpg.mvThemeCol_TitleBg,           (0, 30, 50, 255))
            dpg.add_theme_color(dpg.mvThemeCol_TitleBgActive,     (0, 50, 80, 255))
            dpg.add_theme_color(dpg.mvThemeCol_TitleBgCollapsed,  (0, 20, 35, 200))
            dpg.add_theme_color(dpg.mvThemeCol_Tab,               (0, 40, 60, 200))
            dpg.add_theme_color(dpg.mvThemeCol_TabActive,         (0, 170, 210, 255))
            dpg.add_theme_color(dpg.mvThemeCol_TabHovered,        (0, 130, 170, 220))
            dpg.add_theme_color(dpg.mvThemeCol_Button,            (0, 80, 120, 200))
            dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered,     (0, 150, 200, 230))
            dpg.add_theme_color(dpg.mvThemeCol_ButtonActive,      (0, 200, 240, 255))
            dpg.add_theme_color(dpg.mvThemeCol_SliderGrab,        (0, 200, 230, 255))
            dpg.add_theme_color(dpg.mvThemeCol_SliderGrabActive,  (0, 230, 255, 255))
            dpg.add_theme_color(dpg.mvThemeCol_CheckMark,         (0, 230, 255, 255))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBg,           (15, 25, 40, 210))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered,    (25, 40, 60, 230))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive,     (30, 55, 80, 255))
            dpg.add_theme_color(dpg.mvThemeCol_Header,            (0, 70, 100, 200))
            dpg.add_theme_color(dpg.mvThemeCol_HeaderHovered,     (0, 120, 160, 220))
            dpg.add_theme_color(dpg.mvThemeCol_HeaderActive,      (0, 170, 210, 255))
            dpg.add_theme_color(dpg.mvThemeCol_Text,              (170, 235, 255, 255))
            dpg.add_theme_color(dpg.mvThemeCol_TextDisabled,      (80, 130, 150, 180))
            dpg.add_theme_color(dpg.mvThemeCol_Border,            (0, 160, 210, 140))
            dpg.add_theme_color(dpg.mvThemeCol_BorderShadow,      (0, 0, 0, 0))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarBg,       (8, 12, 22, 180))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrab,     (0, 130, 170, 200))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrabHov,  (0, 170, 210, 220))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrabAct,  (0, 200, 240, 255))
            dpg.add_theme_color(dpg.mvThemeCol_Separator,         (0, 120, 160, 150))
            dpg.add_theme_color(dpg.mvThemeCol_SeparatorHovered,  (0, 170, 210, 200))
            dpg.add_theme_color(dpg.mvThemeCol_SeparatorActive,   (0, 200, 240, 255))
            dpg.add_theme_style(dpg.mvStyleVar_WindowRounding,    rounding)
            dpg.add_theme_style(dpg.mvStyleVar_FrameRounding,     rounding - 2)
            dpg.add_theme_style(dpg.mvStyleVar_TabRounding,       rounding - 2)
            dpg.add_theme_style(dpg.mvStyleVar_ScrollbarRounding, rounding)
            dpg.add_theme_style(dpg.mvStyleVar_GrabRounding,      rounding)
            dpg.add_theme_style(dpg.mvStyleVar_WindowPadding,     pad, pad)
            dpg.add_theme_style(dpg.mvStyleVar_FramePadding,      pad - 2, pad - 4)
            dpg.add_theme_style(dpg.mvStyleVar_ItemSpacing,       pad, pad - 2)
            dpg.add_theme_style(dpg.mvStyleVar_ItemInnerSpacing,  pad - 2, pad - 2)
    dpg.bind_theme(t)

# ── section header helper ─────────────────────────────────────────────────────
def section(label: str):
    dpg.add_spacer(height=6)
    dpg.add_text(f"-- {label} --", color=(0, 190, 220, 255))
    dpg.add_separator()
    dpg.add_spacer(height=4)

# ── scale rebuild ─────────────────────────────────────────────────────────────
def rebuild_ui_scale(sender, app_data):
    cfg["ui_scale"] = round(app_data, 2)
    scale = cfg["ui_scale"]
    w = int(760 * scale)
    h = int(500 * scale)
    dpg.set_item_width("main_window", w)
    dpg.set_item_height("main_window", h)
    apply_theme(scale)

# ── mobile drag state ─────────────────────────────────────────────────────────
drag_start_mouse = (0, 0)
drag_start_pos   = (0, 0)
is_dragging      = False

def mobile_btn_drag_start(sender, app_data):
    global drag_start_mouse, drag_start_pos, is_dragging
    is_dragging = True
    pos = dpg.get_item_pos("mobile_toggle_window")
    drag_start_pos   = tuple(pos)
    drag_start_mouse = tuple(dpg.get_mouse_pos(local=False))

def mobile_btn_drag(sender, app_data):
    if not is_dragging:
        return
    cur = dpg.get_mouse_pos(local=False)
    dx = cur[0] - drag_start_mouse[0]
    dy = cur[1] - drag_start_mouse[1]
    new_x = max(0, drag_start_pos[0] + dx)
    new_y = max(0, drag_start_pos[1] + dy)
    dpg.set_item_pos("mobile_toggle_window", [new_x, new_y])
    cfg["mobile_btn_x"] = new_x
    cfg["mobile_btn_y"] = new_y

def mobile_btn_drag_stop(sender, app_data):
    global is_dragging
    is_dragging = False

# ── UI build ──────────────────────────────────────────────────────────────────
def build_ui():
    dpg.create_context()
    apply_theme(cfg["ui_scale"])

    with dpg.handler_registry():
        dpg.add_mouse_drag_handler(callback=mobile_btn_drag)
        dpg.add_mouse_release_handler(callback=mobile_btn_drag_stop)

    # mobile toggle button
    with dpg.window(tag="mobile_toggle_window",
                    no_title_bar=True, no_resize=True, no_scrollbar=True,
                    no_collapse=True, no_background=False,
                    width=90, height=36,
                    pos=[cfg["mobile_btn_x"], cfg["mobile_btn_y"]],
                    show=False):
        dpg.add_button(label="= AngelHub", width=86, height=28,
                       callback=lambda: toggle_menu())
        with dpg.item_handler_registry() as btn_hr:
            dpg.add_item_clicked_handler(button=0,
                                         callback=mobile_btn_drag_start)
        dpg.bind_item_handler_registry(dpg.last_item(), btn_hr)

    w = int(760 * cfg["ui_scale"])
    h = int(500 * cfg["ui_scale"])

    with dpg.window(label="AngelHub  |  v2.0", tag="main_window",
                    width=w, height=h, no_close=True, pos=[100, 80]):

        # top bar
        with dpg.group(horizontal=True):
            dpg.add_text("AngelHub v2.0", color=(0, 210, 240, 255))
            dpg.add_spacer(width=20)
            dpg.add_text("|", color=(0, 100, 130, 200))
            dpg.add_spacer(width=8)
            dpg.add_text("Discord:", color=(140, 200, 220, 200))
            dpg.add_spacer(width=4)
            dpg.add_input_text(tag="discord_field",
                               default_value=DISCORD_LINK,
                               width=200, readonly=True)
            dpg.add_button(label="Copy",
                           callback=lambda: dpg.set_clipboard_text(DISCORD_LINK))

        dpg.add_separator()
        dpg.add_spacer(height=4)

        with dpg.tab_bar(tag="main_tabs"):

            # COMBAT
            with dpg.tab(label="  Combat  "):
                with dpg.child_window(height=-1, border=False):
                    section("AIMBOT")
                    dpg.add_checkbox(label="Aimbot Enabled",
                                     default_value=cfg["aimbot_enabled"],
                                     callback=lambda s, a: cfg.update({"aimbot_enabled": a}))
                    dpg.add_slider_int(label="Smoothness",
                                       default_value=cfg["aimbot_smoothness"],
                                       min_value=1, max_value=100, format="%d%%",
                                       callback=lambda s, a: cfg.update({"aimbot_smoothness": a}))
                    dpg.add_slider_int(label="FOV Radius",
                                       default_value=cfg["fov_radius"],
                                       min_value=10, max_value=500, format="%d px",
                                       callback=lambda s, a: cfg.update({"fov_radius": a}))
                    dpg.add_checkbox(label="Draw FOV Circle",
                                     default_value=cfg["draw_fov"],
                                     callback=lambda s, a: cfg.update({"draw_fov": a}))
                    dpg.add_checkbox(label="Fill FOV Circle",
                                     default_value=cfg["fov_filled"],
                                     callback=lambda s, a: cfg.update({"fov_filled": a}))
                    dpg.add_color_edit(label="FOV Color",
                                       default_value=cfg["fov_color"],
                                       alpha_preview=True,
                                       callback=lambda s, a: cfg.update({"fov_color": list(a)}))
                    dpg.add_combo(label="Target Bone",
                                  items=BONES,
                                  default_value=cfg["target_bone"],
                                  callback=lambda s, a: cfg.update({"target_bone": a}))
                    dpg.add_checkbox(label="Team Check",
                                     default_value=cfg["team_check"],
                                     callback=lambda s, a: cfg.update({"team_check": a}))
                    dpg.add_text(f"Aimbot Key:  [V]  (0x{cfg['aimbot_key']:02X})",
                                 color=(120, 190, 210, 200))

                    section("SILENT AIM")
                    dpg.add_checkbox(label="Silent Aim Enabled",
                                     default_value=cfg["silent_aim_enabled"],
                                     callback=lambda s, a: cfg.update({"silent_aim_enabled": a}))
                    dpg.add_slider_int(label="Silent FOV",
                                       default_value=cfg["silent_fov"],
                                       min_value=10, max_value=500, format="%d px",
                                       callback=lambda s, a: cfg.update({"silent_fov": a}))
                    dpg.add_slider_int(label="Silent Smoothness",
                                       default_value=cfg["silent_smoothness"],
                                       min_value=1, max_value=100, format="%d%%",
                                       callback=lambda s, a: cfg.update({"silent_smoothness": a}))
                    dpg.add_combo(label="Silent Target Bone",
                                  items=BONES,
                                  default_value=cfg["silent_bone"],
                                  callback=lambda s, a: cfg.update({"silent_bone": a}))
                    dpg.add_text(f"Silent Key:  [X]  (0x{cfg['silent_key']:02X})",
                                 color=(120, 190, 210, 200))

            # VISUALS
            with dpg.tab(label="  Visuals  "):
                with dpg.child_window(height=-1, border=False):
                    section("ESP")
                    dpg.add_checkbox(label="ESP Enabled",
                                     default_value=cfg["esp_enabled"],
                                     callback=lambda s, a: cfg.update({"esp_enabled": a}))
                    dpg.add_checkbox(label="Box ESP",
                                     default_value=cfg["box_esp"],
                                     callback=lambda s, a: cfg.update({"box_esp": a}))
                    dpg.add_checkbox(label="Name ESP",
                                     default_value=cfg["name_esp"],
                                     callback=lambda s, a: cfg.update({"name_esp": a}))
                    dpg.add_checkbox(label="Health Bar",
                                     default_value=cfg["health_bar"],
                                     callback=lambda s, a: cfg.update({"health_bar": a}))
                    dpg.add_checkbox(label="Skeleton ESP",
                                     default_value=cfg["skeleton_esp"],
                                     callback=lambda s, a: cfg.update({"skeleton_esp": a}))
                    dpg.add_spacer(height=6)
                    dpg.add_color_edit(label="ESP Color",
                                       default_value=cfg["esp_color"],
                                       alpha_preview=True,
                                       callback=lambda s, a: cfg.update({"esp_color": list(a)}))

            # WORLD
            with dpg.tab(label="  World  "):
                with dpg.child_window(height=-1, border=False):
                    section("WORLD HACKS")
                    dpg.add_checkbox(label="No Flash",
                                     default_value=cfg["no_flash"],
                                     callback=lambda s, a: cfg.update({"no_flash": a}))
                    dpg.add_checkbox(label="Radar Hack",
                                     default_value=cfg["radar"],
                                     callback=lambda s, a: cfg.update({"radar": a}))
                    dpg.add_checkbox(label="Fullbright",
                                     default_value=cfg["fullbright"],
                                     callback=lambda s, a: cfg.update({"fullbright": a}))

            # SETTINGS
            with dpg.tab(label="  Settings  "):
                with dpg.child_window(height=-1, border=False):
                    section("KEYS")
                    dpg.add_text(f"Menu Toggle:  INSERT  (0x{cfg['menu_key']:02X})",
                                 color=(150, 210, 230, 220))
                    dpg.add_text(f"Panic / Exit: END     (0x{cfg['panic_key']:02X})",
                                 color=(200, 80, 80, 220))

                    section("PERFORMANCE")
                    dpg.add_slider_int(label="FPS Limit",
                                       default_value=cfg["fps_limit"],
                                       min_value=30, max_value=360, format="%d fps",
                                       callback=lambda s, a: cfg.update({"fps_limit": a}))

                    section("UI SCALE")
                    dpg.add_slider_float(label="UI Scale",
                                         default_value=cfg["ui_scale"],
                                         min_value=0.6, max_value=2.0, format="%.2fx",
                                         callback=rebuild_ui_scale)
                    dpg.add_text("Drag the mobile button when menu is hidden",
                                 color=(100, 170, 190, 180))

                    section("MOBILE BUTTON POSITION")
                    dpg.add_slider_int(label="Btn X",
                                       default_value=cfg["mobile_btn_x"],
                                       min_value=0, max_value=1920,
                                       callback=lambda s, a: (
                                           cfg.update({"mobile_btn_x": a}),
                                           dpg.set_item_pos("mobile_toggle_window",
                                               [a, cfg["mobile_btn_y"]])))
                    dpg.add_slider_int(label="Btn Y",
                                       default_value=cfg["mobile_btn_y"],
                                       min_value=0, max_value=1080,
                                       callback=lambda s, a: (
                                           cfg.update({"mobile_btn_y": a}),
                                           dpg.set_item_pos("mobile_toggle_window",
                                               [cfg["mobile_btn_x"], a])))

                    section("CONFIG")
                    with dpg.group(horizontal=True):
                        dpg.add_button(label="Save Config", width=140,
                                       callback=lambda: save_cfg())
                        dpg.add_button(label="Load Config", width=140,
                                       callback=lambda: load_cfg())
                        dpg.add_button(label="Reset", width=100,
                                       callback=lambda: (
                                           os.remove(CFG_PATH)
                                           if os.path.exists(CFG_PATH) else None))

            # MISC
            with dpg.tab(label="  Misc  "):
                with dpg.child_window(height=-1, border=False):
                    section("MOVEMENT")
                    dpg.add_checkbox(label="Bunny Hop",
                                     default_value=cfg["bhop"],
                                     callback=lambda s, a: cfg.update({"bhop": a}))
                    dpg.add_checkbox(label="Auto Strafe",
                                     default_value=cfg["auto_strafe"],
                                     callback=lambda s, a: cfg.update({"auto_strafe": a}))
                    dpg.add_checkbox(label="Long Jump",
                                     default_value=cfg["long_jump"],
                                     callback=lambda s, a: cfg.update({"long_jump": a}))

                    section("COSMETIC")
                    dpg.add_checkbox(label="Clantag Spoof",
                                     default_value=cfg["clantag_spoof"],
                                     callback=lambda s, a: cfg.update({"clantag_spoof": a}))
                    dpg.add_input_text(label="Clantag Text",
                                       default_value=cfg["clantag_text"],
                                       width=200,
                                       callback=lambda s, a: cfg.update({"clantag_text": a}))

    dpg.create_viewport(title="AngelHub v2.0", width=w + 20, height=h + 20,
                        always_on_top=True, decorated=True)
    dpg.setup_dearpygui()
    dpg.show_viewport()
    dpg.start_dearpygui()
    dpg.destroy_context()

# ── entry ─────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    load_cfg()
    try_attach()
    threading.Thread(target=combat_loop, daemon=True).start()
    threading.Thread(target=key_loop,    daemon=True).start()
    build_ui()
