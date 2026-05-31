{
  description = "Standalone build of GNU cpio";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # GNU cpio is a single binary (`cpio`) plus one hand-written man page
  # (`doc/cpio.1`, shipped in-tree — no help2man, so it embeds verbatim on
  # every target). No multicall, no aliases.
  #
  # nixpkgs' cpio also builds `rmt` (the remote-tape helper) into `libexec/`
  # and installs its `rmt.8` page. unpins ships ONE binary, so we drop rmt
  # (and its man) on both the native and Windows paths.
  outputs = { self, unpins-lib }:
    let
      pkgsX = unpins-lib.inputs.nixpkgs.legacyPackages.x86_64-linux;

      # The Windows binary's man comes from a graft, not its own cross build
      # (mkStandaloneFlake's winManSrc). The default graft is nixpkgs' cpio,
      # whose share/man carries cpio.1 AND rmt.8 — and we don't ship rmt. Pin
      # a curated single-page tree so the .exe embeds exactly `cpio.1`, the
      # same page the native side keeps after pruning.
      winMan = pkgsX.runCommand "cpio-win-man" { } ''
        mkdir -p "$out/share/man/man1"
        zcat ${pkgsX.cpio}/share/man/man1/cpio.1.gz > "$out/share/man/man1/cpio.1"
      '';

      # Drop the rmt helper + its man page so the package is a single binary.
      # Runs at postInstall (man pages are still uncompressed here; fixupPhase
      # gzips them later).
      prune = old: {
        postInstall = (old.postInstall or "") + "\n" + ''
          for o in $outputs; do
            d="''${!o}"
            rm -rf "$d/libexec"
            rm -f "$d/share/man/man8/rmt.8" "$d/share/man/man8/rmt.8.gz"
            rmdir "$d/share/man/man8" 2>/dev/null || true
          done
        '';
      };
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "cpio";
      winManRoot = winMan;
      smoke = [ "--version" ];
      smokePattern = "GNU cpio";
      build = pkgs: pkgs.pkgsStatic.cpio.overrideAttrs prune;
      # Windows via Cosmopolitan, not mingw: cpio's configure can't determine
      # the return type of major()/minor() under mingw (Windows has no device
      # numbers / sys/sysmacros.h), and the archive code references
      # major()/makedev() for device entries. Cosmopolitan libc ships
      # sys/sysmacros.h, so the cosmocc cross builds clean.
      windowsBuild = pkgs:
        (unpins-lib.lib.cosmoStaticCross pkgs).cpio.overrideAttrs prune;
    };
}
