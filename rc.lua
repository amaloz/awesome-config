local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
beautiful.init(awful.util.getdir("config") .. "/themes/dust/theme.lua")
local naughty = require("naughty")
local menubar = require("menubar")
local vicious = require("vicious")
local extra = require("extra")

if awesome.startup_errors then
   naughty.notify({ preset = naughty.config.presets.critical,
                    title = "Oops, there were errors during startup!",
                    text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
   local in_error = false
   awesome.connect_signal(
      "debug::error", function (err)
         -- Make sure we don't go into an endless error loop
         if in_error then return end
         in_error = true
         naughty.notify({ preset = naughty.config.presets.critical,
                          title = "Oops, an error happened!",
                          text = err })
         in_error = false
   end)
end

terminal = "roxterm"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"
altkey = "Mod1"

local layouts = {
   awful.layout.suit.fair,
   -- awful.layout.suit.floating,
   -- awful.layout.suit.fair.horizontal,
}

naughty.config.defaults.timeout = 2
naughty.config.defaults.screen = 1
naughty.config.defaults.position = "top_right"
naughty.config.defaults.margin = 8
naughty.config.defaults.gap = 1
naughty.config.defaults.ontop = true
naughty.config.defaults.font = "sans 8"
naughty.config.defaults.icon = nil
naughty.config.defaults.icon_size = 256
naughty.config.defaults.fg = beautiful.fg_tooltip
naughty.config.defaults.bg = beautiful.bg_tooltip
naughty.config.defaults.border_color = beautiful.border_tooltip
naughty.config.defaults.border_width = 2
naughty.config.defaults.hover_timeout = nil

if beautiful.wallpaper then
   for s = 1, screen.count() do
      gears.wallpaper.maximized(beautiful.wallpaper, s, true)
   end
end

tags = {}
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end

mymainmenu = awful.menu({
      items = { { "terminal", terminal },
         { "restart", awesome.restart },
         { "quit", awesome.quit }
} })
menubar.utils.terminal = terminal

mytextclock = awful.widget.textclock(
   "<span color='" .. beautiful.fg_em .. "'>%a %m %d</span> @ %I:%M %p")

mywibox = {}
mypromptbox = {}
mylayoutbox = {}

mytaglist = {}
mytaglist.buttons = awful.util.table.join(
   awful.button({ }, 1, awful.tag.viewonly),
   awful.button({ modkey }, 1, awful.client.movetotag),
   awful.button({ }, 3, awful.tag.viewtoggle),
   awful.button({ modkey }, 3, awful.client.toggletag),
   awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
   awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end))

mytasklist = {}
mytasklist.buttons = awful.util.table.join(
   awful.button({ }, 1, function (c)
         if c == client.focus then
            c.minimized = true
         else
            c.minimized = false
            if not c:isvisible() then
               awful.tag.viewonly(c:tags()[1])
            end
            client.focus = c
            c:raise()
         end
   end),
   awful.button({ }, 3, function ()
         if instance then
            instance:hide()
            instance = nil
         else
            instance = awful.menu.clients({ width=250 })
         end
   end),
   awful.button({ }, 4, function ()
         awful.client.focus.byidx(1)
         if client.focus then client.focus:raise() end
   end),
   awful.button({ }, 5, function ()
         awful.client.focus.byidx(-1)
         if client.focus then client.focus:raise() end
end))

for s = 1, screen.count() do
   mypromptbox[s] = awful.widget.prompt()
   mylayoutbox[s] = awful.widget.layoutbox(s)
   mylayoutbox[s]:buttons(
      awful.util.table.join(
         awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
         awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
         awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
         awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
   mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all,
                                       mytaglist.buttons)
   mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags,
                                         mytasklist.buttons)
   mywibox[s] = awful.wibox({ position = "top", screen = s })

   -- Widgets that are aligned to the left
   local left_layout = wibox.layout.fixed.horizontal()
   left_layout:add(mytaglist[s])
   left_layout:add(space)
   left_layout:add(mypromptbox[s])

   -- Widgets that are aligned to the right
   local right_layout = wibox.layout.fixed.horizontal()
   if s == 1 then right_layout:add(wibox.widget.systray()) end
   right_layout:add(pacicon)
   right_layout:add(pacwidget)
   right_layout:add(space)
   right_layout:add(wifiicon)
   right_layout:add(wifipct)
   right_layout:add(baticon)
   right_layout:add(batpct)
   right_layout:add(space)
   right_layout:add(volicon)
   right_layout:add(volpct)
   right_layout:add(space)
   right_layout:add(weather)
   right_layout:add(space)
   right_layout:add(mytextclock)
   right_layout:add(space)

   -- Now bring it all together (with the tasklist in the middle)
   local layout = wibox.layout.align.horizontal()
   layout:set_left(left_layout)
   layout:set_middle(mytasklist[s])
   layout:set_right(right_layout)

   mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(
   awful.util.table.join(
      awful.button({ }, 3, function () mymainmenu:toggle() end),
      awful.button({ }, 4, awful.tag.viewnext),
      awful.button({ }, 5, awful.tag.viewprev)))
-- }}}

