# Contributing to puppet-openproject

This module is maintained by [Vox Pupuli](https://voxpupuli.org/). We
welcome contributions from the community.

## Getting started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a feature branch from `main`
4. Make your changes, including tests
5. Submit a pull request

For general Vox Pupuli contribution guidelines, see
<https://voxpupuli.org/contributing/>.

## Testing

### Unit tests

```bash
bundle install
bundle exec rake spec
```

### Acceptance tests

Acceptance tests use [Beaker](https://github.com/voxpupuli/beaker) with
vagrant\_libvirt:

```bash
BEAKER_SETFILE=spec/acceptance/nodesets/debian12-libvirt.yaml bundle exec rake beaker
```

### Linting and style

This project uses [overcommit](https://github.com/sds/overcommit) to run
pre-commit hooks:

```bash
overcommit --install
bundle exec rake lint
bundle exec rubocop
```

## Coding standards

- Follow [puppet-lint](http://puppet-lint.com/) conventions
- Follow [rubocop](https://rubocop.org/) for Ruby files
- Add SPDX license headers to all new source files
- Include unit tests for new classes, defined types, and functions
- Include acceptance tests for user-facing behaviour changes

## AI-assisted contributions (MCP)

This project enforces the [OpenVox AI Governance Policy](GOVERNANCE.md)
via MCP. If you use AI tools when contributing:

- **Disclosure required:** Add an appropriate AI trailer to your commit
  message (e.g. `AI-Co-Author:`, `AI-Assisted-By:`, `AI-Generated-By:`)
- **DCO sign-off required:** All commits must include a
  `Signed-off-by:` trailer (`git commit -s`)
- **Human review required:** AI-generated or AI-co-authored code must be
  reviewed by a human before merge. Add a `Human-Reviewed-By:` trailer
  after review
- See `GOVERNANCE.md` for the full policy

## Commit messages

Write clear, descriptive commit messages. If AI tools were involved, use
the trailers described above. Example:

```
Add RHEL 9 support for repository management

Extend openproject::repository with a yumrepo resource for RedHat-family
systems alongside the existing apt::source for Debian.

Signed-off-by: Your Name <your.email@example.com>
AI-Co-Author: Claude Opus 4.6 (Anthropic) <noreply@anthropic.com>
Human-Reviewed-By: Your Name <your.email@example.com>
```
