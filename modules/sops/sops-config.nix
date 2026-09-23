{ inputs, self, ... }:
let
  # sops-nix @ 13616ff builds sops-install-secrets with buildGo125Module,
  # which was removed from nixpkgs 2026-09-15 (Go 1.25 EOL). Inject the
  # current builder via callPackage until upstream moves to buildGo126Module.
  sopsInstallSecrets =
    pkgs:
    pkgs.callPackage "${inputs.sops-nix}/pkgs/sops-install-secrets" {
      buildGo125Module = pkgs.buildGo126Module;
      vendorHash = "sha256-SXOd+0yh0DQr3uLVQBdw07J9j5HNuFJSOajDul1B1qo="; # from sops-nix default.nix
    };

  sharedConfig =
    { pkgs, ... }:
    {
      sops = {
        package = sopsInstallSecrets pkgs;
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
