{ config, pkgs, ... }:
{
  # oh-my-opencode config: GitHub Copilot — tiered model routing
  # Agents inherit model/fallback from their assigned category.
  # Premium categories → claude-sonnet-4.6  (premium, counted request)
  # Free    categories → gpt-5-mini         (free 0x multiplier)
  xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON {
    google_auth = false;

    agents = {
      # --- Premium agents: inherit from unspecified-high ---
      sisyphus = {
        category = "unspecified-high";
      };
      prometheus = {
        category = "unspecified-high";
      };
      metis = {
        category = "unspecified-high";
      };
      atlas = {
        category = "unspecified-high";
      };
      hephaestus = {
        category = "unspecified-high";
      };
      oracle = {
        category = "unspecified-high";
      };
      momus = {
        category = "unspecified-high";
      };

      # --- Free 0x subagents: inherit from quick ---
      sisyphus-junior = {
        category = "quick";
      };
      explore = {
        category = "quick";
      };
      librarian = {
        category = "quick";
      };
      "multimodal-looker" = {
        category = "quick";
      };
    };

    categories = {
      # --- Premium categories: complex reasoning & generation ---

      # Hardest logic-heavy tasks
      ultrabrain = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
          "github-copilot/gpt-5-mini"
        ];
      };
      # Autonomous deep problem-solving
      deep = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
          "github-copilot/gpt-5-mini"
        ];
      };
      # Creative, unconventional approaches
      artistry = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
          "github-copilot/gpt-5-mini"
        ];
      };
      # Frontend / UI / UX implementation
      "visual-engineering" = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
          "github-copilot/gpt-5-mini"
        ];
      };
      # Heavier unspecified tasks (default for premium agents)
      "unspecified-high" = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "google/gemini-3.1-pro"
          "openrouter/zhipuai/glm-5"
          "github-copilot/gpt-5-mini"
        ];
      };

      # --- Free 0x categories: simple/trivial tasks ---

      # Single-file trivial tasks (default for free subagents)
      quick = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
          "github-copilot/gpt-4.1"
        ];
      };
      # Light unspecified tasks
      "unspecified-low" = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
          "github-copilot/gpt-4.1"
        ];
      };
      # Documentation / prose writing
      writing = {
        model = "github-copilot/gpt-5-mini";
        fallback_models = [
          "google/gemini-3.0-flash"
          "openrouter/meta-llama/llama-3.1-8b-instruct"
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
