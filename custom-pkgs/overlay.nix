{ inputs, system }:

final: prev: {
  # A manager script for gamescope
  scopebuddy = prev.callPackage ./scopebuddy { inherit inputs; };

  # Vintage Story game
  vintagestory = prev.callPackage ./vintagestory { };
}
