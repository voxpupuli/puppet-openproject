# Ubuntu and SLES Support

## Status: BLOCKED

## Ubuntu

OpenProject provides packages for Ubuntu 22.04 and 24.04, but there are
no vagrant libvirt boxes available for automated acceptance testing.
Adding Ubuntu to `metadata.json` without acceptance test coverage would
be premature.

### Steps to enable

1. Find or build vagrant libvirt boxes for Ubuntu 22.04/24.04
2. Add `data/os/Ubuntu.yaml` (same as Debian.yaml, packages match)
3. Add Ubuntu to `metadata.json` operatingsystem_support
4. Add nodesets and acceptance tests
5. Add Ubuntu to `test_on` in all spec files

## SLES 15

OpenProject provides packages for SLES 15, but no vagrant libvirt boxes
are available.

### Steps to enable

1. Find or build vagrant libvirt boxes for SLES 15
2. Add `data/os/SLES.yaml` (zypper repo config)
3. Extend `manifests/repository.pp` with Suse family case
4. Add SLES to `metadata.json` operatingsystem_support
5. Add nodesets and acceptance tests

## Cross-reference

Related work tracked in the openvox-mcp-modules-voxpupuli project for
modulesync CI design that may provide shared vagrant box infrastructure.

## Decision Log

- 2026-03-01: Documented as future work. Blocked by vagrant libvirt box
  availability for both Ubuntu and SLES.
