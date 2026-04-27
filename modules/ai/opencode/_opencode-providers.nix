{ config, pkgs, ... }:
{
  programs.opencode.settings.provider = {
    openrouter = {
      options = {
        # baseURL = "https://openrouter.ai/api/v1";
        apiKey = "{file:${config.sops.secrets.openrouter_api_key.path}}";
      };
    };
    llama-swap = {
      npm = "@ai-sdk/openai-compatible";
      name = "llama-swap (local)";
      options = {
        baseURL = "http://localhost:8080/v1";
      };
      models = {
        "omnicoder-9b" = {
          name = "Omnicoder 9B";
          limit = {
            context = 160000;
            output = 16384;
          };
        };
      };
    };
  };
}
