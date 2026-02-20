{ config, pkgs, ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      ddg-search = {
        command = "bunx";
        args = [ "duckduckgo-mcp-server" ];
      };
      nixos = {
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      };
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        headers = {
          "CONTEXT7_API_KEY" = "{file:${config.sops.secrets.context7_api_key.path}}";
        };
      };
      github = {
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          "Authorization" = "Bearer {file:${config.sops.secrets.github_token.path}}";
        };
      };
    };
  };
}
