{ inputs, ... }:
{
  flake.nixosModules.llama-cpp =
    { pkgs, ... }:
    let
      # llama-cpp from nixpkgs master — newer than nixos-unstable and avoids the
      # hand-maintained upstream pin / npmDepsHash / cmakeFlags we previously
      # carried in _overlay.nix. Vulkan-only build matches the RX 9070 XT.
      # master's `cpuArchDynamicDispatch` builds all CPU variants and dispatches
      # at runtime, so native -march=znver5 tuning is no longer required to get
      # full AVX-512 performance on the Ryzen 7 9800X3D.
      masterPkgs = inputs.nixpkgs-master.legacyPackages."${pkgs.system}";
      llama-cpp = masterPkgs.llama-cpp.override {
        vulkanSupport = true;
        rocmSupport = false;
        cudaSupport = false;
        openclSupport = false;
        rpcSupport = false;
      };

      llamaCppZshCompletions =
        pkgs.runCommand "llama-cpp-zsh-completions" { nativeBuildInputs = [ llama-cpp ]; }
          ''
            mkdir -p "$out/share/bash-completion/completions" "$out/share/zsh/site-functions"
            llama-cli --completion-bash > "$out/share/bash-completion/completions/llama-cpp" 2>/dev/null

            touch "$out/share/zsh/site-functions/_llama-cpp"
            printf '%s\n' \
              '#compdef llama-cli llama-server' \
              "" \
              '# Generated from llama.cpp bash completion during the Nix build.' \
              '# bashcompinit adapts the generated bash completion to zsh, avoiding any' \
              '# hand-maintained option lists or per-flag completion rules here.' \
              'autoload -Uz bashcompinit' \
              'bashcompinit' \
              "source \"$out/share/bash-completion/completions/llama-cpp\"" \
              '_bash_complete -F _llama_completions "$@"' \
              > "$out/share/zsh/site-functions/_llama-cpp"
          '';
    in
    {
      environment.systemPackages = [
        llama-cpp
        llamaCppZshCompletions
      ];
      environment.sessionVariables = {
        # Force all model layers and KV cache work onto the discrete RX 9070 XT.
        LLAMA_ARG_DEVICE = "Vulkan0";
        # LLAMA_ARG_SPLIT_MODE = "none";
        # LLAMA_ARG_N_GPU_LAYERS = "-1";

        LLAMA_ARG_CACHE_TYPE_K = "q8_0";
        LLAMA_ARG_CACHE_TYPE_V = "q8_0";

        LLAMA_ARG_BATCH = "8192";
        LLAMA_ARG_UBATCH = "512";

        LLAMA_ARG_THREADS = "16";
        LLAMA_ARG_THREADS_BATCH = "16";

        LLAMA_ARG_FLASH_ATTN = "1";
        LLAMA_ARG_NO_MMAP = "1";

        # Vulkan backend: request VRAM memory priority when RADV exposes
        # VK_EXT_memory_priority; leave host-memory/sysmem fallback disabled for
        # best performance on the discrete GPU.
        GGML_VK_ENABLE_MEMORY_PRIORITY = "1";
      };
    };
}
