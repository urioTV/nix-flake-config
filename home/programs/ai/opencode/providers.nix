{ config, pkgs, ... }:
{
  programs.opencode.settings.provider = {
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
        "Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF:Q6_K" = {
          name = "Qwen3.5 9B Claude 4.6 Opus Reasoning Distilled";
        };
      };
    };
    litellm = {
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
  };
}
