{
  lib,
  stdenv,
  fetchurl,
  patchelf,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "kimi-cli";
  version = "1.37.0";

  src = fetchurl {
    url = "https://github.com/MoonshotAI/kimi-cli/releases/download/${version}/kimi-${version}-x86_64-unknown-linux-gnu-onedir.tar.gz";
    hash = "sha256-dpZQQBk/+eMel4BqbWtG15HYXtcGlc0UbqMfqoXP61A=";
  };

  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/kimi-cli" "$out/bin"
    tar -xzf "$src" -C "$out/share/kimi-cli"

    # Patch bundled ELF binaries to use the NixOS dynamic loader.
    while IFS= read -r -d "" elf; do
      if patchelf --print-interpreter "$elf" >/dev/null 2>&1; then
        patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" "$elf"
      fi
    done < <(find "$out/share/kimi-cli" -type f -perm -111 -print0)

    kimi_bin="$(find "$out/share/kimi-cli" -type f -name kimi -perm -111 | head -n1)"
    if [ -z "$kimi_bin" ]; then
      echo "kimi executable not found in release archive" >&2
      find "$out/share/kimi-cli" -maxdepth 3 -type f >&2
      exit 1
    fi

    makeWrapper "$kimi_bin" "$out/bin/kimi" \
      --prefix LD_LIBRARY_PATH : "$out/share/kimi-cli/kimi/_internal"
    ln -s "$out/bin/kimi" "$out/bin/kimi-cli"

    runHook postInstall
  '';

  meta = {
    description = "Kimi Code CLI";
    homepage = "https://github.com/MoonshotAI/kimi-cli";
    license = lib.licenses.asl20;
    mainProgram = "kimi";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
