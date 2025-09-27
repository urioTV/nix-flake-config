{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # AI/LLM Tools
    lmstudio
    gemini-cli
  ];
}
