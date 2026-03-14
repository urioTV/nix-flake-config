{ config, pkgs, ... }:
let
  litellmProvider = {
    npm = "@ai-sdk/openai-compatible";
    name = "LiteLLM Proxy";
    options = {
      baseURL = "https://litellm.urio.dev/v1";
      apiKey = "{file:${config.sops.secrets.litellm_api_key.path}}";
    };
    models = {
      # Gemini Family (via Google)
      "gemini-3.1-pro-preview" = {
        name = "Gemini 3.1 Pro Preview";
      };
      "gemini-3-flash-preview" = {
        name = "Gemini 3 Flash Preview";
      };

      # Antigravity Family
      "antigravity-claude-opus-4-6-thinking" = {
        name = "Claude Opus 4.6 Thinking (Antigravity)";
      };
      "antigravity-claude-sonnet-4-6" = {
        name = "Claude Sonnet 4.6 (Antigravity)";
      };
      "antigravity-gemini-3-flash" = {
        name = "Gemini 3 Flash (Antigravity)";
      };
      "antigravity-gemini-3.1-pro-high" = {
        name = "Gemini 3.1 Pro High (Antigravity)";
      };
      "antigravity-gemini-3.1-pro-low" = {
        name = "Gemini 3.1 Pro Low (Antigravity)";
      };
    };
  };
  commonModels = {
    model = "zai-coding-plan/glm-5";
    fallback_models = [
      "github-copilot/claude-sonnet-4.6"
      "nano-gpt/qwen3.5-122b-a10b:thinking"
      "openrouter/zhipuai/glm-5"
    ];
  };

  gptModels = {
    model = "openrouter/openai/gpt-5.1-codex-mini";
    fallback_models = [ "github-copilot/gpt-5-mini" ];
  };

  miniModels = {
    model = "github-copilot/gpt-5-mini";
  };
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
      sisyphus = commonModels;
      metis = {
        model = "google/gemini-3.1-pro-preview";
        fallback_models = [
          "github-copilot/claude-sonnet-4.6"
          "zai-coding-plan/glm-5"
          "nano-gpt/qwen3.5-122b-a10b:thinking"
        ];
      };

      # --- Dual-Prompt Agents ---
      prometheus = commonModels;
      atlas = commonModels;

      # --- GPT-Native Agents (GPT family only) ---
      hephaestus = gptModels;
      oracle = gptModels;
      momus = gptModels;

      # --- Utility / Subagents (Speed and cost focused) ---
      "sisyphus-junior" = miniModels;
      explore = miniModels;
      librarian = miniModels;
      "multimodal-looker" = miniModels;
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
        litellm = litellmProvider;
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
