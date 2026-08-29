{
  flake.homeModules.llama-cpp =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      # llama-cpp straight from nixpkgs (unstable), so the ROCm stack comes
      # from the same tree and stays binary-cache friendly. ROCm is enabled and
      # set as the default backend; Vulkan stays enabled as a fallback.
      # gfx1151: Ryzen 9 9800X3D iGPU (RDNA 3.5); gfx1201: RX 9070 XT (RDNA 4).
      # Only gfx1201 is compiled: models run exclusively on the RX 9070 XT
      # (HIP_VISIBLE_DEVICES=0), and each HIP target adds significant HIP
      # compile time. Vulkan stays enabled as a fallback backend.
      llama-cpp =
        (pkgs.llama-cpp.override {
          rocmSupport = true;
          rocmGpuTargets = [ "gfx1201" ];
          vulkanSupport = true;
          cudaSupport = false;
          openclSupport = false;
          rpcSupport = false;
          cpuArchDynamicDispatch = false;
        }).overrideAttrs
          (old: {
            # Single CPU variant tuned for this machine (Zen 5, 9800X3D) instead of
            # ~10 dynamically-dispatched GGML variants: shorter build, max CPU perf.
            # Machine-specific by design (this config targets exactly this host).
            # Nix normally strips -march=native to preserve reproducibility. This
            # derivation intentionally opts out and must therefore build locally.
            NIX_ENFORCE_NO_NATIVE = false;
            preferLocalBuild = true;
            allowSubstitutes = false;

            cmakeFlags =
              builtins.filter (flag: !(lib.hasPrefix "-DGGML_NATIVE" flag)) (old.cmakeFlags or [ ])
              ++ [ "-DGGML_NATIVE:BOOL=ON" ];
          });

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
      home.packages = [
        llama-cpp
        llamaCppZshCompletions
      ];

      home.sessionVariables = {
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

        # LLAMA_ARG_BATCH = "8192";
        # LLAMA_ARG_UBATCH = "512";

        LLAMA_ARG_THREADS = "16";
        LLAMA_ARG_THREADS_BATCH = "16";

        LLAMA_ARG_FLASH_ATTN = "1";
        LLAMA_ARG_NO_MMAP = "1";

        # Enable llama-server router mode and load model presets managed from
        # dotfiles/llama-cpp/models.ini.
        LLAMA_ARG_MODELS_PRESET = "${config.home.homeDirectory}/.config/llama.cpp/models.ini";
      };

      home.file.".config/llama.cpp/models.ini".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-flake-config/dotfiles/llama-cpp/models.ini";
    };
}
