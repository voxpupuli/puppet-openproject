# Debian 13 (Trixie) Support Blocked by SHA1 APT Signing Key

## Status: BLOCKED

## Problem

OpenProject's APT repository signing key (hosted at
`https://dl.packager.io/srv/opf/openproject/key`) uses SHA1 for its
self-signature. Debian 13 (Trixie) deprecated SHA1 signatures in
February 2026, causing `apt update` to reject the repository with:

```
W: GPG error: https://dl.packager.io/srv/deb/opf/openproject/stable/17/debian
  trixie InRelease: The following signatures used a weak algorithm (SHA1):
  ...
```

This is a **hard blocker** -- Puppet's `apt::source` resource will fail
on every run because `apt update` rejects the InRelease signature.

## What Needs to Happen

1. **Upstream (OpenProject / packager.io):** Reissue the APT signing key
   with SHA256 or stronger self-signatures. The key fingerprint may
   change, which means `data/os/Debian.yaml` will need an updated
   `checksum_value`.

2. **This module:** Once the key is reissued:
   - Update `data/os/Debian.yaml` with the new `checksum_value`
   - Add `"13"` to `metadata.json` operatingsystem_support for Debian
   - Re-create `spec/acceptance/nodesets/debian13-libvirt.yaml`
   - Add Debian 13 to `test_on` arrays in all spec files
   - Run acceptance tests against a Trixie VM
   - Update README.md to remove the blocker note

## Tracking

- OpenProject packager.io key URL: https://dl.packager.io/srv/opf/openproject/key
- Debian SHA1 deprecation: https://wiki.debian.org/SHA1
- This module issue: (file upstream issue when ready)

## Decision Log

- 2026-03-01: Removed `spec/acceptance/nodesets/debian13-libvirt.yaml`
  and documented the blocker. Debian 13 is not listed in `metadata.json`
  and adding it would be dishonest given the SHA1 issue.
