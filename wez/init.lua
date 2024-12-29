local fromnix = require 'nixStuff'
local wezterm = require "wezterm"
-- local sessionizer = require("sessionizer")

return {
	font = wezterm.font(fromnix.fontString),
	font_dirs = fromnix.fontDirs,
	font_size = 11,
	color_scheme = "kanagawa_custom",
	color_scheme_dirs = { wezterm.config_dir .. "/colors" },
	set_environment_variables = fromnix.envVars,
	use_ime = true,
	default_prog = fromnix.shellString,
	enable_kitty_keyboard = true,
	window_background_opacity = 1,
	window_decorations = "NONE",
	window_close_confirmation = "NeverPrompt",
	enable_tab_bar = false,
	webgpu_power_preference = "HighPerformance",
	check_for_updates = false,
	enable_wayland = true,
	max_fps = 165,
	anti_alias_custom_block_glyphs = true,
	default_cursor_style = "SteadyBlock",
	warn_about_missing_glyphs = true,
	tiling_desktop_environments = {
		"Wayland sway",
		"X11 i3",
	},
	window_padding = {
		left = "0px",
		right = "0px",
		top = "0px",
		bottom = "0px",
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
