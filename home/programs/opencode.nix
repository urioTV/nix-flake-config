{ config, pkgs, ... }:
let
in
{
  xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON {
    google_auth = false;
    runtime_fallback = {
      enabled = true;
      retry_on_errors = [
        400
        401
        402
        403
        404
        429
        500
        503
        529
      ];
      max_fallback_attempts = 5;
      cooldown_seconds = 60;
      timeout_seconds = 10;
      notify_on_fallback = true;
    };

    agents = {
      # --- Z.ai Coding Plan Agents ---
      sisyphus = {
        model = "zai-coding-plan/glm-5";
        thinking = {
          type = "disabled";
        };
        fallback_models = [
          "github-copilot/claude-sonnet-4.6"
          "openrouter/zhipuai/glm-5"
        ];
      };
      metis = {
        model = "zai-coding-plan/glm-4.7";
        fallback_models = [
          "github-copilot/claude-sonnet-4.6"
          "openrouter/zhipuai/glm-5"
        ];
      };

      # --- Dual-Prompt Agents ---
      prometheus = {
        model = "zai-coding-plan/glm-4.7";
        fallback_models = [
          "github-copilot/claude-sonnet-4.6"
          "openrouter/zhipuai/glm-5"
        ];
      };
      atlas = {
        model = "zai-coding-plan/glm-4.7";
        fallback_models = [
          "github-copilot/claude-sonnet-4.6"
          "openrouter/zhipuai/glm-5"
        ];
      };

      # --- GPT-Native Agents (GPT family only) ---
      hephaestus = {
        model = "openrouter/openai/gpt-5.1-codex-mini";
        fallback_models = [ "github-copilot/gpt-5-mini" ];
      };
      oracle = {
        model = "openrouter/openai/gpt-5.1-codex-mini";
        fallback_models = [ "github-copilot/gpt-5-mini" ];
      };
      momus = {
        model = "openrouter/openai/gpt-5.1-codex-mini";
        fallback_models = [ "github-copilot/gpt-5-mini" ];
      };

      # --- Utility / Subagents (Speed and cost focused) ---
      "sisyphus-junior" = {
        model = "github-copilot/gpt-5-mini";
      };
      explore = {
        model = "github-copilot/gpt-5-mini";
      };
      librarian = {
        model = "github-copilot/gpt-5-mini";
      };
      "multimodal-looker" = {
        model = "github-copilot/gpt-5-mini";
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
        "opencode-gemini-auth@latest"
        "@tarquinen/opencode-dcp@latest"
        "@simonwjackson/opencode-direnv"
        "oh-my-opencode"
      ];
    };
  };
}
