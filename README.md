# Wezterm+tmux+zsh DRV

This was a somewhat successful experiment that I will be messing with further in my system flake.

If you were curious how to bundle a config into a tmux executable, wrap a wezterm, or wrap a zsh, this might be a useful example.

It wont source the tmux config unless you tmux kill-server your tmux first.

you can override extraPATH to add more programs in it.

You can override quite a few things now actually, although the wez directory is mostly suitable for editing compared to overriding.

I'm not trying to make a wezterm wrapper that can be consumed like that I'm just trying some things out.

The tmux wrapper though is pretty alright I think, and nixCats came in handy for wezterm too.
