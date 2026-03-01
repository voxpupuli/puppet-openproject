# GitHub Actions CI via Modulesync

## Status: DEFERRED

GitHub Actions CI for this module should be managed by modulesync, not
hand-crafted per module. This ensures consistency across all Vox Pupuli
modules.

## Cross-reference

CI pipeline design is being tracked in the openvox-mcp-modules-voxpupuli
project, which handles the modulesync configuration for Vox Pupuli
module CI templates.

## Decision Log

- 2026-03-01: Deferred to modulesync. Hand-crafting CI per module would
  conflict with the modulesync-managed approach used across Vox Pupuli.
