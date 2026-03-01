# OpenVox MCP Compliance & Module Findings

**Module**: puppet-openproject v1.0.0
**Tier**: Tier 2 (Voxpupuli Community) — full policy enforcement as peer recommendation
**License**: GPL-3.0-or-later (accepted, but not preferred; preferred is GPL-3.0-only)
**Date**: 2026-03-01
**Reviewer**: Claude Opus 4.6 (Anthropic) — AI-assisted review

---

## Table of Contents

1. [OpenVox MCP Policy Compliance](#1-openvox-mcp-policy-compliance)
2. [Puppet Module Quality Gaps](#2-puppet-module-quality-gaps)
3. [Summary Matrix](#3-summary-matrix)

---

## 1. OpenVox MCP Policy Compliance

### Area A — Attribution & Disclosure

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| A1 | Mandatory AI disclosure on any AI involvement | **FAIL** | No AI disclosure trailers found on any existing commits. If AI was involved in authoring any part of this module, trailers are missing. |
| A2 | Standardized AI role trailers on every commit | **FAIL** | None of the 5 commits carry `AI-Generated-By`, `AI-Co-Author`, `AI-Assisted-By`, or `AI-Reviewed-By` trailers. |
| A3 | Mandatory human review at Tier 2 (different person) | **N/A** | Cannot verify from repository state alone — this is a process requirement for future contributions. |
| A4 | No threshold — even trivial AI involvement requires disclosure | **FAIL** | See A1/A2. |

**Remediation**: All future commits involving AI must include proper trailers. If past commits had AI involvement, this should be disclosed retroactively (e.g., in a `NOTICE` or `.ai-provenance.yml` file).

---

### Area B — License Compliance

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| B1 | DCO sign-off required (`Signed-off-by` trailer) | **FAIL** | No `Signed-off-by` trailers found on any commits. |
| B1 | SPDX headers on all source files | **FAIL** | Zero files contain `SPDX-License-Identifier` or `SPDX-FileCopyrightText` headers. Affected: all `.pp`, `.rb`, `.epp` files. |
| B1 | License allowlist compliance | **PASS** | `GPL-3.0-or-later` is on the accepted list. |
| B2 | Four-layer enforcement (instructions, validation, review, CI) | **PARTIAL** | CI linting exists but no SPDX/DCO validation gates. |
| B3 | AI provenance bibliography (`.ai-provenance.yml`) | **FAIL** | File does not exist in the repository. |
| B4 | Policies delivered via MCP channels | **N/A** | Infrastructure concern, not module-level. |

**Remediation**:
- Add `SPDX-License-Identifier: GPL-3.0-or-later` and `SPDX-FileCopyrightText` to all source files.
- Add `Signed-off-by` trailers to all future commits (use `git commit -s`).
- Create `.ai-provenance.yml` documenting any AI involvement.
- Consider whether `GPL-3.0-only` (preferred) is more appropriate than `GPL-3.0-or-later`.

**Files requiring SPDX headers** (at minimum):
- `manifests/init.pp`
- `manifests/configure.pp`
- `manifests/install.pp`
- `manifests/repository.pp`
- `manifests/system_requirements.pp`
- `templates/env.epp`
- `templates/installer.dat.epp`
- `templates/enterprise_token.rb.epp`
- `tasks/backup.rb`
- `tasks/restore.rb`
- `spec/classes/openproject_spec.rb`
- `spec/classes/configure_spec.rb`
- `spec/classes/install_spec.rb`
- `spec/classes/repository_spec.rb`
- `spec/tasks/backup_spec.rb`
- `spec/tasks/restore_spec.rb`
- `spec/acceptance/openproject_spec.rb`
- `spec/spec_helper.rb`
- `spec/spec_helper_acceptance.rb`
- `spec/spec_helper_local.rb`

---

### Area C — Coding Standards

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| C1 | voxbox container recommended | **PASS** | CI uses `ghcr.io/voxpupuli/voxbox` images. |
| C2 | Hard gate for new dependencies (Tier 2) | **PASS** | Only 2 well-known dependencies (puppetlabs/apt, puppetlabs/stdlib). |
| C3 | Level 3 testing — coverage must not decrease | **PARTIAL** | Good coverage exists but `system_requirements` class has no dedicated spec file. No coverage enforcement tooling observed in CI. |
| C4 | Standard linters available | **PASS** | puppet-lint, rubocop, yamllint, metadata_lint all present in CI. |

**Remediation**:
- Add `spec/classes/system_requirements_spec.rb`.
- Add SimpleCov or equivalent coverage tracking to CI with a coverage floor.

---

### Area D — Security Boundaries

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| D1 | Deny-list for sensitive files | **PASS** | No sensitive file patterns present in the module. |
| D2 | Read-only allowlisted network endpoints | **PASS** | Module only fetches from OpenProject APT repos (well-known). |
| D3 | CI/CD modification flagging | **PASS** | `.gitlab-ci.yml` exists and is versioned. |
| D4 | Production data advisory | **PASS** | No production data included. |

No issues found.

---

### Area E — Scope Limitations

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| E1 | Protected files are read-only | **PASS** | `LICENSE.md` correctly identified as protected/read-only. |
| E2 | No unneeded protected files | **PASS** | Standard set. |
| E3 | No AI repo creation on protected orgs | **N/A** | This repo already exists. |
| E4 | Deletions flagged | **N/A** | No deletions in scope. |

**Note**: `GOVERNANCE.md` does not exist. While not strictly required at Tier 2, it is a governance-critical file that would strengthen the module's compliance posture.

---

### Area F — Accountability

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| F1 | Submitter bears primary responsibility | **N/A** | Process requirement. |
| F2 | Configurable logging | **N/A** | Infrastructure concern. |
| F3 | Enhanced incident response | **N/A** | Process requirement. |
| F4 | No delegation defense | **N/A** | Process requirement. |

No module-level issues.

---

### Area G — Data Handling & Privacy

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| G1-G4 | AI provider vetting, PII handling, retention | **N/A** | Process/infrastructure requirements. |

No module-level issues.

---

### Area H — Community Consent & Opt-out

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| H1 | Repos can tighten but not weaken policy | **N/A** | No repo-level overrides detected. |
| H2 | Inline/config opt-out markers | **N/A** | None present (no opt-out needed). |

No issues found.

---

### Area I — Contribution Quality & Anti-Spam

| Rule | Requirement | Status | Finding |
|------|-------------|--------|---------|
| I1 | AI contributions must meet human bar | **N/A** | Quality appears high. |
| I2 | Rate limiting (5 AI PRs/week/contributor/repo) | **N/A** | Process requirement. |
| I3 | Fully autonomous contributions not accepted (Tier 2) | **ATTENTION** | Future AI contributions must have human review. |
| I4 | Five-point meaningful review | **N/A** | Process requirement for reviewers. |

---

## 2. Puppet Module Quality Gaps

### High Priority

#### 2.1 No Service Management Class

**Impact**: The module installs and configures OpenProject but does not manage the service lifecycle.

**Missing**:
- `manifests/service.pp` — manage `openproject` service (enable, ensure running)
- Service restart on configuration change (notify from `openproject::configure`)
- Standard Puppet ordering: `install -> config -> service`

**Current chain**: `system_requirements -> repository -> install -> configure` (stops at configure)

#### 2.2 No RHEL/CentOS/Rocky/AlmaLinux Support

**Impact**: Significantly limits adoption. OpenProject provides RPM repositories.

**Missing**:
- `data/os/RedHat.yaml` — yum repository configuration
- YUM/DNF repo management in `repository.pp`
- RPM-specific system requirement packages
- `metadata.json` entries for RHEL-family operating systems

#### 2.3 No Ubuntu Support

**Impact**: Ubuntu is in the Debian family and OpenProject supports it. Low-effort addition.

**Missing**:
- `data/os/Ubuntu.yaml` (or shared Debian family data)
- `metadata.json` entries for Ubuntu versions

### Medium Priority

#### 2.4 Missing `system_requirements_spec.rb`

4 of 5 classes have dedicated spec files. `openproject::system_requirements` only has indirect coverage through the main class spec.

#### 2.5 No Custom Facts

A fact like `openproject_version` would enable:
- Conditional logic in profiles
- PuppetDB inventory/reporting
- Upgrade orchestration decisions

#### 2.6 No Bolt Plans

Bolt tasks exist (backup/restore) but no orchestrated plans for common workflows:
- Backup-upgrade-restore-on-failure
- Health check after configuration change
- Rolling upgrades across node groups

#### 2.7 No Upgrade/Migration Path

No class, task, or documentation for handling major version upgrades (e.g., 16 → 17). The `reconfigure` exec exists but full upgrade workflows need more orchestration.

#### 2.8 Debian 13 Inconsistency

A Beaker nodeset exists for Debian 13 (`debian13-libvirt.yaml`) but Debian 13 is not listed in `metadata.json` `operatingsystem_support`.

### Low Priority

#### 2.9 No `CONTRIBUTING.md`

Standard for community/Voxpupuli modules. Should describe contribution workflow, testing requirements, and coding standards.

#### 2.10 No `examples/` Directory

Puppet Forge convention. Runnable `.pp` example manifests complement the README examples and are used by some validation tools.

#### 2.11 No GitHub Actions CI

Module has GitLab CI only. Voxpupuli modules on GitHub need `.github/workflows/` configuration. Required if the module moves to the Voxpupuli GitHub organization.

#### 2.12 No PDK Compatibility

Deliberate removal, but limits users who rely on `pdk validate` / `pdk test unit` workflows.

#### 2.13 No Defined Types for Granular Configuration

All configuration goes through a single `installer_dat_contents` hash. No way to manage individual configuration keys or extend configuration from profiles without overriding the entire hash.

---

## 3. Summary Matrix

### OpenVox MCP Compliance Summary

| Area | Name | Pass | Fail | Partial | N/A |
|------|------|------|------|---------|-----|
| A | Attribution & Disclosure | 0 | 3 | 0 | 1 |
| B | License Compliance | 1 | 3 | 1 | 1 |
| C | Coding Standards | 3 | 0 | 1 | 0 |
| D | Security Boundaries | 4 | 0 | 0 | 0 |
| E | Scope Limitations | 2 | 0 | 0 | 2 |
| F | Accountability | 0 | 0 | 0 | 4 |
| G | Data Handling & Privacy | 0 | 0 | 0 | 4 |
| H | Community Consent | 0 | 0 | 0 | 2 |
| I | Contribution Quality | 0 | 0 | 0 | 4 |
| **Total** | | **10** | **6** | **2** | **18** |

### Top Remediation Priorities

| # | Item | Type | Effort |
|---|------|------|--------|
| 1 | Add SPDX headers to all source files | MCP compliance (B1) | Low |
| 2 | Create `.ai-provenance.yml` | MCP compliance (B3) | Low |
| 3 | Add `Signed-off-by` to future commits | MCP compliance (B1) | Low |
| 4 | Add AI disclosure trailers to future commits | MCP compliance (A1-A4) | Low |
| 5 | Create `manifests/service.pp` | Module quality | Medium |
| 6 | Add `spec/classes/system_requirements_spec.rb` | Module quality (C3) | Low |
| 7 | Add Ubuntu support | Module quality | Low-Medium |
| 8 | Add RHEL family support | Module quality | Medium-High |
| 9 | Add `GOVERNANCE.md` | MCP compliance (E) | Low |
| 10 | Add `CONTRIBUTING.md` | Module quality | Low |

---

## 4. Session Actions & Decisions (2026-03-01)

### 4.1 License Switch Decision

**Decision**: Switch from `GPL-3.0-or-later` to `GPL-3.0-only`.

**Rationale**: `GPL-3.0-only` is the OpenVox-preferred license (Area B). Since this is
a new module (v1.0.0) with no downstream consumers relying on the `-or-later` grant,
there is no compatibility cost. The `LICENSE.md` file body (GPLv3 full text) is
identical for both SPDX identifiers — only metadata references change.

**Changes made**:
- `metadata.json`: `"license": "GPL-3.0-or-later"` → `"license": "GPL-3.0-only"`
- All SPDX headers use `GPL-3.0-only`

### 4.2 SPDX Header Additions

**Files modified** (20 files):

| Category | Files | Header Style |
|----------|-------|--------------|
| Puppet manifests (5) | `manifests/init.pp`, `configure.pp`, `install.pp`, `repository.pp`, `system_requirements.pp` | `# SPDX-...` prepended before `@summary` |
| Ruby tasks (2) | `tasks/backup.rb`, `tasks/restore.rb` | `# SPDX-...` after `frozen_string_literal`, before doc comment |
| EPP templates (3) | `templates/env.epp`, `installer.dat.epp`, `enterprise_token.rb.epp` | `<%# SPDX-... -%>` prepended before content (trailing `-%>` trims newline to avoid altering rendered output) |
| Spec files (9) | `spec/classes/*.rb`, `spec/tasks/*.rb`, `spec/acceptance/openproject_spec.rb`, `spec/spec_helper_local.rb`, `spec/spec_helper_acceptance.rb` | `# SPDX-...` after `frozen_string_literal`, before `require` |

**Files intentionally skipped**:

| File | Reason |
|------|--------|
| `spec/spec_helper.rb` | Modulesync-managed — SPDX changes belong in `modulesync_config` |
| `Gemfile` | Modulesync-managed |
| `Rakefile` | Modulesync-managed |
| `metadata.json` | JSON format — no comment syntax for SPDX headers |
| `data/*.yaml` | Data files — SPDX headers not standard practice for YAML hieradata |

### 4.3 Protected File Constraints

The following files are protected by MCP policy (AI cannot write them):

#### `.ai-provenance.yml` — Template for Human to Create

```yaml
# .ai-provenance.yml — AI Provenance Bibliography
# Required by OpenVox MCP Policy Area B3
#
# This file documents AI tool involvement in the puppet-openproject module.

version: "1.0"
module: puppet-openproject
created: "2026-03-01"

contributions:
  - date: "2026-03-01"
    branch: mcp-compliance
    ai_tool: "Claude Opus 4.6 (Anthropic)"
    ai_role: AI-Co-Author
    contributor: "Hugo Antonio Sepulveda Manriquez <hugo@neatnerds.be>"
    description: >
      MCP compliance remediation: added SPDX headers to all source files,
      switched license from GPL-3.0-or-later to GPL-3.0-only, updated
      metadata.json, and documented compliance decisions.
    files_modified:
      - metadata.json
      - manifests/*.pp
      - tasks/*.rb
      - templates/*.epp
      - spec/**/*.rb
      - openvox_mcp_findings.md
    sources:
      - type: project_code
        reference: "Existing puppet-openproject module source"
      - type: documentation
        reference: "OpenVox AI Governance Policy v1.0.0-draft"
```

#### `GOVERNANCE.md` — Template for Human to Create

```markdown
# Governance — puppet-openproject

## AI Policy

This module follows the [OpenVox AI Governance Policy](https://github.com/OpenVoxProject/openvox-mcp)
at **Tier 2** (Voxpupuli Community).

### Requirements for Contributors

1. **AI Disclosure**: All commits involving AI assistance must include an appropriate
   trailer (`AI-Generated-By`, `AI-Co-Author`, `AI-Assisted-By`, or `AI-Reviewed-By`).
2. **DCO Sign-off**: All commits must include a `Signed-off-by` trailer
   (`git commit -s`).
3. **Human Review**: All AI-involved contributions require human review by a different
   person before merge (Tier 2 requirement).
4. **SPDX Headers**: All new source files must include `SPDX-FileCopyrightText` and
   `SPDX-License-Identifier: GPL-3.0-only` headers.

### License

This module is licensed under `GPL-3.0-only`. See `LICENSE.md` for the full text.

### AI Provenance

AI involvement in this module is tracked in `.ai-provenance.yml`.
```

### 4.4 Human Post-Session Tasks

The following tasks **must be completed by the human maintainer** (Hugo):

1. **Create `GOVERNANCE.md`** — Copy template from section 4.3 above. This is a
   protected file that AI cannot write.
2. **Create `.ai-provenance.yml`** — Copy template from section 4.3 above. This is a
   protected file that AI cannot write.
3. **Add `Signed-off-by` trailer** — When committing the compliance changes, use
   `git commit -s` to add the DCO sign-off with your identity.
4. **Review all changes** — Tier 2 requires human review of all AI-involved work
   before merge.

### 4.5 AI Disclosure

This session's work was performed by **Claude Opus 4.6 (Anthropic)** in an
`AI-Co-Author` capacity. The commit trailer should be:

```
AI-Co-Author: Claude Opus 4.6 (Anthropic) <noreply@anthropic.com>
```

### 4.6 Existing Commit Gap

The 5 existing commits on this branch do not carry AI disclosure trailers or DCO
sign-off. Retroactively adding these would require history rewriting, which is not
recommended for a branch that may have been shared. Instead:

- This gap is acknowledged and documented here.
- All future commits will comply with Areas A and B.
- The `.ai-provenance.yml` file (once created) serves as retroactive disclosure.
