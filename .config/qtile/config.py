# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from typing import List  # noqa: F401
from libqtile import hook
from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Match, Screen, ScratchPad, DropDown
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

colors = [["#171717", "#171717"],   # 0: black
         ["#f1f1f1", "#f1f1f1"],    # 1: white
         ["#fb007a", "#fb007a"],    # 2: red
         ["#10a778", "#10a778"],    # 3: green
         ["#a89c14", "#a89c14"],    # 4: yellow
         ["#008ec4", "#008ec4"],    # 5: blue
         ["#523c79", "#523c79"],    # 6: magenta
         ["#20a5ba", "#20a5ba"]]    # 7: cyan

mod = "mod4"
terminal = guess_terminal()

keys = [
    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html

    # Switch between windows
    Key(
      [mod], "h", 
      lazy.layout.left(), 
      desc="Move focus to left"
    ),
    Key(
      [mod], "l", 
      lazy.layout.right(), 
      desc="Move focus to right"
    ),
    Key(
      [mod], "j", 
      lazy.layout.down(), 
      desc="Move focus down"
    ),
    Key(
      [mod], "k", 
      lazy.layout.up(), 
      desc="Move focus up"
    ),

    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key(
      [mod, "shift"], "h", 
      lazy.layout.shuffle_left(),
      desc="Move window to the left"
    ),
    Key(
      [mod, "shift"], "l", 
      lazy.layout.shuffle_right(),
      desc="Move window to the right"
    ),
    Key(
      [mod, "shift"], "j", 
      lazy.layout.shuffle_down(),
      desc="Move window down"
    ),
    Key(
      [mod, "shift"], "k", 
      lazy.layout.shuffle_up(), 
      desc="Move window up"
    ),

    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key(
      [mod, "control"], "p", 
      lazy.layout.grow_left(),
      desc="Grow window to the left"
    ),
    Key(
      [mod, "control"], "l", 
      lazy.layout.grow_right(),
      desc="Grow window to the right"
    ),
    Key(
      [mod, "control"], "j", 
      lazy.layout.grow_down(),
      desc="Grow window down"
    ),
    Key(
      [mod, "control"], "k", 
      lazy.layout.grow_up(), 
      desc="Grow window up"
    ),
    Key(
      [mod], "n", 
      lazy.next_layout(), 
      desc="Toggle through layouts"
    ),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
      [mod, "shift"], "space", 
      lazy.layout.toggle_split(),
      desc="Toggle between split andunsplit sides of stack"
    ),
    Key(
      [mod, "shift"], "Return", 
      lazy.spawn(terminal), 
      desc="Launch terminal"
    ),
    Key(
      [mod], "w",
      lazy.spawn("flatpak run app.zen_browser.zen"), 
      desc="Launch zen browser"
    ),
    Key(
      [mod], "b", 
      lazy.spawn("background-change"), 
      desc="Change background wallpaper"
    ),
    Key(
      [mod], "BackSpace", 
      lazy.spawn("change-keyboard-layout"), 
      desc="Change keyboard language"
    ),

    # Toggle between different layouts as defined below
    Key(
      [mod], "Tab", 
      lazy.screen.toggle_group(),
      desc="Toggle between layouts"
    ),
    Key(
      [mod, "shift"], "c", 
      lazy.window.kill(), 
      desc="Kill focused window"
    ),
    Key(
      [mod, "control"], "r", 
      lazy.reload_config(), 
      desc="Reload the config"
    ),
    Key(
      [mod, "control"], "q", 
      lazy.shutdown(), 
      desc="Shutdown Qtile"
    ),
    Key(
      [mod], "space", 
      lazy.spawn("rofi -show drun -icon-theme 'Papirus' -show-icons"),
      desc="Spawn a command using a prompt widget"
    ),
    Key(
      [mod], "F2", 
      lazy.spawn("volume-control down"),
      desc="Lower volume"
    ),
    Key(
      [mod], "F3", 
      lazy.spawn("volume-control up"),
      desc="Increase volume"
    ),
    Key(
      [mod, "shift"], "t", 
      lazy.spawn("change-package-to-build"),
        desc="Focus an R-package to build from source"
    ),
    Key(
      [mod, "shift"], "b", 
      lazy.spawn("build-r-package"),
      desc="Focus an R-package to build from source"
    ),
    Key(
      [mod, "shift"], "p", 
      lazy.spawn("flameshot gui"),
      desc="Focus an R-package to build from source"
    ),
    Key(
      [mod], "e", 
      lazy.spawn("/snap/bin/emacs"),
      desc="Spawn an emacs client"
    ),
    Key(
      [mod, "shift"], "l", 
      lazy.prev_screen(),
      desc="Switch to next screen"
    ),
    Key(
      [mod, "shift"], "h", 
      lazy.next_screen(),
      desc="Switch to previous screen"
    ),
    Key(
      [mod], "f", 
      lazy.spawn("nautilus"),
      desc="Open nautilus file manager"
    ),
    Key(
      [mod], "u", 
      lazy.spawn("random-unsplash"),
      desc="Download random unsplash image and set as background"
    ),
    Key(
      [mod, "shift"], "w", 
      lazy.spawn("set-work-screens"),
      desc="Set the screen arrangement in the office"
    ),
    Key(
      [mod, "shift"], "s", 
      lazy.spawn("background-set"),
      desc="Set the desktop background picture"
    ),
    Key(
      [mod], "x", 
      lazy.spawn("i3lock-fancy"),
      desc="locks screen"
    ),
    Key(
      [mod], "y", 
      lazy.spawn("brave --app=https://youtube.com/"),
      desc="Launches youtube"
    ),
    Key(
      [mod], "m", 
      lazy.spawn("brave --app=https://mail.certh.gr/"),
      desc="Launches certh email"
    ),
    Key(
      [mod], "g", 
      lazy.spawn("brave --app=https://mail.google.com/"),
      desc="Launches certh email"
    ),
    Key(
      [mod], "c", 
      lazy.spawn("brave --app=https://calendar.google.com/"),
      desc="Launches certh email"
    ),
    Key(
      [mod], "t", 
      lazy.spawn("brave --app=https://teams.microsoft.com"),
      desc="Launches MS Teams"
    ),
    Key(
      [mod], "o", 
      lazy.spawn("onlyoffice-desktopeditors"),
      desc="Launches OnlyOffice"
    ),
]

