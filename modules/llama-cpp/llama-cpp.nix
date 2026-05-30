{ inputs, ... }:
let
  sharedConfig =
    { inputs', ... }:
    {
      nixpkgs.overlays = [
        (import ./_overlay.nix { inherit inputs'; })
      ];
    };
in
{
  flake.nixosModules.llama-cpp =
    { pkgs, inputs', ... }:
    let
      llamaCppZshCompletions =
        pkgs.runCommand "llama-cpp-zsh-completions" { nativeBuildInputs = [ pkgs.llama-cpp ]; }
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
      imports = [ (sharedConfig { inherit inputs'; }) ];

      environment.systemPackages = with pkgs; [
        llama-cpp
        llamaCppZshCompletions
      ];

      # konrad-m18 hardware assumptions:
      # - CPU: Ryzen 9 7945HX, 16C/32T Zen 4 with AVX-512.
      # - Vulkan0: AMD Radeon 610M iGPU.
      # - Vulkan1: AMD Radeon RX 7900M (Navi 31) dGPU via RADV.
      # We use Vulkan rather than ROCm for llama.cpp because it gives explicit
      # device selection and avoids ROCm/HIP package conflicts for this setup.
      environment.sessionVariables = {
        # Force all model layers and KV cache work onto the RX 7900M.
        LLAMA_ARG_DEVICE = "Vulkan1";
        LLAMA_ARG_SPLIT_MODE = "none";
        LLAMA_ARG_N_GPU_LAYERS = "-1";

        # KV cache quantization saves VRAM and allows larger contexts while
        # keeping quality/performance balance good for local coding models.
        LLAMA_ARG_CACHE_TYPE_K = "q8_0";
        LLAMA_ARG_CACHE_TYPE_V = "q8_0";

        # Larger prompt batches are efficient on the 7900M; ubatch stays smaller
        # to limit transient VRAM pressure and latency spikes.
        LLAMA_ARG_BATCH = "4096";
        LLAMA_ARG_UBATCH = "1024";

        # CPU threads: use physical cores for token generation, all SMT threads
        # for prompt/batch preprocessing.
        LLAMA_ARG_THREADS = "16";
        LLAMA_ARG_THREADS_BATCH = "32";

        LLAMA_ARG_FLASH_ATTN = "1";
        LLAMA_ARG_NO_MMAP = "1";

        # Vulkan backend: request VRAM memory priority when RADV exposes
        # VK_EXT_memory_priority; leave host-memory/sysmem fallback disabled for
        # best performance on the discrete GPU.
        GGML_VK_ENABLE_MEMORY_PRIORITY = "1";
      };
    };
}
