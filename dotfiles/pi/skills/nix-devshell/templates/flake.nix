# Szkielet flake.nix dla wielo-profilowego devshella.
# Adaptuj: description, listę imports (jeden plik na profil + default + ci).
# Nie dodawaj tu logiki językowej — profile żyją w nix/devshells/.

{
  description = "Środowisko developerskie <PROJECT>";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    inputs@{ flake-parts, devshell, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Domyślnie wszystkie platformy. Zawężaj tylko, gdy projekt celuje
      # w jedną architekturę (np. ARM-only firmware).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        devshell.flakeModule
        ./nix/devshells/secrets.nix      # opcjonalny ładowacz sekretów (fnox/aws-vault/...)
        ./nix/devshells/toolA.nix        # np. ansible.nix
        ./nix/devshells/toolB.nix        # np. pulumi.nix / node.nix / rust.nix
        ./nix/devshells/tools.nix        # opcjonalne: pakiety pomocnicze / generatory
        ./nix/devshells/ci.nix
        ./nix/devshells/default.nix
      ];
    };
}
