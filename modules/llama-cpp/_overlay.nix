{ inputs' }:
final: prev:
let
  # Pinned close to the current nixpkgs expression so the Linux/Vulkan build stays
  # compatible with nixpkgs' llama-cpp package recipe and shader generation.
  llama-cpp-src = final.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "0dbfa66a1fb99e5270b8b6652f553c1bff59123f";
    hash = "sha256-DA8c9lPmvxSVCI75sEaEE+zBLzyg79PVopUl1ouL4Wc=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  llama-cpp-vulkan = prev.llama-cpp.override {
    vulkanSupport = true;
    rocmSupport = false;
    cudaSupport = false;
    openclSupport = false;
    rpcSupport = false;
  };

  appendFlags = oldFlags: newFlags: (oldFlags) ++ newFlags;
  filterCmakeFlags =
    managedFlags: flags:
    builtins.filter (
      f:
      let
        flag = if builtins.isString f then f else "";
      in
      !(builtins.any (name: final.lib.hasPrefix "-D${name}" flag) managedFlags)
    ) flags;
in
{
  llama-cpp = llama-cpp-vulkan.overrideAttrs (old: {
    version = "b9509-unstable-2026-06-04";
    src = llama-cpp-src;

    # Keep this in the module because it belongs to the pinned upstream src.
    npmRoot = "tools/ui";
    npmDepsHash = "sha256-1iM0LGeI9e+gZEHk46lkBe51DxIhiimfAm9o3Z3m9Ik=";

    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.perl ];

    postPatch = (old.postPatch or "") + ''
      # The b9412 Vulkan shader generator fans out to up to 16 glslc processes.
      # In the Nix sandbox on this host that can hit process limits and leave
      # shader symbols undefined at link time. Compile shaders serially; the
      # rest of the package still builds with Ninja parallelism.
      substituteInPlace ggml/src/ggml-vulkan/vulkan-shaders/vulkan-shaders-gen.cpp \
        --replace-fail "std::min(16u, std::thread::hardware_concurrency())" \
                       "1u"

      # The RX 7900M path does not benefit from NVIDIA-only coopmat2, and KHR
      # coopmat shader generation is currently too memory-heavy in this Nix
      # sandbox. Disable both so the Vulkan build emits the portable AMD paths.
      perl -0pi -e 's|function\(test_shader_extension_support EXTENSION_NAME TEST_SHADER_FILE RESULT_VARIABLE\)\n|function(test_shader_extension_support EXTENSION_NAME TEST_SHADER_FILE RESULT_VARIABLE)\n    if (EXTENSION_NAME MATCHES "GL_KHR_cooperative_matrix\|GL_NV_cooperative_matrix2\|GL_NV_cooperative_matrix_decode_vector")\n        message(STATUS "\''${EXTENSION_NAME} disabled for RX 7900M-focused build")\n        set(\''${RESULT_VARIABLE} OFF PARENT_SCOPE)\n        return()\n    endif()\n|' ggml/src/ggml-vulkan/CMakeLists.txt
    '';

    # Host-specific maximum-performance build for konrad-m18:
    # Ryzen 9 7945HX = Zen 4 with AVX-512; RX 7900M is handled by Vulkan.
    # This intentionally trades generic binary portability for local speed.
    NIX_CFLAGS_COMPILE = appendFlags (old.NIX_CFLAGS_COMPILE or [ ]) [
      "-O3"
      "-march=znver4"
      "-mtune=znver4"
      "-fomit-frame-pointer"
    ];

    cmakeFlags =
      filterCmakeFlags [
        "CMAKE_BUILD_TYPE"
        "GGML_NATIVE"
        "GGML_CPU_REPACK"
        "GGML_VULKAN_CHECK_RESULTS"
        "GGML_VULKAN_DEBUG"
        "GGML_VULKAN_MEMORY_DEBUG"
        "GGML_VULKAN_SHADER_DEBUG_INFO"
        "GGML_VULKAN_VALIDATE"
        "LLAMA_BUILD_NUMBER"
      ] old.cmakeFlags
      ++ [
        "-DCMAKE_BUILD_TYPE:STRING=Release"
        # Let ggml enable every CPU path available on this exact CPU
        # (AVX2/AVX512/VNNI/BF16/FMA). The explicit znver4 flags above make the
        # target stable even if GCC changes `-march=native` detection details.
        "-DGGML_NATIVE:BOOL=ON"
        "-DGGML_CPU_REPACK:BOOL=ON"

        # Keep Vulkan fast paths clean: no validation/debug checks in runtime.
        "-DGGML_VULKAN_CHECK_RESULTS:BOOL=OFF"
        "-DGGML_VULKAN_DEBUG:BOOL=OFF"
        "-DGGML_VULKAN_MEMORY_DEBUG:BOOL=OFF"
        "-DGGML_VULKAN_SHADER_DEBUG_INFO:BOOL=OFF"
        "-DGGML_VULKAN_VALIDATE:BOOL=OFF"

        # Current package version is intentionally descriptive, but CMake wants
        # LLAMA_BUILD_NUMBER to be a numeric C++ int.
        "-DLLAMA_BUILD_NUMBER:STRING=9412"
      ];
  });
}
