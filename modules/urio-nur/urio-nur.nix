{ inputs, ... }:
let
  overlay = inputs.urio-nur.overlays.default;
in
{
  flake.nixosModules.urio-nur =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ overlay ];

      home-manager.sharedModules = [
        { nixpkgs.overlays = [ overlay ]; }
      ];

      environment.systemPackages = with pkgs; [
        scopebuddy
        wowup-cf
        optiscaler-install
        optipatcher-install
        optiscaler-client
        rimsort-appimage
        vs-launcher
        nmssaveeditor
      ];
    };
}
