{ config, pkgs, ... }:
{
  # oh-my-opencode config: Force Gemini 3 for all agents
  xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON {
    google_auth = false; # Disable built-in auth
    agents = {
      # --- High Intelligence Agents (Gemini 3 Pro) ---
      # Sisyphus: Main agent (Ultraworker)
      sisyphus = {
        model = "google/gemini-3-pro-preview";
      };
      # Prometheus: Strategic planning
      prometheus = {
        model = "google/gemini-3-pro-preview";
      };
      # Metis: Plan review
      metis = {
        model = "google/gemini-3-pro-preview";
      };
      # Atlas: Task management (Todo)
      atlas = {
        model = "google/gemini-3-pro-preview";
      };
      # Hephaestus: Deep autonomous work
      hephaestus = {
        model = "google/gemini-3-pro-preview";
      };
      # Oracle: Architecture and debugging
      oracle = {
        model = "google/gemini-3-pro-preview";
      };
      # Momus: Verification and review
      momus = {
        model = "google/gemini-3-pro-preview";
      };
      # Frontend Engineer
      "frontend-ui-ux-engineer" = {
        model = "google/gemini-3-pro-preview";
      };

      # --- Fast / Utility Agents (Gemini 3 Flash) ---
      # Explore: Code search (grep)
      explore = {
        model = "google/gemini-3-flash-preview";
      };
      # Librarian: Documentation search
      librarian = {
        model = "google/gemini-3-flash-preview";
      };
      # Multimodal Looker: Image/Screenshot analysis
      "multimodal-looker" = {
        model = "google/gemini-3-flash-preview";
      };
      # Document Writer: Documentation writing
      "document-writer" = {
        model = "google/gemini-3-flash-preview";
      };
    };
  };

  programs = {
    mcp = {
      enable = true;
      servers = {
        ddg-search = {
          command = "bunx";
          args = [ "duckduckgo-mcp-server" ];
        };
        nixos = {
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        };
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          headers = {
            "CONTEXT7_API_KEY" = "{file:${config.sops.secrets.context7_api_key.path}}";
          };
        };
        github = {
          type = "remote";
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            "Authorization" = "Bearer {file:${config.sops.secrets.github_token.path}}";
          };
        };
      };
    };
    opencode = {
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
        };
        plugin = [
          "@simonwjackson/opencode-direnv"
          "oh-my-opencode@latest"
          "opencode-gemini-auth@latest"
        ];
      };
    };
  };
}