local client_focus_next = function ()
   awful.client.focus.byidx(1)
   if client.focus then client.focus:raise() end
end
local client_focus_prev = function ()
   awful.client.focus.byidx(-1)
   if client.focus then client.focus:raise() end
end

-- {{{ Key bindings
globalkeys = awful.util.table.join(
   awful.key({ modkey, }, "Left",   awful.tag.viewprev),
   awful.key({ modkey, }, "Right",  awful.tag.viewnext),

   awful.key({ modkey }, "Tab", client_focus_next),
   awful.key({ modkey, "Shift" }, "Tab", client_focus_prev),

   awful.key({ modkey }, "w", function () mymainmenu:show() end),

   -- Layout manipulation
   awful.key({ modkey, "Shift" }, "j", function () awful.client.swap.byidx(  1) end),
   awful.key({ modkey, "Shift" }, "k", function () awful.client.swap.byidx( -1) end),
   awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
   awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),

   -- Standard program
   awful.key({ modkey }, "Return", function () awful.util.spawn(terminal) end),
   awful.key({ modkey, "Control" }, "r", awesome.restart),
   awful.key({ modkey, "Shift" }, "q", awesome.quit),

   awful.key({ modkey }, "l", function () awful.tag.incmwfact( 0.05) end),
   awful.key({ modkey }, "h", function () awful.tag.incmwfact(-0.05) end),
   awful.key({ modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1) end),
   awful.key({ modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1) end),
   -- awful.key({ modkey, "Control" }, "h", function () awful.tag.incncol( 1) end),
   -- awful.key({ modkey, "Control" }, "l", function () awful.tag.incncol(-1) end),
   awful.key({ modkey }, "space", function () awful.layout.inc(layouts,  1) end),
   awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(layouts, -1) end),
   awful.key({ modkey, "Control" }, "n", awful.client.restore),

   -- Prompt
   awful.key({ modkey }, "r",
      function () mypromptbox[mouse.screen]:run() end),
   awful.key({ modkey }, "x",
      function ()
         awful.prompt.run({ prompt = "Run Lua code: " },
            mypromptbox[mouse.screen].widget,
            awful.util.eval, nil,
            awful.util.getdir("cache") .. "/history_eval")
   end),
   -- Menubar
   -- awful.key({ modkey }, "p", function() menubar.show() end),
   -- Lock
   awful.key({ modkey, "Shift" }, "l",
      function() awful.util.spawn("slock") end)
)

clientkeys = awful.util.table.join(
   awful.key({ modkey, }, "f", function (c) c.fullscreen = not c.fullscreen end),
   awful.key({ modkey, "Shift" }, "c", function (c) c:kill() end),
   awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle                     ),
   -- awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
   awful.key({ modkey, }, "o", awful.client.movetoscreen),
   awful.key({ modkey, }, "t", function (c) c.ontop = not c.ontop end),
   awful.key({ modkey, }, "n",
      function (c)
         -- The client currently has the input focus, so it cannot be
         -- minimized, since minimized clients can't have the focus.
         c.minimized = true
   end),
   awful.key({ modkey, }, "m",
      function (c)
         c.maximized_horizontal = not c.maximized_horizontal
         c.maximized_vertical   = not c.maximized_vertical
   end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber))
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
   globalkeys = awful.util.table.join(
      globalkeys,
      awful.key({ modkey }, "#" .. i + 9,
         function ()
            local screen = mouse.screen
            if tags[screen][i] then
               awful.tag.viewonly(tags[screen][i])
            end
      end),
      awful.key({ modkey, "Control" }, "#" .. i + 9,
         function ()
            local screen = mouse.screen
            if tags[screen][i] then
               awful.tag.viewtoggle(tags[screen][i])
            end
      end),
      awful.key({ modkey, "Shift" }, "#" .. i + 9,
         function ()
            if client.focus and tags[client.focus.screen][i] then
               awful.client.movetotag(tags[client.focus.screen][i])
            end
      end),
      awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
         function ()
            if client.focus and tags[client.focus.screen][i] then
               awful.client.toggletag(tags[client.focus.screen][i])
            end
   end))
end

clientbuttons = awful.util.table.join(
   awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
   awful.button({ modkey }, 1, awful.mouse.client.move),
   awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

awful.rules.rules = {
   { rule = { },
     properties = { border_width = beautiful.border_width,
                    border_color = beautiful.border_normal,
                    focus = awful.client.focus.filter,
                    keys = clientkeys,
                    buttons = clientbuttons,
                    size_hints_honor = false, } },
}

-- Signal function to execute when a new client appears.
client.connect_signal(
   "manage", function (c, startup)
      -- Enable sloppy focus
      c:connect_signal("mouse::enter", function(c)
                          if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
                          and awful.client.focus.filter(c) then
                             client.focus = c
                          end
      end)

      if not startup then
         -- Set the windows at the slave,
         -- i.e. put it at the end of others instead of setting it master.
         -- awful.client.setslave(c)

         -- Put windows in a smart way, only if they does not set an initial position.
         if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
         end
      end
end)

client.connect_signal(
   "focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal(
   "unfocus", function(c) c.border_color = beautiful.border_normal end)
