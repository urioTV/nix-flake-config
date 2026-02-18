{ ... }:
let
  sharedConfig =
    { ... }:
    {
      sops = {
        defaultSopsFile = ./sops/secrets/secrets.yaml;

        age = {
          sshKeyPaths = [ "/home/urio/.ssh/id_ed25519" ];
          keyFile = "/home/urio/.config/sops/age/keys.txt";
          generateKey = true;
        };

        secrets.openrouter_api_key = { };
        secrets.context7_api_key = { };
        secrets.github_token = { };
      };
    };
in
{
  flake.nixosModules.sops-config =
    {
      pkgs,
      ...
    }:
    {
      imports = [ sharedConfig ];

      # Install sops and age tools for secrets management
      environment.systemPackages = with pkgs; [
        sops
        age
        ssh-to-age
      ];
    };

  flake.homeModules.sops-config =
    {
      ...
    }:
    {
      imports = [ sharedConfig ];
    };
}
