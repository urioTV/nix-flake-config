{ inputs, system }:

final: prev: {
  # A manager script for gamescope
  scopebuddy = prev.callPackage ./scopebuddy { inherit inputs; };

  # Vintage Story game
  vintagestory = prev.callPackage ./vintagestory { };

  # CyberGRUB-2077
  cybergrub2077 = prev.callPackage ./cybergrub2077 { };

  # WowUp-CF
  wowup-cf = prev.callPackage ./wowup-cf { };
}
