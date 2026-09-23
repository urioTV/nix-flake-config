{
  inputs,
  ...
}:
{
  flake.homeModules.ai-claude-code =
    {
      config,
      pkgs,
      inputs',
      lib,
      self,
      ...
    }:
    {
      programs.claude-code = {
        enable = true;
        package = pkgs.llm-agents.claude-code;
        # Reuse the shared Home Manager MCP registry from modules/ai/_ai.nix.
        # Home Manager exposes these servers to Claude Code through a generated
        # plugin, while Pi reads the same server definitions from programs.mcp.
        enableMcpIntegration = true;
      };

    };

  flake.homeModules.ai =
    {
      config,
      pkgs,
      inputs',
      lib,
      self,
      ...
    }:
    {
      imports = [
        ./_ai.nix
        self.homeModules.ai-claude-code
        self.homeModules.ai-pi
      ];
    };
}
