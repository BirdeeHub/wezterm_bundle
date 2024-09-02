{
  lib,
  stdenv,
  writeShellScriptBin,
  writeText,
  wezterm,
  zsh,
  nerdfonts,
  callPackage,
  nixToLua,
  nerdString ? "FiraMono",

  tmux,
  autotx ? true,
  custom_tx_script ? null,
  zdotdir ? null,
  wrapZSH ? false,
  extraPATH ? [ ],
  ...
}:
let

  nerdpkg = nerdfonts.override {
    fonts = [
      nerdString
    ];
  };

  fzdotdir = if zdotdir != null then zdotdir else callPackage ./zdot { };

  tmuxf = tmux.override (prev: {
    isAlacritty = false;
    passthruvars = (if prev ? passthruvars then prev.passthruvars else []) ++ (builtins.attrNames passables.envVars);
  });

  tx = if custom_tx_script != null then custom_tx_script else writeShellScriptBin "tx" /*bash*/''
    if ! echo "$PATH" | grep -q "${tmuxf}/bin"; then
      export PATH=${tmuxf}/bin:$PATH
    fi
    if [[ $(tmux list-sessions -F '#{?session_attached,1,0}' | grep -c '0') -ne 0 ]]; then
      selected_session=$(tmux list-sessions -F '#{?session_attached,,#{session_name}}' | tr '\n' ' ' | awk '{print $1}')
      exec tmux new-session -At $selected_session
    else
      exec tmux new-session
    fi
  '';

  extraBin = [ tmuxf tx ] ++ extraPATH;

  passables = {
    cfgdir = "${wezCFG}";
    fontDirs = [ "${nerdpkg}/share/fonts" ];
    shellString = [
      "${zsh}/bin/zsh"
    ] ++ (lib.optionals (tx != null && autotx) [
      "-c"
      "exec ${tx}/bin/tx"
    ]);
    inherit nerdString wrapZSH extraBin;
    envVars = {
    } // (if wrapZSH then {
      ZDOTDIR = "${fzdotdir}";
    } else {});
  };

  wezinit = writeText "init.lua" /*lua*/ ''
    package.preload["nixStuff"] = function()
      -- mini nixCats plugin
      return ${nixToLua.toLua passables}
    end
    local cfgdir = require('nixStuff').cfgdir
    package.path = package.path .. ';' .. cfgdir .. '/?.lua;' .. cfgdir .. '/?/init.lua'
    package.cpath = package.cpath .. ';' .. cfgdir .. '/?.so'
    local wezterm = require 'wezterm'
    wezterm.config_dir = cfgdir
    return require 'init'
  '';

  wezCFG = stdenv.mkDerivation {
    name = "weztermCFG";
    builder = writeText "builder.sh" /* bash */ ''
      source $stdenv/setup
      mkdir -p $out
      cp -r ${./.}/* $out/
    '';
  };

in
writeShellScriptBin "wezterm" ''
  export PATH="${lib.makeBinPath extraBin}:$PATH"
  declare -f __bp_install_after_session_init && source '${wezterm}/etc/profile.d/wezterm.sh'
  exec ${wezterm}/bin/wezterm --config-file ${wezinit} $@
''
