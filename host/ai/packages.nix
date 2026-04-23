{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # AI/LLM Tools
    lmstudio
    gemini-cli
    # (llama-cpp.override { rocmSupport = true; })
    (python3.withPackages (ps: [ ps.huggingface-hub ]))
    (writeShellScriptBin "huggingface-cli" ''
      exec ${python3Packages.huggingface-hub}/bin/hf "$@"
    '')

    (llama-cpp.override {
      vulkanSupport = true;
      rocmSupport = true;
    })
  ];

  # Vulkan dGPU (RX 7900M) for llama-cpp
  # rocmSupport = false: only Vulkan backend, no ROCm conflict
  # LLAMA_ARG_DEVICE: select device for offloading (use --list-devices to verify)
  # LLAMA_ARG_N_GPU_LAYERS: offload all layers to GPU (-1 = auto)
  #   Vulkan0 = AMD Radeon 610M (iGPU), Vulkan1 = AMD Radeon RX 7900M (dGPU)
  environment.sessionVariables = {
    LLAMA_ARG_DEVICE = "Vulkan1";
    LLAMA_ARG_CACHE_TYPE_K = "q8_0";
    LLAMA_ARG_CACHE_TYPE_V = "q8_0";
    LLAMA_ARG_FLASH_ATTN = "1";
    LLAMA_ARG_NO_MMAP = "1";
    LLAMA_ARG_BATCH = "2048";
    LLAMA_ARG_UBATCH = "512";
  };
}
