# Changelog

## [Unreleased]

## [2.15-2] - 2026-09-26

### Fixed

- Remote archives (`cpio -F host:file`, over rsh/ssh) asked the remote host to
  run a copy of `rmt` under `/nix/store` — a path that means nothing there, and
  that this build does not ship. The default is `/etc/rmt` now, where the remote
  side is expected to provide it; `--rmt-command=` still overrides it.

### Changed

- Built by the same compiler as the rest of the catalog. The Linux x86_64 binary
  grew from 245 KB to 320 KB; behaviour is unchanged.

- The build now runs GNU cpio's own test suite, all 17 tests, on every target the
  build host can execute. Nothing before this ran upstream's tests at all.

### Security

- A crafted archive could write outside the directory it was extracted into, by
  way of a tar link name (CVE-2026-66484), and a very long path or `--owner`
  argument could crash cpio by exhausting the stack (CVE-2026-66485).

- File and member names were printed exactly as stored, so a name carrying
  terminal escape sequences reached the terminal untouched (CVE-2026-66486); the
  fix brings `--quoting-style=` and `--quote-chars=` with it.

- All three are upstream fixes, carried in with nixpkgs 26.05. Every release
  before this one is affected.
