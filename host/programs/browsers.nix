{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    brave
    zen-browser
    microsoft-edge
  ];

  environment.etc = {
    "brave/policies/managed/brave-debloat.json".text = builtins.toJSON {
      "BraveRewardsDisabled" = true;
      "BraveWalletDisabled" = true;
      "BraveVPNDisabled" = 1;
      "BraveAIChatEnabled" = false;
      "TorDisabled" = true;
      "DnsOverHttpsMode" = "automatic";
      "PreferredOzonePlatform" = "wayland";
    };
  };

  programs = {
    # firefox = {
    #   enable = true;
    #   package = pkgs.librewolf-wayland;
    #   languagePacks = [
    #     "pl"
    #   ];
    #   policies = {
    #     DisableFirefoxAccounts = false;
    #     DisableTelemetry = true;
    #     DisableFirefoxStudies = true;

    #     # Preferences = {
    #     #   "identity.sync.tokenserver.uri" = "https://token.services.mozilla.com/1.0/sync/1.5";
    #     #   "privacy.donottrackheader.enabled" = true;
    #     #   "privacy.fingerprintingProtection" = false;
    #     #   "privacy.resistFingerprinting" = false;
    #     #   "privacy.trackingprotection.emailtracking.enabled" = true;
    #     #   "privacy.trackingprotection.enabled" = true;
    #     #   "privacy.trackingprotection.fingerprinting.enabled" = false;
    #     #   "privacy.trackingprotection.socialtracking.enabled" = true;
    #     # };
    #   };
    # };
  };

}
