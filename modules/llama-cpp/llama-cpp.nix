{ inputs, ... }:
{
  flake.nixosModules.llama-cpp =
    { pkgs, ... }:
    let
      # llama-cpp from nixpkgs master via a plain package override (like the
      # original _overlay.nix approach, but using the flake's nixpkgs-master
      # input instead of a vendored package.nix). ROCm is enabled and set as
      # the default backend; Vulkan stays enabled as a fallback.
      # gfx1151: Ryzen 9 9800X3D iGPU (RDNA 3.5); gfx1201: RX 9070 XT (RDNA 4).
      masterPkgs = inputs.nixpkgs-master.legacyPackages."${pkgs.system}";
      llama-cpp = masterPkgs.llama-cpp.override {
        rocmSupport = true;
        rocmGpuTargets = [
          "gfx1151"
          "gfx1201"
        ];
        vulkanSupport = true;
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
        # ROCm (HIP) is the default backend: all model layers and KV cache work
        # goes to the discrete RX 9070 XT (gfx1201), listed by llama.cpp as
        # "ROCm0". rocminfo enumerates gfx1201 as the first GPU agent, and
        # HIP_VISIBLE_DEVICES pins it in case the agent order ever changes.
        HIP_VISIBLE_DEVICES = "0";
        LLAMA_ARG_DEVICE = "ROCm0";
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
      };
    };
}
