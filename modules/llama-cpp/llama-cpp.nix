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
      environment.sessionVariables = {
        # Force all model layers and KV cache work onto the RX 7900M.
        LLAMA_ARG_DEVICE = "Vulkan1";
        # LLAMA_ARG_SPLIT_MODE = "none";
        # LLAMA_ARG_N_GPU_LAYERS = "-1";

        LLAMA_ARG_CACHE_TYPE_K = "q8_0";
        LLAMA_ARG_CACHE_TYPE_V = "q8_0";

        LLAMA_ARG_BATCH = "8192";
        LLAMA_ARG_UBATCH = "512";

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
