{ config, pkgs, ... }:
let
  # ── Edit models here ─────────────────────────────────────────────────
  premiumModel = "github-copilot/claude-sonnet-4.6";
  premiumFallbacks = [
    "google/gemini-3.1-pro"
    "openrouter/zhipuai/glm-5"
    "github-copilot/gpt-5-mini"
  ];

  freeModel = "github-copilot/gpt-5-mini";
  freeFallbacks = [
    "google/gemini-3.0-flash"
    "openrouter/meta-llama/llama-3.1-8b-instruct"
    "github-copilot/gpt-4.1"
  ];
  # ─────────────────────────────────────────────────────────────────────
in
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

      # Heavier unspecified tasks (default for premium agents)
      "unspecified-high" = {
        model = premiumModel;
        fallback_models = premiumFallbacks;
      };
      # Hardest logic-heavy tasks
      ultrabrain = {
        model = premiumModel;
        fallback_models = premiumFallbacks;
      };
      # Autonomous deep problem-solving
      deep = {
        model = premiumModel;
        fallback_models = premiumFallbacks;
      };
      # Creative, unconventional approaches
      artistry = {
        model = premiumModel;
        fallback_models = premiumFallbacks;
      };
      # Frontend / UI / UX implementation
      "visual-engineering" = {
        model = premiumModel;
        fallback_models = premiumFallbacks;
      };

      # --- Free 0x categories: simple/trivial tasks ---

      # Single-file trivial tasks (default for free subagents)
      quick = {
        model = freeModel;
        fallback_models = freeFallbacks;
      };
      # Light unspecified tasks
      "unspecified-low" = {
        model = freeModel;
        fallback_models = freeFallbacks;
      };
      # Documentation / prose writing
      writing = {
        model = freeModel;
        fallback_models = freeFallbacks;
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
