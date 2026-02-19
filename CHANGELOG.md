# Changelog

All notable changes to this project will be documented in this file.

## [v1.0.0](https://github.com/voxpupuli/puppet-openproject/tree/v1.0.0) (2026-02-19)

Initial release as a Vox Pupuli module.

**Features**

- Install and configure OpenProject via unattended `installer.dat` configuration
- APT repository management with GPG key verification
- Support for environment variable overrides via `conf.d/env`
- Enterprise token configuration support
- Optional full-text extraction dependencies (catdoc, unrtf, poppler-utils, tesseract-ocr)
- Idempotent configuration through semantic comparison of sorted/normalized files
- APT package hold support
- Bolt task for full OpenProject backup (database, attachments, configuration, repositories)
- Bolt task for OpenProject restore from timestamped backups

**Supported platforms**

- Debian 11, 12 (amd64)
- OpenVox / Puppet 7.16 to < 9.0.0