# groups = [Group(i) for i in "123456789"]
# groups = [Group(i) for i in "123456789"]
groups = [
    Group(name = "1", label = ""),
    Group(name = "2", label = ""),
    Group(name = "3", label = ""),
    Group(name = "4", label = ""),
    Group(name = "5", label = ""),
    Group(name = "6", label = ""),
    Group(name = "7", label = ""),
    Group(name = "8", label = ""),
    Group(name = "9", label = ""),
    Group(name = "0", label = ""),
]

# Scratchpad
groups.append(ScratchPad('scratchpad', [
    DropDown('term', terminal, width=0.7, height=0.5, x=0.15, y=0.2, on_focus_lost_hide = False),
    DropDown('chatgpt', 'chromium --app=https://chatgpt.com/', width=1, height=1, x=0, on_focus_lost_hide = False),
    DropDown('keepassxc', 'keepassxc', width=0.8, height=0.8, x=0.1, y=0.05, on_focus_lost_hide = False),
    DropDown('blanket', 'blanket', width=0.8, height=0.8, x=0.1, y=0.05, on_focus_lost_hide = False),
]))

keys.extend([
    Key(
        [mod], "Return",
        lazy.group['scratchpad'].dropdown_toggle('term')
    ),
    Key(
        [mod], "q",
        lazy.group['scratchpad'].dropdown_toggle('chatgpt')
    ),
    Key(
        [mod], "b",
        lazy.group['scratchpad'].dropdown_toggle('blanket')
    ),
    Key(
        [mod], "e",
        lazy.group['scratchpad'].dropdown_toggle('keepassxc')
    ),
])

for group in groups:
    if not isinstance(group, ScratchPad):
        keys.extend([
        # mod1 + letter of group = switch to group
            Key([mod], group.name, lazy.group[group.name].toscreen(),
                desc="Switch to group {}".format(group.name)),

            # mod1 + shift + letter of group = switch to & move focused window to group
            Key([mod, "shift"], group.name, lazy.window.togroup(group.name, switch_group=True),
                desc="Switch to & move focused window to group {}".format(group.name)),
    ])

layout_basic={
        "border.width": 8,
        "margin": 1,
        "border_focus": colors[0],
        "border_normal": "#c7c7c7"
        }

layouts = [
    layout.MonadTall(**layout_basic),
    layout.Max(**layout_basic),
]

widget_defaults = dict(
    font='sans',
    fontsize=12,
    padding=3,
)
extension_defaults = widget_defaults.copy()

