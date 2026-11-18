{
  description = "GNU cpio as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # GNU cpio is one program (`cpio`) plus one hand-written man page
  # (`doc/cpio.1`, shipped in-tree — no help2man, so it embeds verbatim on
  # every target). `--with-rmt=/etc/rmt` (below) keeps nixpkgs from building
  # the `rmt` remote-tape helper.
  outputs = { self, unpins-lib }:
    let
      # The native test suite and the rmt path, on the native and Windows
      # builds alike. A drv->drv tune (not a bare attr override) so doCheck can
      # read the build/host platforms off the drv.
      tune = drv: drv.overrideAttrs (old: {
        # GNU cpio's autotest suite (17/17) runs on native/i686 runners; auto-
        # skips on crosses the build host can't execute (Windows here = cosmo).
        doCheck = drv.stdenv.buildPlatform.canExecute drv.stdenv.hostPlatform;
        # DEFAULT_RMT_COMMAND defaults to $libexecdir/rmt, a store path. It is
        # not even a local path: cpio passes it to the REMOTE host over rsh/ssh
        # (lib/rtapelib.c), where a /nix/store name is meaningless. /etc/rmt is
        # the traditional location the remote side is expected to provide, and
        # `--rmt-command=` still overrides at runtime. With it set, the rmt
        # helper isn't built.
        configureFlags = (old.configureFlags or [ ]) ++ [ "--with-rmt=/etc/rmt" ];
        # Without rmt, `make install` still creates an empty man8.
        postInstall = (old.postInstall or "") + "\n" + ''
          rmdir "$out/share/man/man8" 2>/dev/null || true
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
      # as native. No graft.
      smoke = [ "--version" ];
      smokePattern = "GNU cpio";
      build = pkgs: tune pkgs.pkgsStatic.cpio;
      windowsBuild = import ./cosmo.nix { inherit unpins-lib tune; };
    };
}
