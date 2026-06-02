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
      # No winManRoot: cpio.1 ships in-tree and `make install` installs it on
      # every target — the cosmo cross included (verified: its $out/share/man
      # has cpio.1.gz) — so the .exe harvests its OWN man, the same single page
      # native keeps after the rmt prune. No graft.
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
