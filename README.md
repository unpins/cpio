# cpio

Standalone build of [GNU cpio](https://www.gnu.org/software/cpio/).

[![CI](https://github.com/unpins/cpio/actions/workflows/cpio.yml/badge.svg)](https://github.com/unpins/cpio/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin cpio
```

Or run without installing:

```bash
unpin run cpio
```

## Build locally

```bash
nix build github:unpins/cpio
./result/bin/cpio --version
```

Or run directly:

```bash
nix run github:unpins/cpio
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/cpio/releases) page has standalone binaries for manual download.

## Build notes

- Single binary. The `rmt` remote-tape helper (a second executable GNU cpio
  installs into `libexec/`) is dropped — unpins ships one self-contained `cpio`.
- **Windows** is built with [Cosmopolitan](https://github.com/jart/cosmopolitan)
  instead of mingw: cpio's device-number handling (`major`/`minor`/`makedev`)
  has no mingw equivalent, and Cosmopolitan libc provides `sys/sysmacros.h`.

## Man pages

The `cpio` man page is embedded in the binary; read it with `unpin man cpio`.
(The `rmt.8` page is dropped along with the helper.)
