{ config, pkgs, ... }:
{
  # oh-my-opencode config: GitHub Copilot — tiered model routing
  # Premium agents/categories → claude-sonnet-4.6  (premium, counted request)
  # Utility subagents/categories → gpt-5-mini       (free 0x multiplier)
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
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Sisyphus-Junior: Subagent executor (spawned via task()) — fast & free
      sisyphus-junior = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
        ];
      };
      # Prometheus: Strategic planning consultant
      prometheus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Metis: Plan analysis and review
      metis = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Atlas: Master orchestrator & todo management
      atlas = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Hephaestus: Deep autonomous coding worker
      hephaestus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Oracle: Strategic advisor & architecture/debugging
      oracle = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Momus: Verification, review and QA
      momus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };

      # --- Free 0x Subagents: exploration, summarization & documentation ---

      # Explore: Fast read-only code search (grep/find)
      explore = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
        ];
      };
      # Librarian: Documentation and code exploration
      librarian = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
        ];
      };
      # Multimodal Looker: Image/Screenshot analysis
      "multimodal-looker" = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
        ];
      };
    };

    categories = {
      # --- Premium categories: complex reasoning & generation (claude-sonnet-4.6) ---

      # Hardest logic-heavy tasks
      ultrabrain = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Autonomous deep problem-solving
      deep = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Creative, unconventional approaches
      artistry = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Frontend / UI / UX implementation
      visual-engineering = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };
      # Heavier unspecified tasks
      unspecified-high = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "github-copilot/gpt-5-mini"
          "openrouter/zhipuai/glm-5"
        ];
      };

      # --- Free 0x categories: simple/trivial tasks (gpt-5-mini) ---

      # Single-file trivial tasks
      quick = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
        ];
      };
      # Light unspecified tasks
      unspecified-low = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
        ];
      };
      # Documentation / prose writing
      writing = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "github-copilot/gpt-4.1"
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
