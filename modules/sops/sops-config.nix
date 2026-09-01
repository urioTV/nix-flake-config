{ inputs, self, ... }:
let
  sharedConfig =
    { ... }:
    {
      sops = {
        defaultSopsFile = "${self}/sops/secrets/secrets.yaml";

        secrets.openrouter_api_key = { };
        secrets.context7_api_key = { };
        secrets.github_token = { };
        secrets.nano-gpt_api_key = { };
        secrets.z-ai_api_key = { };
        secrets.litellm_api_key = { };
        secrets.netbird_authkey = { };
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
      sops = {
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        useSystemdActivation = true;
      };

      imports = [
        inputs.sops-nix.nixosModules.sops
        sharedConfig
      ];

      environment.systemPackages = with pkgs; [
        sops
        age
        ssh-to-age
      ];
    };

  flake.homeModules.sops-config =
    { config, ... }:
    {
      imports = [
        inputs.sops-nix.homeManagerModules.sops
        sharedConfig
      ];

      sops.age = {
        sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
        keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
        generateKey = true;
      };
    };
}
