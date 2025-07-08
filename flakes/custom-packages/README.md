# Custom Packages Flake

This flake contains custom Nix packages for the nix-flake-config repository.

## Structure

```
flakes/custom-packages/
├── flake.nix              # Main flake definition with overlay
├── flake.lock             # Lock file with pinned dependencies
├── scopebuddy/            # ScopeBuddy package
│   └── default.nix
├── vintagestory/          # Vintage Story package
│   └── default.nix
└── README.md              # This file
```

## Packages

### ScopeBuddy
- **Description**: A manager script to make gamescope easier to use on desktop
- **Homepage**: https://github.com/HikariKnight/ScopeBuddy
- **License**: Apache 2.0
- **Version**: unstable (tracks upstream)

### Vintage Story
- **Description**: In-development indie sandbox game about innovation and exploration
- **Homepage**: https://www.vintagestory.at/
- **License**: Unfree
- **Version**: 1.20.10

## Usage

### As a standalone flake

```bash
# Build packages
nix build .#scopebuddy
nix build .#vintagestory

# Run packages
nix run .#scopebuddy
nix run .#vintagestory
```

### Using the overlay

The flake exports an overlay that can be used in other flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    custom-packages.url = "path:./flakes/custom-packages";
  };

  outputs = { nixpkgs, custom-packages, ... }: {
    nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            custom-packages.overlays.default
          ];
          
          # Now you can use the packages
          environment.systemPackages = with pkgs; [
            scopebuddy
            vintagestory
          ];
        }
      ];
    };
  };
}
```

## Configuration

The flake includes necessary configuration for:
- `allowUnfree = true` for Vintage Story
- `permittedInsecurePackages` for dotnet-runtime-7.0.20 (required by Vintage Story)

## Adding New Packages

To add a new custom package:

1. Create a new directory under `flakes/custom-packages/`
2. Add a `default.nix` file with the package definition
3. Update the `packages` attribute in `flake.nix`
4. Update the overlay to include the new package
5. Run `nix flake lock` to update the lock file

Example structure:
```
flakes/custom-packages/
├── my-new-package/
│   └── default.nix
└── flake.nix              # Add package here
```

## Dependencies

This flake depends on:
- nixpkgs (follows parent flake)
- flake-utils (for multi-system support)
- scopebuddy source (GitHub input)