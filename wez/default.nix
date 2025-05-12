{
  pkgs,
  lib,
  runCommand,
  makeWrapper,
  writeShellScriptBin,
  writeText,
  wezterm,
  zsh,
  callPackage,
  nixToLua,
  fontString ? "FiraMono Nerd Font",
  fontpkg ? pkgs.nerd-fonts.fira-mono,

  tmux,
  wezcfg ? ./.,
  autotx ? true,
  custom_tx_script ? null,
  zdotdir ? null,
  wrapZSH ? false,
  extraPATH ? [ ],
  extraWrapperArgs ? [],
  ...
}:
let

  fzdotdir = if zdotdir != null then zdotdir else callPackage ./zdot { };

  tmuxf = tmux.override (prev: {
    isAlacritty = false;
    passthruvars = (if prev ? passthruvars then prev.passthruvars else []) ++ (builtins.attrNames passables.envVars);
  });

  tx = if custom_tx_script != null then custom_tx_script else writeShellScriptBin "tx" /*bash*/''
    if [[ $(tmux list-sessions -F '#{?session_attached,1,0}' | grep -c '0') -ne 0 ]]; then
      selected_session=$(tmux list-sessions -F '#{?session_attached,,#{session_name}}' | tr '\n' ' ' | awk '{print $1}')
      exec tmux new-session -At $selected_session
    else
      exec tmux new-session
    fi
  '';

  extraBin = [ tmuxf tx ] ++ extraPATH;

  passables = {
    cfgdir = runCommand "wezCFG" {} ''
      mkdir -p $out
      cp -r ${wezcfg}/* $out/
    '';
    fontDirs = [ "${fontpkg}/share/fonts" ];
    shellString = [
      "${zsh}/bin/zsh"
    ] ++ (lib.optionals (tx != null && autotx) [
      "-c"
      "exec ${tx}/bin/tx"
    ]);
    inherit fontString wrapZSH extraBin;
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

  wrapperArgs = [
    "${wezterm}/bin/wezterm"
    "${placeholder "out"}/bin/wezterm"
    "--inherit-argv0"
    "--prefix" "PATH" ":" "${lib.makeBinPath extraBin}"
    "--add-flags" "--config-file ${wezinit}"
    "--run" /*bash*/''
      declare -f __bp_install_after_session_init && source '${wezterm}/etc/profile.d/wezterm.sh'
    ''
  ] ++ extraWrapperArgs;
in
runCommand "wezterm" {
  nativeBuildInputs = [ makeWrapper ];
} ''
  mkdir -p $out/bin
  makeWrapper ${lib.escapeShellArgs wrapperArgs}
''
