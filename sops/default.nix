{
  pkgs,
  ...
}:
{
  # Install sops and age tools for secrets management
  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  # sops-nix configuration
  sops = {
    # Default secrets file
    defaultSopsFile = ./secrets/secrets.yaml;

    # Use user SSH key for decryption
    age = {
      # Path to user SSH key (will be converted to age)
      sshKeyPaths = [ "/home/urio/.ssh/id_ed25519" ];

      # Age key file - will be generated from SSH key
      keyFile = "/var/lib/sops-nix/key.txt";

      # Automatically generate age key from SSH key
      generateKey = true;
    };

    # Example secrets - uncomment and adjust to your needs
    # secrets = {
    #   "example_secret" = { };
    #   "api_key" = {
    #     owner = "urio";
    #   };
    #   "database_password" = {
    #     mode = "0400";
    #   };
    # };
  };
}
