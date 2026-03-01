{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # AI/LLM Tools
    lmstudio
    gemini-cli
    ramalama
    (python3.withPackages (ps: [ ps.huggingface-hub ]))
    (writeShellScriptBin "huggingface-cli" ''
      exec ${python3Packages.huggingface-hub}/bin/hf "$@"
    '')
  ];
}
