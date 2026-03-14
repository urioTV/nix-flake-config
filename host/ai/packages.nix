{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # AI/LLM Tools
    lmstudio
    gemini-cli
    ramalama
    (llama-cpp.override { rocmSupport = true; })
    (python3.withPackages (ps: [ ps.huggingface-hub ]))
    (writeShellScriptBin "huggingface-cli" ''
      exec ${python3Packages.huggingface-hub}/bin/hf "$@"
    '')

    (pkgs.writeShellScriptBin "ramalama-optimized" ''
      # Ukrycie układu zintegrowanego (Radeon 610M) dla stabilności wnioskowania ROCm
      export HIP_VISIBLE_DEVICES=0

      # Optymalizacje parametrów prefill dla llama.cpp
      export LLAMA_ARG_FLASH_ATTN=true
      export LLAMA_ARG_BATCH=4096
      export LLAMA_ARG_UBATCH=4096
      export LLAMA_ARG_CACHE_TYPE_K=q8_0
      export LLAMA_ARG_CACHE_TYPE_V=q8_0

      # Przekazanie procesu z flagą omijającą konteneryzację OCI
      exec ramalama --nocontainer "$@"
    '')
  ];
}
