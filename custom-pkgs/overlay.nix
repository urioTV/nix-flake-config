{ inputs, system }:

final: prev: {
  # A manager script for gamescope
  scopebuddy = prev.callPackage ./scopebuddy { inherit inputs; };

  # A Vulkan layer for frame generation
  lsfg-vk = prev.callPackage ./lsfg-vk { };

  # Vintage Story game
  vintagestory = prev.callPackage ./vintagestory { };
}
