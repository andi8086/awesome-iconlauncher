-- Awesome icon launcher panel
-- (c) 2018 Andreas J. Reichel
--
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")

local _M = {}

local split = function(inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end

-- Convert a lua table into a lua syntactically correct string
function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end


local scandir = function(path, handle_files_callback, bar)
        erg = {}
        awful.spawn.with_line_callback("ls -A1 " .. path,
        {
                output_done = function()
                        _M.handle_files_callback(erg, bar)
                end,
                stdout = function(line)
                        table.insert(erg, line)
                end
        })
end

_M.handle_files_callback = function(file_list, bar_layout)
        for k,file in pairs(file_list) do
                local link = {}
                filepath = _M.desktop_dir .. '/' .. file
                -- open the file
                f = io.open(filepath, "r")
                if f then
                        for line in f:lines() do
                                new_kv = split(line, '=')
                                link[new_kv[1]] = new_kv[2]
                        end
                        f:close()
                end
                link_name = link["Name"] or "unnamed"
                link_icon = link["Icon"] or ""
                link_exec = link["Exec"] or ""

                local ib = awful.widget.button {
                        image = beautiful.iconlauncher_icon,
                }
                ib.scale = false

                ib:buttons(gears.table.join(
                        ib:buttons(),
                        awful.button({}, 1, nil, function()
                                awful.spawn(link_exec)
                        end)
                ))

                local it = wibox.widget {
                        markup = link_name,
                        align = 'center',
                        widget = wibox.widget.textbox
                }


                _M.icon_button = wibox.widget {
                        {
                                widget = ib,
                        },
                        it,
                        bg = "#FFFFFF33",
                        layout = wibox.layout.fixed.vertical,
                }

                bar_layout:add(
                        _M.icon_button
                )
        end
end

_M.new = function(position, width, bgcolor, screen)
        local self = {}

        self.launcherbar = awful.wibar({ position = position, width=width,
                bg = bgcolor, screen=screen or 1, ontop = true})
--      self.launcherbar: setup({layout = wibox.layout.fixed.horizontal})

        -- create a toggle button
        --
        local b = awful.widget.button {
                image = beautiful.iconlauncher_icon
        }

        b:buttons(gears.table.join(
                b:buttons(),
                awful.button({}, 1, nil, function()
                        self.launcherbar.visible = not self.launcherbar.visible
                end)
        ))

        self.togglebutton = {
                {
                        widget = b
                },
                bg = "#FFFFFF33",
                widget = wibox.container.background
        }

        cfghome = gears.filesystem.get_xdg_config_home()

        --if not file_readable(cfghome .. "user-dirs.dirs") then
        --      naughty.notify({ preset = naughty.config.presets.critical,
        --                      title = "xdg cfg home",
        --                      text = "No user-dirs.dirs found. Run xdg-user-dirs-update." })
        --      return self
        --end

        self.launcherbar_layout = wibox.widget {
                homogeneous = true,
                spacing = 5,
                expand = false,
                horizontal_expand = false,
                forced_width = self.launcherbar.width,
                layout = wibox.layout.grid
        }

        awful.spawn.easy_async("bash -c 'xdg-user-dir DESKTOP'",
                function(stdout, stderr, reason, exit_code)
                        if exit_code ~= 0 then
                                naughty.notify({ preset = naughty.config.presets.critical,
                                title = "iconlauncher error",
                                text = "could not run xdg-user-dir DESKTOP" })
                        end

                        _M.desktop_dir = stdout:sub(1, -2) -- remove line break
                        scandir(_M.desktop_dir, self.handle_files_callback, self.launcherbar_layout)
                end)

        self.launcherbar:set_widget(self.launcherbar_layout)
        return self
end

_M.setscreen = function(s)
        self.launcherbar.screen = s
end

_M.hide = function()
        self.launcherbar.visible = false
end

_M.show = function()
        self.launcherbar.visible = true
end

return _M




