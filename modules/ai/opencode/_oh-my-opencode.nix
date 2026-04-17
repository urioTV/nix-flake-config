{ config, pkgs, ... }:
{
  xdg.configFile."opencode/oh-my-opencode-slim.json".text = builtins.toJSON {
    fallback = {
      enabled = true;
      chains = {
        orchestrator = [
          "opencode-go/glm-5.1"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
          "litellm/antigravity-gemini-3.1-pro-high"
        ];
        oracle = [
          "opencode-go/kimi-k2.5"
          "litellm/antigravity-gemini-3.1-pro-high"
        ];
        designer = [
          "opencode-go/kimi-k2.5"
          "litellm/antigravity-gemini-3.1-pro-high"
        ];
        fixer = [
          "opencode-go/minimax-m2.7"
          "github-copilot/gpt-5-mini"
          "openrouter/x-ai/grok-4.1-fast"
        ];
      };
    };

    agents = {
      orchestrator = {
        model = "opencode-go/glm-5.1";
      };
      oracle = {
        model = "opencode-go/kimi-k2.5";
      };
      explorer = {
        model = "opencode-go/minimax-m2.7";
      };
      librarian = {
        model = "opencode-go/minimax-m2.7";
      };
      designer = {
        model = "opencode-go/kimi-k2.5";
      };
      fixer = {
        model = "opencode-go/minimax-m2.7";
      };
    };
  };
}
