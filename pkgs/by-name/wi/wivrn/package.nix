{
  config,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchFromGitLab,
  applyPatches,
  autoAddDriverRunpath,
  avahi,
  boost,
  cli11,
  cmake,
  cudaPackages ? {},
  cudaSupport ? config.cudaSupport,
  eigen,
  ffmpeg,
  freetype,
  git,
  glm,
  glslang,
  harfbuzz,
  libdrm,
  libGL,
  libva,
  libpulseaudio,
  libX11,
  libXrandr,
  nix-update-script,
  nlohmann_json,
  onnxruntime,
  openxr-loader,
  pipewire,
  pkg-config,
  python3,
  shaderc,
  spdlog,
  systemd,
  udev,
  vulkan-headers,
  vulkan-loader,
  vulkan-tools,
  x264,
  openssl,
  glib,
  libnotify,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wivrn";
  version = "0.22";

  src = fetchFromGitHub {
    owner = "wivrn";
    repo = "wivrn";
    rev = "v${finalAttrs.version}";
    hash = "sha256-i/CG+zD64cwnu0z1BRkRn7Wm67KszE+wZ5geeAvrvMY=";
  };

  monado = applyPatches {
    src = fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "monado";
      repo = "monado";
      rev = "aa2b0f9f1d638becd6bb9ca3c357ac2561a36b07";
      hash = "sha256-yfHtkMvX/gyVG0UgpSB6KjSDdCym6Reb9LRb3OortaI=";
    };

    patches = [
      "${finalAttrs.src}/patches/monado/0001-c-multi-early-wake-of-compositor.patch"
      "${finalAttrs.src}/patches/monado/0003-ipc-server-Always-listen-to-stdin.patch"
      "${finalAttrs.src}/patches/monado/0004-Use-extern-socket-fd.patch"
      "${finalAttrs.src}/patches/monado/0005-distortion-images.patch"
      "${finalAttrs.src}/patches/monado/0006-environment-blend-mode.patch"
      "${finalAttrs.src}/patches/monado/0008-Use-mipmaps-for-distortion-shader.patch"
      "${finalAttrs.src}/patches/monado/0009-convert-to-YCbCr-in-monado.patch"
      "${finalAttrs.src}/patches/monado/0010-d-solarxr-Add-SolarXR-WebSockets-driver.patch"
      "${finalAttrs.src}/patches/monado/0011-Revert-a-bindings-improve-reproducibility-of-binding.patch"
      "${finalAttrs.src}/patches/monado/0012-store-alpha-channel-in-layer-1.patch"
    ];
  };

  imgui = applyPatches {
    src = fetchFromGitHub {
      owner = "ocornut";
      repo = "imgui";
      rev = "v1.91.3";
      hash = "sha256-J4gz4rnydu8JlzqNC/OIoVoRcgeFd6B1Qboxu5drOKY=";
    };

    patches = [
      "${finalAttrs.src}/patches/imgui/0001-Change-ImGui-ButtonBehavior-default-flags-when-using.patch"
      "${finalAttrs.src}/patches/imgui/0002-Add-ImGuiWindowFlags_NoFocusOnClick-flag.patch"
    ];
  };

  strictDeps = true;

  postUnpack = ''
    # Let's make sure our monado source revision matches what is used by WiVRn upstream
    ourMonadoRev="${finalAttrs.monado.src.rev}"
    theirMonadoRev=$(grep "GIT_TAG" ${finalAttrs.src.name}/CMakeLists.txt | awk '{print $2}')
    if [ ! "$theirMonadoRev" == "$ourMonadoRev" ]; then
      echo "Our Monado source revision doesn't match CMakeLists.txt." >&2
      echo "  theirs: $theirMonadoRev" >&2
      echo "    ours: $ourMonadoRev" >&2
      return 1
    fi
  '';

  nativeBuildInputs =
    [
      cmake
      git
      glslang
      pkg-config
      python3
      glib
    ]
    ++ lib.optionals cudaSupport [autoAddDriverRunpath];

  buildInputs =
    [
      avahi
      boost
      cli11
      eigen
      ffmpeg
      freetype
      glm
      harfbuzz
      libdrm
      libGL
      libva
      libX11
      libXrandr
      libpulseaudio
      nlohmann_json
      onnxruntime
      openxr-loader
      pipewire
      shaderc
      spdlog
      systemd
      udev
      vulkan-headers
      vulkan-loader
      vulkan-tools
      x264
      openssl
      libnotify
    ]
    ++ lib.optionals cudaSupport [cudaPackages.cudatoolkit];

  cmakeFlags = [
    (lib.cmakeBool "WIVRN_USE_VAAPI" true)
    (lib.cmakeBool "WIVRN_USE_X264" true)
    (lib.cmakeBool "WIVRN_USE_NVENC" cudaSupport)
    (lib.cmakeBool "WIVRN_USE_SYSTEMD" true)
    (lib.cmakeBool "WIVRN_USE_PIPEWIRE" true)
    (lib.cmakeBool "WIVRN_USE_PULSEAUDIO" true)
    (lib.cmakeBool "WIVRN_BUILD_CLIENT" false)
    (lib.cmakeBool "WIVRN_OPENXR_INSTALL_ABSOLUTE_RUNTIME_PATH" true)
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_MONADO" "${finalAttrs.monado}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_IMGUI" "${finalAttrs.imgui}")
  ];

  passthru.updateScript = nix-update-script {};

  meta = with lib; {
    description = "An OpenXR streaming application to a standalone headset";
    homepage = "https://github.com/Meumeu/WiVRn/";
    changelog = "https://github.com/Meumeu/WiVRn/releases/";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [passivelemon];
    platforms = platforms.linux;
    mainProgram = "wivrn-server";
  };
})
