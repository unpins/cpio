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
      # Windows via Cosmopolitan, not mingw: cpio's configure can't determine
      # the return type of major()/minor() under mingw (Windows has no device
      # numbers / sys/sysmacros.h), and the archive code references
      # major()/makedev() for device entries. Cosmopolitan libc ships
      # sys/sysmacros.h, so the cosmocc cross builds clean.
      #
      # cosmocc 4.0.2's libc declares `timespec_cmp` (a plain, non-inline extern
      # in libc/calls/struct/timespec.h). cpio 2.15's bundled (vintage) gnulib
      # also defines `timespec_cmp` as an extern-inline in lib/timespec.h; with
      # the libc declaration in scope the C99 inline rules force an *external*
      # definition in every TU that includes the header (copyin.c, gettime.c,
      # utimens.c), so ld.bfd reports "multiple definition". The two are the
      # same function (lexicographic timespec compare), so let the linker keep
      # the first. Windows-only: native gnulib (newer) + glibc/musl don't hit
      # this. Carried on NIX_CFLAGS_LINK so it reaches only the $CC-driven final
      # link, never a direct `ld -r`.
      windowsBuild = pkgs:
        let
          pruned = tune (unpins-lib.lib.cosmoStaticCross pkgs).cpio;
          flag = " -Wl,--allow-multiple-definition";
        in
        pruned.overrideAttrs (old:
          if old ? env && old.env ? NIX_CFLAGS_LINK then
            { env = old.env // { NIX_CFLAGS_LINK = old.env.NIX_CFLAGS_LINK + flag; }; }
          else if old ? env then
            { env = old.env // { NIX_CFLAGS_LINK = flag; }; }
          else if old ? NIX_CFLAGS_LINK then
            { NIX_CFLAGS_LINK = old.NIX_CFLAGS_LINK + flag; }
          else { NIX_CFLAGS_LINK = flag; });
    };
}
