# cpio for Windows-x86_64, via Cosmopolitan and not mingw: cpio's configure can't determine
# the return type of major()/minor() under mingw (Windows has no device
# numbers / sys/sysmacros.h), and the archive code references
# major()/makedev() for device entries. Cosmopolitan libc ships
# sys/sysmacros.h, so the cosmocc cross builds clean.
#
# cosmocc's libc also declares `timespec_cmp` (libc/calls/struct/timespec.h),
# and cpio's gnulib defines it `_GL_INLINE` in lib/timespec.h. With that
# declaration in scope, C99 inline rules make every includer (copyin.c,
# gettime.c, utimens.c) emit an external copy: "multiple definition" at link.
# -fgnu89-inline restores the one-copy `extern inline` gnulib expects.
{ unpins-lib, tune }:
pkgs:
(tune (unpins-lib.lib.cosmoStaticCross pkgs).cpio).overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./patches/windows-crlf-names.patch ];
  env = (old.env or { }) // {
    NIX_CFLAGS_COMPILE = toString [ (old.env.NIX_CFLAGS_COMPILE or "") "-fgnu89-inline" ];
  };
})
