{ lib
, stdenv
, fetchzip
, firefox-bin
, suffix
, revision
, system
, throwSystem
}:
let
  suffix' = if lib.hasPrefix "linux" suffix
            then "ubuntu-22.04" + (lib.removePrefix "linux" suffix)
            else suffix;
in
stdenv.mkDerivation {
  name = "firefox";
  src = fetchzip {
    url = "https://playwright.azureedge.net/builds/firefox/${revision}/firefox-${suffix'}.zip";
    sha256 = {
      x86_64-linux = "00gjpkagbnk2rpnw394l4b53zvl10yqcaj075fa0hc5fnv6bzydd";
      aarch64-linux = "025q1vv835pnl60y8sl9r3r08cmjw68ing2ng7r61ycwqa223i9h";
    }.${system} or throwSystem;
  };

  inherit (firefox-bin.unwrapped)
    nativeBuildInputs
    buildInputs
    runtimeDependencies
    appendRunpaths
    patchelfFlags
  ;

  buildPhase = ''
    mkdir -p $out/firefox
    cp -R . $out/firefox
  '';
}
