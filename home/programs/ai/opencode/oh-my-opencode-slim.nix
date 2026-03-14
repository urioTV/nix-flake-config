{ config, pkgs, ... }:
{
  xdg.configFile."opencode/oh-my-opencode-slim.json".text = builtins.toJSON {
    fallback = {
      enabled = true;
      chains = {
        orchestrator = [
          "github-copilot/claude-sonnet-4.6"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
          "litellm/antigravity-gemini-3.1-pro-high"
        ];
        oracle = [
          "litellm/antigravity-gemini-3.1-pro-high"
        ];
        designer = [
          "litellm/antigravity-gemini-3.1-pro-high"
        ];
        fixer = [
          "openrouter/x-ai/grok-4.1-fast"
          "github-copilot/gpt-5-mini"
        ];
      };
    };

    agents = {
      orchestrator = {
        model = "zai-coding-plan/glm-5";
      };
      oracle = {
        model = "google/gemini-3.1-pro-preview";
      };
      explorer = {
        model = "github-copilot/gpt-5-mini";
      };
      librarian = {
        model = "github-copilot/gpt-5-mini";
      };
      designer = {
        model = "google/gemini-3.1-pro-preview";
      };
      fixer = {
        model = "nano-gpt/qwen3.5-122b-a10b";
      };
    };
  };
}
