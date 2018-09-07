Add iconlauncher_icon to the theme's properties.

Use something like this in your rc.lua where your wibox is created:

```lua
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    local left_widgets = {}
    if s.index == 2 then
            s.ic = iconlauncher.new("left", 64, "#FF00FF22", s)
            left_widgets = {
                layout = wibox.layout.fixed.horizontal,
                mylauncher,
                s.ic.togglebutton,
                s.mytaglist,
                s.mypromptbox,
            }
    else
            left_widgets = {
                layout = wibox.layout.fixed.horizontal,
                mylauncher,
                s.mytaglist,
                s.mypromptbox,
            }
    end
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        left_widgets,
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            mytextclock,
            s.mylayoutbox,
        },
    }
```

NOTE: Currently only one instance is supported.
Otherwise you get all symbols twice with two screens and three times
with three screens, etc...
