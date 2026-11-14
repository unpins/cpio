# cpio for Windows-x86_64, via Cosmopolitan and not mingw: cpio's configure can't determine
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
{ unpins-lib, tune }:
pkgs:
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
  else { NIX_CFLAGS_LINK = flag; })
