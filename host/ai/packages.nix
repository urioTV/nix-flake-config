{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      # AI/LLM Tools
      lmstudio
      gemini-cli
      # huggingface-hub from nixpkgs master — newer than nixos-unstable
      # (1.26.0 vs 1.16.0). The withPackages env provides the `hf`,
      # `huggingface-cli` and `tiny-agents` entry points AND makes
      # `huggingface_hub` importable from the system Python, so no separate
      # wrapper or standalone package is needed.
      (inputs.nixpkgs-master.legacyPackages."${pkgs.system}".python3.withPackages (ps: [
        ps.huggingface-hub
      ]))
    ];
}
