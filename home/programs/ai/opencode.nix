{ config, pkgs, ... }:
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
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "zai-coding-plan/glm-5"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
          "openrouter/zhipuai/glm-5"
        ];
      };
      metis = {
        model = "google/gemini-3.1-pro-preview";
        fallback_models = [
          "github-copilot/claude-sonnet-4.6"
          "zai-coding-plan/glm-5"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
        ];
      };

      # --- Dual-Prompt Agents ---
      prometheus = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "zai-coding-plan/glm-5"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
          "openrouter/zhipuai/glm-5"
        ];
      };
      atlas = {
        model = "github-copilot/claude-sonnet-4.6";
        fallback_models = [
          "zai-coding-plan/glm-5"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
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
          models = {
            "qwen3.5-35b-a3b" = {
              name = "Qwen3.5 35B";
            };
            "qwen3.5-35b-a3b:thinking" = {
              name = "Qwen3.5 35B Thinking";
            };
            "qwen3.5-122b-a10b" = {
              name = "Qwen3.5 122B";
            };
            "qwen3.5-122b-a10b:thinking" = {
              name = "Qwen3.5 122B Thinking";
            };
          };
          options = {
            apiKey = "{file:${config.sops.secrets.nano-gpt_api_key.path}}";
          };
        };
        ramalama = {
          npm = "@ai-sdk/openai-compatible";
          name = "RamaLama (Local)";
          options = {
            baseURL = "http://127.0.0.1:8080/v1";
            apiKey = "";
          };
          models = {
            "unsloth/GLM-4.6V-Flash-GGUF:Q6_K" = {
              name = "GLM-4.6V Flash";
            };
            "TeichAI/Qwen3-14B-Claude-4.5-Opus-High-Reasoning-Distill-GGUF:Q4_K_M" = {
              name = "Qwen3-14B Claude 4.5 Opus Distill";
            };
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
