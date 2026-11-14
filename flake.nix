{
  description = "GNU cpio as a single self-contained binary";

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
      # Drop the rmt helper + its man page so the package is a single binary,
      # and wire the native test suite. Kept as a drv->drv tune (not a bare attr
      # override) so doCheck can read the build/host platforms off the drv. The
      # prune runs at postInstall (man pages still uncompressed here; fixupPhase
      # gzips them later).
      tune = drv: drv.overrideAttrs (old: {
        # GNU cpio's autotest suite (17/17) runs on native/i686 runners; auto-
        # skips on crosses the build host can't execute (Windows here = cosmo).
        doCheck = drv.stdenv.buildPlatform.canExecute drv.stdenv.hostPlatform;
        # DEFAULT_RMT_COMMAND defaults to $libexecdir/rmt, i.e. the store path
        # we delete right below — so the shipped binary carried a dead store
        # reference. It is not even a local path: cpio passes it to the REMOTE
        # host over rsh/ssh (lib/rtapelib.c), where a /nix/store name is
        # meaningless. /etc/rmt is the traditional location the remote side is
        # expected to provide, and `--rmt-command=` still overrides at runtime.
        # The option also skips building the rmt helper we drop anyway.
        configureFlags = (old.configureFlags or [ ]) ++ [ "--with-rmt=/etc/rmt" ];
        postInstall = (old.postInstall or "") + "\n" + ''
          for o in $outputs; do
            d="''${!o}"
            rm -rf "$d/libexec"
            rm -f "$d/share/man/man8/rmt.8" "$d/share/man/man8/rmt.8.gz"
            rmdir "$d/share/man/man8" 2>/dev/null || true
          done
        '';
      });
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "cpio";

      engine = "unpin-llvm";
      multicall = {
        programs = [{ name = "cpio"; }];
      };
      # No winManRoot: cpio.1 ships in-tree and `make install` installs it on
      # every target — the cosmo cross included (verified: its $out/share/man
      # has cpio.1.gz) — so the .exe harvests its OWN man, the same single page
      # native keeps after the rmt prune. No graft.
      smoke = [ "--version" ];
      smokePattern = "GNU cpio";
      build = pkgs: tune pkgs.pkgsStatic.cpio;
      windowsBuild = import ./cosmo.nix { inherit unpins-lib tune; };
    };
}
