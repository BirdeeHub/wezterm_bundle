inputs:
{
  config,
  wlib,
  lib,
  ...
}:
{
  imports = [ wlib.wrapperModules.tmux ];
  prefix = "C-Space";
  terminal = "xterm-256color";
  terminalOverrides = ",${config.terminal}:RGB";
  secureSocket = true;
  statusKeys = "vi";
  modeKeys = "vi";
  vimVisualKeys = true;
  disableConfirmationPrompt = true;
  configBefore = /*tmux*/ ''
    bind-key -N "Select the previously current window" C-p last-window
    bind-key -N "Switch to the last client" P switch-client -l

    bind -r -N "Resize the pane left" H resize-pane -L
    bind -r -N "Resize the pane down" J resize-pane -D
    bind -r -N "Resize the pane up" K resize-pane -U
    bind -r -N "Resize the pane right" L resize-pane -R

    bind -r -N "Resize the pane left by 5" C-H resize-pane -L 5
    bind -r -N "Resize the pane down by 5" C-J resize-pane -D 5
    bind -r -N "Resize the pane up by 5" C-K resize-pane -U 5
    bind -r -N "Resize the pane right by 5" C-L resize-pane -R 5

    bind -r -N "Move the visible part of the window left" M-h refresh-client -L 10
    bind -r -N "Move the visible part of the window up" M-j refresh-client -U 10
    bind -r -N "Move the visible part of the window down" M-k refresh-client -D 10
    bind -r -N "Move the visible part of the window right" M-l refresh-client -R 10
  '';
  plugins = [
    config.pkgs.tmuxPlugins.onedark-theme
    {
      plugin = (
        config.pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "tmux-navigate";
          version = "master";
          src = inputs.tmux-navigate-src;
          rtpFilePath = "tmux-navigate.tmux";
        }
      );
      configBefore = /* tmux */ ''
        set -g @navigate-left  'h'
        set -g @navigate-down  'j'
        set -g @navigate-up    'k'
        set -g @navigate-right 'l'
        set -g @navigate-back  'C-p'
      '';
    }
  ];
  extraDrvAttrs.postBuild = let
    tx = /*bash*/''
      #!${config.pkgs.bash}/bin/bash
      if [[ $(${placeholder "out"}/bin/tmux list-sessions -F '#{?session_attached,1,0}' | grep -c '0') -ne 0 ]]; then
        selected_session=$(${placeholder "out"}/bin/tmux list-sessions -F '#{?session_attached,,#{session_name}}' | tr '\n' ' ' | awk '{print $1}')
        exec ${placeholder "out"}/bin/tmux new-session -At $selected_session
      else
        exec ${placeholder "out"}/bin/tmux new-session
      fi
    '';
  in ''
    echo ${lib.escapeShellArg tx} > $out/bin/tx
    chmod +x $out/bin/tx
  '';
  # module code to include with root installs
  # This is required so that tmux can write to /var/run/utmp
  # (which can be queried with who to display currently connected user sessions).
  # Note, this will add a guid wrapper for the group utmp!
  # see programs.tmux.withUtempter
  # module code to include with root installs
  passthru.nixosModule = {
    config.security.wrappers = {
      utempter = {
        source = "${config.pkgs.libutempter}/lib/utempter/utempter";
        owner = "root";
        group = "utmp";
        setuid = false;
        setgid = true;
      };
    };
  };
}
