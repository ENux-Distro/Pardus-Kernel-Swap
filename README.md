# Pardus Kernel Swap

# **Status: Stable**

A classic-style terminal utility for advanced Pardus users to inspect, evaluate
and swap their running kernel. The interface is pure Bash + whiptail, styled
after FreeBSD `sysinstall` and 1990s UNIX administration tools: blue background,
white text, keyboard-only navigation.

```
Current Kernel:
6.12.50+pardus25-amd64

Security Status:
Known CVEs detected

Recommendation:
Upgrade to a newer supported kernel.

                [ OK ]
```

## What it does

- Detects the currently running kernel (`uname -r`).
- Checks it against a local CVE database and reports matching vulnerabilities,
  their severity, and a recommendation. **It never installs anything because of
  a CVE — it only advises.**
- Offers a menu of predefined Pardus kernels (Cutting-Edge / Stable / LTS /
  Old-LTS) plus a Custom build-from-source option.
- Downloads and installs predefined kernel `.deb` packages.
- Builds custom kernels from an upstream source tarball with
  `make bindeb-pkg ... LOCALVERSION="+pardus25-amd64"` and installs the result.
- Logs every action to `/var/log/pardus-kernel-swap.log`.

## Safety

This tool is deliberately conservative:

- Never reboots automatically.
- Never removes old kernels.
- Always asks for confirmation before modifying the system.
- Can be cancelled at any stage.
- Handles download, installation and build failures gracefully, preserving logs.

## Requirements

- Root privileges (`sudo`).
- `whiptail`, `jq`, `dpkg`, `uname` (always required).
- `curl` or `wget` (downloads).
- For Custom builds: `make`, `gcc`, `tar`, and the usual kernel build
  dependencies (`build-essential`, `libncurses-dev`, `flex`, `bison`,
  `libssl-dev`, `libelf-dev`, ...).

## Usage

```bash
sudo ./bin/pardus-kernel-swap
```

Or install system-wide:

```bash
sudo ./install.sh        # symlinks bin/pardus-kernel-swap into /usr/local/sbin
sudo pardus-kernel-swap
```

## Localization

The interface is bilingual: **Turkish** and **English**. The language is chosen
automatically from the active locale — if `LC_ALL`/`LC_MESSAGES`/`LANG` starts
with `tr` the UI is Turkish, otherwise English. English is the fallback for any
string lacking a translation, so the app is never left blank.

Force a language regardless of locale:

```bash
sudo PKS_LANG_OVERRIDE=tr ./bin/pardus-kernel-swap
sudo PKS_LANG_OVERRIDE=en ./bin/pardus-kernel-swap
```

UI strings live in `lib/i18n.sh` (keyed `printf` formats). Translatable data —
kernel summaries, CVE descriptions and recommendations — carry optional `*_tr`
fields in `data/kernels.json` and `data/cve.json`.

## Project layout

```
pardus-kernel-swap/
├── bin/
│   └── pardus-kernel-swap   Main entry point + screen/flow logic
├── lib/
│   ├── common.sh            Paths, globals, colour scheme, helpers
│   ├── log.sh               Logging subsystem
│   ├── ui.sh                whiptail wrappers
│   ├── kernel.sh            Running-kernel detection + catalog access
│   ├── cve.sh               CVE detection engine
│   ├── download.sh          Download subsystem (curl/wget)
│   ├── install.sh           .deb install + bootloader refresh
│   └── build.sh             Custom kernel build pipeline
├── data/
│   ├── kernels.json         Predefined kernel catalog
│   └── cve.json             Local CVE database
└── install.sh               Optional system-wide installer
```

## CVE database

`data/cve.json` holds the local database. A kernel base version `V`
(`7.0.12+pardus25-amd64` → `7.0.12`) is considered affected by an entry when:

```
introduced <= V  AND  (fixed is null OR V < fixed)
```

Comparisons use `dpkg --compare-versions`. The schema is intentionally simple so
a future online updater can replace the file wholesale. Set `"fixed": null` for
an issue with no fix yet (affected for every `V >= introduced`).

## Predefined kernel packages

Packages are fetched from:

```
https://github.com/ENux-Distro/Pardus-Kernel-Swap/releases/download/Kernels/<version>.deb
```

where `<version>` is the catalog version string (e.g.
`7.0.12+pardus25-amd64`).

## Installation

### Installing from the cloned repo

```bash
sudo ./install.sh        # symlinks bin/pardus-kernel-swap into /usr/local/sbin
sudo pardus-kernel-swap
```

### Installing via the .deb package

```bash
wget https://github.com/ENux-Distro/pardus-code/releases/download/Pardus-Code/pardus-code_amd64.deb      # downloads the .deb package
sudo apt install ./pardus-code_amd64.deb      # Installs the .deb package via apt using sudo
```


## License

GPL-2.0.
