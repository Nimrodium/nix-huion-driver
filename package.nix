{
  pkgs,
  lib,
  version,
  hash,
  useCN,
  ...
}:let
name = "huion-tablet-driver";
fetchDriver = version: hash: useCN: let toplevel = if useCN then "cn" else "com"; in pkgs.fetchurl {

  url = "https://driverdl.huion.${toplevel}/driver/Linux/HuionTablet_LinuxDriver_v${version}.x86_64.tar.xz";
  inherit hash;
  curlOptsList = [ "-H" "User-Agent: Mozilla/5.0" "-H" "Referer: https://www.huion.${toplevel}/" ];
};

huion-tablet-driver = pkgs.stdenv.mkDerivation rec {
  pname = "${name}-unwrapped";
  inherit version;
  src = fetchDriver version hash useCN;
  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    xdotool
    libGL
    freetype
    libz
    libusb1
    e2fsprogs
    fontconfig
    libgpg-error
    xmodmap
  ];
  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    makeWrapper
  ];
  installPhase = ''
    mkdir -p $out/lib/huiontablet
    mkdir -p $out/lib/udev/rules.d
    cp -r huiontablet $out/lib/
    chmod +x $out/lib/huiontablet/huionCore
    chmod +x $out/lib/huiontablet/huiontablet
    cp huiontablet/res/rule/20-huion.rules $out/lib/udev/rules.d/

    # desktop
    mkdir -p $out/share/applications
    cat > $out/share/applications/huiontablet.desktop <<EOF
    [Desktop Entry]
    Name=HuionTablet
    Comment=Huion driver
    Exec=$out/bin/huiontablet
    Icon=huiontablet
    Terminal=false
    Type=Application
    Categories=Utility;
    StartupNotify=true
    EOF

    # icon
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp icon/huiontablet.png \
       $out/share/icons/hicolor/256x256/apps/

    # wrapper
    mkdir -p $out/bin
    makeWrapper $out/lib/huiontablet/huiontablet.sh \
      $out/bin/huiontablet \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --prefix PATH : ${lib.makeBinPath [ pkgs.xdotool pkgs.xmodmap ]} \


    makeWrapper $out/lib/huiontablet/huionCore.sh \
      $out/bin/huionCore \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath buildInputs} \
      --prefix PATH : ${lib.makeBinPath [ pkgs.xdotool pkgs.xmodmap ]}

    runHook postInstall
  '';
  postPatch = ''
    substituteInPlace huiontablet/huiontablet.sh \
      --replace-fail 'dirname=`dirname $0`' "dirname=$out/lib/huiontablet" \
      --replace-fail 'ps -e|grep' "pgrep -x" \
      --replace-fail 'killall' "pkill -x"

    substituteInPlace huiontablet/huionCore.sh \
      --replace-fail 'dirname=`dirname $0`' "dirname=$out/lib/huiontablet"
  '';
};
in pkgs.buildFHSEnv {
  pname = name;
  inherit version;
  src = fetchDriver version hash useCN;
#   nativeBuildInputs = with pkgs; [
#
#   ];
  targetPkgs = pkgs: with pkgs; [
    huion-tablet-driver
  ];
  extraPreBwrapCmds = ''
      RES="$HOME/.local/share/huiontablet/res"
      mkdir -p "$RES"
      cp -rn --no-preserve=mode ${huion-tablet-driver}/lib/huiontablet/res/. "$RES"/
    '';

    extraBwrapArgs = [
      "--bind" "$HOME/.local/share/huiontablet/res" "${huion-tablet-driver}/lib/huiontablet/res"
    ];
  runScript = "${huion-tablet-driver}/lib/huiontablet/huiontablet.sh";
}
