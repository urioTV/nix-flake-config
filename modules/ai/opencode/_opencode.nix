{
  config,
  pkgs,
  inputs',
  ...
}:
{
  imports = [
    ./_opencode-providers.nix
    ./skills/_skills-import.nix
    ./_oh-my-opencode.nix
  ];

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      model = "opencode-go/glm-5.1";
      plugin = [
        "opencode-gemini-auth@latest"
        # "opencode-lmstudio@latest"
        "@tarquinen/opencode-dcp@latest"
        "@simonwjackson/opencode-direnv"
        "oh-my-opencode-slim@latest"
      ];
    };
  };
}
