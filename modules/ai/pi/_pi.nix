{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Override pi to use a temp directory on the same filesystem as /home.
  # Fixes EXDEV (cross-device link) errors caused by /tmp being tmpfs
  # while ~/.pi is on ext4. See: anthropics/claude-code#24043
  #
  # Uses overrideAttrs instead of symlinkJoin to preserve the original
  # package identity (name, version) — visible in nh os switch output.
  pi = pkgs.llm-agents.pi.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      # Inject TMPDIR setup before the final exec in pi's wrapper script.
      sed -i 's@^exec @export TMPDIR="$HOME/.pi/tmp"\nmkdir -p "$TMPDIR" 2>/dev/null || true\nexec @' $out/bin/pi
    '';
  });
in
{
  home.packages = with pkgs; [
    pi
  ];

  # npm on NixOS can't write to /nix/store, so global installs fail.
  # Redirect prefix to a writable location.
  programs.npm = {
    enable = true;
    settings = {
      prefix = "${config.home.homeDirectory}/.local/share/npm";
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/share/npm/bin"
  ];

  home.file = {
    ".pi/agent" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/pi";
    };
  };
}