# ----------------------------------
# Need to turn this into a function
# ----------------------------------
screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    font="FontAwesome",
                    fontsize=14,
                    hide_unused=True,
                    active=colors[0],
                    inactive=colors[0],
                    highlight_method="text",
                    highlight_color="#4184ab",
                    other_current_screen_border=colors[0]
                ),
                widget.Prompt(),
                widget.WindowName(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground = colors[0]
                ),
                widget.CPU(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='CPU: {load_percent}%'
                ),
                widget.Sep(
                    linewidth=0,
                    padding=10
                ),
                widget.Memory(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='RAM: {MemPercent}% [{MemUsed: .2f} {mm} ]',
                    measure_mem='G'
                ),
                widget.Sep(
                    linewidth=0,
                    padding=8
                ),
                # widget.Battery(
                #     font="DejaVu Sans Mono Bold",
                #     fontsize=14,
                #     foreground=colors[0],
                #     format='Battery: {percent:2.0%} [ {char} ]',
                #     discharge_char="discharing",
                #     charge_char = "charging",
                #     update_interval = 10,
                #     hide_threshold = 1.0
                # ),
                # widget.ThermalSensor(),
                widget.Clock(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='%Y-%m-%d %a %I:%M %p'
                ),
            ],
            24,
            background=colors[1],
            border_width=[1, 0, 1, 0],  # Draw top and bottom borders
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    ),
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    font="FontAwesome",
                    fontsize=14,
                    hide_unused=True,
                    active=colors[0],
                    inactive=colors[0],
                    highlight_method="text",
                    highlight_color="#4184ab",
                    other_current_screen_border=colors[0]
                ),
                widget.Prompt(),
                widget.WindowName(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground = colors[0]
                ),
                widget.CPU(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='CPU: {load_percent}%'
                ),
                widget.Sep(
                    linewidth=0,
                    padding=10
                ),
                widget.Memory(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='RAM: {MemPercent}% [{MemUsed: .2f} {mm} ]',
                    measure_mem='G'
                ),
                widget.Sep(
                    linewidth=0,
                    padding=8
                ),
                # widget.Battery(
                #     font="DejaVu Sans Mono Bold",
                #     fontsize=14,
                #     foreground=colors[2],
                #     format='Battery: {percent:2.0%} [ {char} ]',
                #     discharge_char="discharing",
                #     charge_char = "charging",
                #     update_interval = 10,
                #     hide_threshold = 0.1
                # ),
                # widget.ThermalSensor(),
                widget.Clock(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='%Y-%m-%d %a %I:%M %p'
                ),
            ],
            24,
            background=colors[1],
            border_width=[1, 0, 1, 0],  # Draw top and bottom borders
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    ),
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    font="FontAwesome",
                    fontsize=14,
                    hide_unused=True,
                    active=colors[0],
                    inactive=colors[0],
                    highlight_method="text",
                    highlight_color="#4184ab",
                    other_current_screen_border=colors[0]
                ),
                widget.Prompt(),
                widget.WindowName(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground = colors[0]
                ),
                widget.CPU(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='CPU: {load_percent}%'
                ),
                widget.Sep(
                    linewidth=0,
                    padding=10
                ),
                widget.Memory(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='RAM: {MemPercent}% [{MemUsed: .2f} {mm} ]',
                    measure_mem='G'
                ),
                widget.Sep(
                    linewidth=0,
                    padding=8
                ),
                # widget.Battery(
                #     font="DejaVu Sans Mono Bold",
                #     fontsize=14,
                #     foreground=colors[2],
                #     format='Battery: {percent:2.0%} [ {char} ]',
                #     discharge_char="discharing",
                #     charge_char = "charging",
                #     update_interval = 10,
                #     hide_threshold = 0.1
                # ),
                # widget.ThermalSensor(),
                widget.Clock(
                    font="DejaVu Sans Mono Bold",
                    fontsize=14,
                    foreground=colors[0],
                    format='%Y-%m-%d %a %I:%M %p'
                ),
            ],
            24,
            background=colors[1],
            border_width=[1, 0, 1, 0],  # Draw top and bottom borders
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    )
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    *layout.Floating.default_float_rules,
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    Match(wm_class='r_x11'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
])
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

@hook.subscribe.client_new
def move_program_to_group(window):
    window_groups = {
        "Mail": '1',
        "microsoft teams - preview": '2',
        "skype": '2',
        "emacs": '5',
        "qpdfview": '6',
        "libreoffice": '6',
        "workspacesclient": '7',
        "brave-browser": '8'
    }
    wm_class = window.window.get_wm_class()[0] 
    window.togroup(window_groups[wm_class])

wmname = "LG3D" 
