{ lib
, tmux
, stdenv
, tmuxPlugins
, runCommand
, makeWrapper
, writeText

# Store tmux socket under {file}`/run`, which is more
# secure than {file}`/tmp`, but as a downside it doesn't
# survive user logout.
, secureSocket ? stdenv.isLinux

# Start with defaults from the Sensible plugin
, sourceSensible ? true
, tmux-navigate-src ? null

, pluginSpecs ? null # <-- type list of plugin or spec [ drv1 { plugin = drv2; configBefore = ""; configAfter = ""; } ]
, global_env_vars ? {}
, passthruvars ? []
, prefix ? "C-Space"
, term_string ? "xterm-256color"
, configBefore ? ""
, configAfter ? ""
, new_tmux_opts ? ""
, new_tmux_keys ? ""
, extraWrapperArgs ? []
, ...
}: let

  plugins = (if pluginSpecs != null then pluginSpecs else [
    tmuxPlugins.onedark-theme
  ]) ++ lib.optional (tmux-navigate-src != null) {
    plugin = (tmuxPlugins.mkTmuxPlugin {
      pluginName = "tmux-navigate";
      version = "master";
      src = tmux-navigate-src;
      rtpFilePath = "tmux-navigate.tmux";
    });
    configBefore = /*tmux*/ ''
      set -g @navigate-left  'h'
      set -g @navigate-down  'j'
      set -g @navigate-up    'k'
      set -g @navigate-right 'l'
      set -g @navigate-back  'C-p'
    '';
  };

  # tmuxBoolToStr = value: if value then "on" else "off";
  defaulttmuxopts = /*tmux*/''
    set -g display-panes-colour default
    set -ga update-environment TERM
    set -ga update-environment TERM_PROGRAM
    set -g default-terminal ${term_string}
    set -ga terminal-overrides ",${term_string}:RGB"

    unbind C-b
    set-option -g prefix ${prefix}
    set -g prefix ${prefix}
    bind -N "Send the prefix key through to the application" \
      ${prefix} send-prefix

    set  -g base-index      1
    setw -g pane-base-index 1

    set  -g mouse             on
    setw -g aggressive-resize off
    setw -g clock-mode-style  12
    set  -s escape-time       500
    set  -g history-limit     2000
    set -gq allow-passthrough on
    set -g visual-activity off

    set -g status-keys vi
    set -g mode-keys   vi

  '';
  defaulttmuxkeys = /*tmux*/''
  bind-key -N "Kill the current window" & kill-window
  bind-key -N "Kill the current pane" x kill-pane

  bind-key -N "Select the previously current window" C-p last-window
  bind-key -N "Switch to the last client" P switch-client -l
  set-window-option -g mode-keys vi
  bind-key -T copy-mode-vi 'v' send -X begin-selection
  bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel

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

  '' + lib.optionalString (tmux-navigate-src == null) /*tmux*/''
  bind -N "Select pane to the left of the active pane" h select-pane -L
  bind -N "Select pane below the active pane" j select-pane -D
  bind -N "Select pane above the active pane" k select-pane -U
  bind -N "Select pane to the right of the active pane" l select-pane -R
  '';

  TMUXconf = writeText "tmux.conf" (/* tmux */ (if sourceSensible then ''
    # ============================================= #
    # Start with defaults from the Sensible plugin  #
    # --------------------------------------------- #
    run-shell ${tmuxPlugins.sensible.rtp}
    # ============================================= #

    '' else "") + ''
    ${if new_tmux_opts != "" then new_tmux_opts else defaulttmuxopts}

    ${if new_tmux_keys != "" then new_tmux_keys else defaulttmuxkeys}

    ${configBefore}

    ${addPassthruVars passthruvars}

    ${addGlobalVars global_env_vars}

    ${configPlugins plugins}

    ${configAfter}
  '');

  addGlobalVars = set: let
    listed = builtins.attrValues (builtins.mapAttrs (k: v: ''set-environment -g ${k} "${v}"'') set);
  in builtins.concatStringsSep "\n" listed;

  addPassthruVars = ptv: lib.optionalString (ptv != [])
    ''set-option -g update-environment "${builtins.concatStringsSep " " ptv}"'';

  configPlugins = plugins: (let
    pluginName = p: if lib.types.package.check p then p.pname else p.plugin.pname;
    pluginRTP = p: if lib.types.package.check p then p.rtp else p.plugin.rtp;
    pluginConfigPre = p: if lib.types.package.check p then "" else p.configBefore or "";
    pluginConfigPost = p: if lib.types.package.check p then "" else p.configAfter or "";
  in
    if plugins == [] || ! (builtins.isList plugins) then "" else ''
      # ============================================== #
      ${(lib.concatMapStringsSep "\n\n" (p: ''
        # ${pluginName p}
        # ---------------------
        ${pluginConfigPre p}
        run-shell ${pluginRTP p}
        ${pluginConfigPost p}
        # ---------------------
      '') plugins)}
      # ============================================== #
    ''
  );

  wrapperArgs = [
    "${tmux}/bin/tmux"
    "${placeholder "out"}/bin/tmux"
    "--inherit-argv0"
    "--add-flags"
    "-f ${TMUXconf}"
  ] ++ lib.optionals secureSocket [
    "--run"
    ''export TMUX_TMPDIR=''${TMUX_TMPDIR:-''${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}}''
  ] ++ extraWrapperArgs;

  # module code to include with root installs
  # config.security.wrappers = {
  #   utempter = {
  #     source = "${pkgs.libutempter}/lib/utempter/utempter";
  #     owner = "root";
  #     group = "utmp";
  #     setuid = false;
  #     setgid = true;
  #   };
  # };
in
runCommand "tmux" {
  nativeBuildInputs = [ makeWrapper ];
} /*bash*/''
  mkdir -p $out/bin
  makeWrapper ${lib.escapeShellArgs wrapperArgs}
''
