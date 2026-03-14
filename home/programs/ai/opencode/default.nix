{ config, pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      plugin = [
        "opencode-gemini-auth@latest"
        "@tarquinen/opencode-dcp@latest"
        "@simonwjackson/opencode-direnv"
        "oh-my-opencode-slim@latest"
      ];
    };
  };
}
