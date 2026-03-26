{ config, pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
}
