local fromnix = require 'nixStuff'
local wezterm = require "wezterm"
-- local sessionizer = require("sessionizer")

return {
	hide_tab_bar_if_only_one_tab = true,
	keys = {},
	allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
	window_padding = {
		left = 0,
		right = -1,
		top = 0,
		bottom = -5,
		-- left = "0px",
		-- right = "0px",
		-- top = "0px",
		-- bottom = "0px",
	},
	adjust_window_size_when_changing_font_size = nil,
	use_fancy_tab_bar = false,
	show_tabs_in_tab_bar = false,
	tab_bar_at_bottom = false,
	command_palette_rows = 0,
	font = wezterm.font(fromnix.fontString),
	font_dirs = fromnix.fontDirs,
	font_size = 11,
	color_scheme = "Konsolas",
	color_scheme_dirs = { wezterm.config_dir .. "/colors" },
	set_environment_variables = fromnix.envVars,
	use_ime = true,
	default_prog = fromnix.shellString,
	enable_kitty_keyboard = true,
	window_background_opacity = 1,
	window_decorations = "NONE", -- <-- fixes the bars around the tmux but breaks i3 border
	window_close_confirmation = "NeverPrompt",
	enable_tab_bar = false,
	-- front_end = "Software",
	front_end = "OpenGL",
	-- front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance", -- "LowPower",
	webgpu_preferred_adapter = nil,
	webgpu_force_fallback_adapter = false,
	check_for_updates = false,
	enable_wayland = true,
	max_fps = 165,
	anti_alias_custom_block_glyphs = true,
	default_cursor_style = "SteadyBlock",
	warn_about_missing_glyphs = true,
	tiling_desktop_environments = {
		"X11 i3",
		"Wayland sway",
	},
	hyperlink_rules = {
		-- Matches: a URL in parens: (URL)
		{
			regex = "\\((\\w+://\\S+)\\)",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in brackets: [URL]
		{
			regex = "\\[(\\w+://\\S+)\\]",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in curly braces: {URL}
		{
			regex = "\\{(\\w+://\\S+)\\}",
			format = "$1",
			highlight = 1,
		},
		-- Matches: a URL in angle brackets: <URL>
		{
			regex = "<(\\w+://\\S+)>",
			format = "$1",
			highlight = 1,
		},
		-- Then handle URLs not wrapped in brackets
		{
			regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
			format = "$0",
		},
		-- implicit mailto link
		{
			regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
			format = "mailto:$0",
		},
	},
}
