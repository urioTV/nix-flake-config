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
        # Claude Code Family
        "claudecode-opus-4.6" = {
          name = "Claude Opus 4.6 (Claude Code)";
        };
        "claudecode-opus-4.6-fast" = {
          name = "Claude Opus 4.6 Fast (Claude Code)";
        };
        "claudecode-sonnet-4.6" = {
          name = "Claude Sonnet 4.6 (Claude Code)";
        };
        "claudecode-haiku-4.5" = {
          name = "Claude Haiku 4.5 (Claude Code)";
        };
      };
    };
  };
}
