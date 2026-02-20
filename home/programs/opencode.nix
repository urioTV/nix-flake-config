{ config, pkgs, ... }:
{
  # oh-my-opencode config: GitHub Copilot — tiered model routing
  # Premium agents (coder/architect) → claude-sonnet-4.6  (premium, counted request)
  # Utility subagents (explore/summarize) → gpt-4.1        (free 0x multiplier)
  # fallback_models: tried in order when primary model fails (429/503/529)
  xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON {
    google_auth = false; # Disable built-in auth
    agents = {
      # --- Premium Agents: logic generation & file modifications ---

      # Sisyphus: Main orchestrator (Ultraworker)
      sisyphus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Prometheus: Strategic planning consultant
      prometheus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Metis: Plan analysis and review
      metis = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Atlas: Master orchestrator & todo management
      atlas = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Hephaestus: Deep autonomous coding worker
      hephaestus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Oracle: Strategic advisor & architecture/debugging
      oracle = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Momus: Verification, review and QA
      momus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Frontend Engineer: UI/UX implementation
      "frontend-ui-ux-engineer" = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
        ];
      };

      # --- Free 0x Subagents: exploration, summarization & documentation ---

      # Explore: Fast read-only code search (grep/find)
      explore = {
        model = "github-copilot/gpt-4.1";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
        ];
      };
      # Librarian: Documentation and code exploration
      librarian = {
        model = "github-copilot/gpt-4.1";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
        ];
      };
      # Multimodal Looker: Image/Screenshot analysis
      "multimodal-looker" = {
        model = "github-copilot/gpt-4o";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
        ];
      };
      # Document Writer: Documentation writing
      "document-writer" = {
        model = "github-copilot/gpt-4.1";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
        ];
      };
      # General: Multi-step research and parallelizable tasks
      general = {
        model = "github-copilot/gpt-4.1";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
        ];
      };
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      provider = {
        openrouter = {
          options = {
            # baseURL = "https://openrouter.ai/api/v1";
            apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
          };
        };
        nano-gpt = {
          options = {
            apiKey = "{file:${config.sops.secrets.nano-gpt_api_key.path}}";
          };
        };
      };
      plugin = [
        "@tarquinen/opencode-dcp@latest"
        "@simonwjackson/opencode-direnv"
        "oh-my-opencode@latest"
        "opencode-gemini-auth@latest"
      ];
    };
  };
}
