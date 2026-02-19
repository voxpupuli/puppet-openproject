# openproject

TL;DR:

* Installs, configures and runs OpenProject.


## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
    * [What openproject affects](#what-openproject-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with openproject](#beginning-with-openproject)
1. [Usage](#usage)
    * [Parameters reference](#parameters-reference)
    * [Hiera examples](#hiera-examples)
1. [Testing](#testing)
1. [Reference](#reference)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

Installs and configures openproject

## Setup

### What openproject affects

* apt sources
* packages form software repository
* database configurations

### Setup Requirements

* puppetlabs-apt
* puppetlabs-stdlib

### Beginning with openproject

## Usage

The recommended way to use this module is via Hiera (automatic parameter
lookup). Include the class in a manifest or role and let Hiera supply
the configuration:

```puppet
include openproject
```

All parameters have sensible defaults. A bare `include openproject` with
no Hiera overrides installs OpenProject 17 with Apache, local PostgreSQL,
and memcached on the node's FQDN.

### Parameters reference

#### `openproject` (public)

The only class you include directly. All other classes are private and
managed internally.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `release_major` | `Integer` | `17` | Major release version. Determines which package repository is configured (e.g. `stable/17`). |
| `enable_full_text_extract` | `Boolean` | `false` | When `true`, installs `catdoc`, `unrtf`, `poppler-utils` and `tesseract-ocr` for full-text extraction of attachments. |

#### `openproject::install` (private)

Controls the OpenProject package resource.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `package_name` | `String` | `'openproject'` | Name of the package to install. |
| `package_ensure` | `String` | `'present'` | Desired package state. Accepts any value valid for the `ensure` attribute of a Puppet `package` resource (`'present'`, `'latest'`, or a version string). |
| `package_hold` | `Enum['none', 'hold']` | `'none'` | Apt mark state. Set to `'hold'` to prevent the package from being upgraded. |

#### `openproject::repository` (private)

Manages the APT source for the OpenProject package repository. The
`release_major` parameter is passed down from the public class so it
always reflects the value you set on `openproject::release_major`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apt_sources` | `Hash` | *(OS-specific, see `data/os/Debian.yaml`)* | Hash of parameters passed to `apt::source` (excluding `location`, which is constructed from `release_major`). Contains the repository comment, signing key, release, and repos. |
| `release_major` | `Integer` | `17` | Inherited from the public class. Used to build the repository URL `https://dl.packager.io/srv/deb/opf/openproject/stable/<release_major>/debian`. |

#### `openproject::configure` (private)

Manages the OpenProject configuration directory, the `installer.dat`
answer file, and optional shell environment overrides.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `root_config_dir` | `Stdlib::Absolutepath` | `'/etc/openproject'` | Absolute path to the OpenProject configuration directory. |
| `file_mode` | `String` | `'0640'` | File permission mode applied to managed configuration files (`installer.dat.puppet`, `conf.d/env`). |
| `installer_dat_contents` | `Hash` | *(see below)* | Key/value pairs that populate the `installer.dat` answer file for the OpenProject unattended installer. **Note:** when using eyaml for secrets, the entire hash must reside in the Hiera file that supplies the encrypted values. |
| `timeout` | `Integer` | `900` | Timeout in seconds for the `openproject configure` command. Increase this for slow hardware or large migrations. |
| `logoutput` | `String` | `'true'` | Controls log output of the configure exec. Accepts `'true'`, `'false'`, or `'on_failure'`. |
| `environment_contents` | `Optional[Hash]` | `undef` | When set, writes a shell environment file to `<root_config_dir>/conf.d/env` and triggers a reconfiguration. Used for advanced settings outside of `installer.dat`. |

Default `installer_dat_contents`:

```yaml
'memcached/autoinstall': 'install'
'openproject/admin_email': "administrator@<fqdn>"
'openproject/default_language': 'en'
'openproject/edition': 'default'
'postgres/addon_version': 'v1'
'postgres/autoinstall': 'install'
'postgres/db_name': 'openproject'
'postgres/db_password': 'SuperSecretStringSuchSecure'
'postgres/db_username': 'openproject'
'postgres/dbhost': 'localhost'
'postgres/dbport': 5432
'postgres/retry': 'retry'
'repositories/git-install': 'skip'
'repositories/svn-install': 'skip'
'server/autoinstall': 'install'
'server/hostname': "<fqdn>"
'server/server_path_prefix': ''
'server/ssl': 'no'
'server/variant': 'apache2'
```

#### Private lookup keys

These keys are consumed via `lookup()` and are not class parameters. They
can be overridden in Hiera but should rarely need changing.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `openproject::system_user` | `String` | `'openproject'` | System user that owns configuration files. |
| `openproject::system_group` | `String` | `'openproject'` | System group that owns configuration files. |
| `openproject::system_requirements` | `Array` | `['apt-transport-https', 'ca-certificates', 'wget', 'gpg']` | System packages installed before the repository is configured. |
| `openproject::full_text_extract_packages` | `Array` | `['catdoc', 'unrtf', 'poppler-utils', 'tesseract-ocr']` | Packages installed when `enable_full_text_extract` is `true`. |

### Hiera examples

#### Minimal setup

No overrides required. Every parameter has a default:

```yaml
# empty — all defaults apply
```

**Effect:** Installs OpenProject 17 from the `stable/17` repository,
configures Apache as reverse proxy with local PostgreSQL and memcached,
listens on the node's FQDN over plain HTTP.

#### Selecting a different major release

```yaml
openproject::release_major: 15
```

**Effect:** Configures the APT source to
`https://dl.packager.io/srv/deb/opf/openproject/stable/15/debian` and
installs the latest OpenProject 15.x package.

#### Pinning a specific package version

```yaml
openproject::install::package_ensure: '14.5.0-1'
openproject::install::package_hold: 'hold'
```

**Effect:** Installs exactly version `14.5.0-1` of the `openproject`
package and marks it as `hold` via `apt-mark`, preventing unattended
upgrades from changing it.

#### Enabling full-text extraction

```yaml
openproject::enable_full_text_extract: true
```

**Effect:** Installs `catdoc`, `unrtf`, `poppler-utils`, and
`tesseract-ocr` alongside OpenProject, enabling full-text search of
uploaded attachments (PDF, Word, RTF, etc.).

#### Customising the installer answer file

The `installer_dat_contents` hash is merged as a whole — you must supply
every key you want present, not just the ones you change:

```yaml
openproject::configure::installer_dat_contents:
  'memcached/autoinstall': 'install'
  'openproject/admin_email': 'admin@corp.example.com'
  'openproject/default_language': 'de'
  'openproject/edition': 'default'
  'postgres/addon_version': 'v1'
  'postgres/autoinstall': 'install'
  'postgres/db_name': 'openproject'
  'postgres/db_password': 'ChangeMeToSomethingSecure'
  'postgres/db_username': 'openproject'
  'postgres/dbhost': 'localhost'
  'postgres/dbport': 5432
  'postgres/retry': 'retry'
  'repositories/git-install': 'install'
  'repositories/svn-install': 'skip'
  'server/autoinstall': 'install'
  'server/hostname': 'projects.corp.example.com'
  'server/server_path_prefix': '/projects'
  'server/ssl': 'yes'
  'server/variant': 'apache2'
```

**Effect:** Configures OpenProject with SSL enabled, German as the
default language, a custom hostname and path prefix
(`https://projects.corp.example.com/projects`), Git repository
integration enabled, and a proper database password. On first run
Puppet writes `installer.dat` and runs `openproject configure`;
subsequent runs only reconfigure when the content changes.

#### Setting environment variables (SMTP example)

```yaml
openproject::configure::environment_contents:
  EMAIL_DELIVERY_METHOD: '"smtp"'
  SMTP_ADDRESS: '"smtp.corp.example.com"'
  SMTP_PORT: '"587"'
  SMTP_DOMAIN: '"corp.example.com"'
  SMTP_AUTHENTICATION: '"plain"'
  SMTP_USER_NAME: '"openproject@corp.example.com"'
  SMTP_PASSWORD: '"TopSecretMailPassword"'
  SMTP_ENABLE_STARTTLS_AUTO: '"true"'
```

**Effect:** Creates `/etc/openproject/conf.d/env` containing the
above key/value pairs (one per line) and triggers an
`openproject configure` run. Values must be double-quoted inside the
YAML string because OpenProject reads them as shell variables.

#### Increasing the configure timeout

```yaml
openproject::configure::timeout: 1800
```

**Effect:** Raises the timeout for the `openproject configure` exec from
the default 900 seconds to 1800 seconds (30 minutes). Useful for slow
hardware or initial runs that include database migrations.

#### Combined production example

```yaml
# Release and package control
openproject::release_major: 17
openproject::install::package_ensure: '17.1.0-1'
openproject::install::package_hold: 'hold'
openproject::enable_full_text_extract: true

# Installer answer file
openproject::configure::installer_dat_contents:
  'memcached/autoinstall': 'install'
  'openproject/admin_email': 'admin@corp.example.com'
  'openproject/default_language': 'en'
  'openproject/edition': 'default'
  'postgres/addon_version': 'v1'
  'postgres/autoinstall': 'skip'
  'postgres/db_name': 'openproject_prod'
  'postgres/db_password': 'ENC[PKCS7,...]'
  'postgres/db_username': 'openproject'
  'postgres/dbhost': 'db.corp.example.com'
  'postgres/dbport': 5432
  'postgres/retry': 'retry'
  'repositories/git-install': 'install'
  'repositories/svn-install': 'skip'
  'server/autoinstall': 'install'
  'server/hostname': 'projects.corp.example.com'
  'server/server_path_prefix': ''
  'server/ssl': 'yes'
  'server/variant': 'apache2'

# SMTP via environment
openproject::configure::environment_contents:
  EMAIL_DELIVERY_METHOD: '"smtp"'
  SMTP_ADDRESS: '"smtp.corp.example.com"'
  SMTP_PORT: '"587"'
  SMTP_AUTHENTICATION: '"plain"'
  SMTP_USER_NAME: '"openproject@corp.example.com"'
  SMTP_PASSWORD: '"ENC[PKCS7,...]"'
  SMTP_ENABLE_STARTTLS_AUTO: '"true"'

# Timeouts
openproject::configure::timeout: 1800
```

**Effect:** Pins OpenProject 17.1.0-1 with apt hold, enables full-text
extraction, points PostgreSQL at an external database server (skipping
local auto-install), enables SSL and Git integration, configures SMTP
delivery via environment variables, and allows 30 minutes for the
initial `openproject configure` run. Secrets are eyaml-encrypted.

## Testing

### Unit testing

* bundle exec rake test

### Acceptance testing with beaker

To run acceptance tests:

# Debian 12 (Bookworm)
BEAKER_SETFILE=spec/acceptance/nodesets/debian12-libvirt.yaml bundle exec rake beaker

# Debian 11 (Bullseye)
BEAKER_SETFILE=spec/acceptance/nodesets/debian11-libvirt.yaml bundle exec rake beaker

# Keep VM for debugging
BEAKER_DESTROY=no BEAKER_SETFILE=spec/acceptance/nodesets/debian12-libvirt.yaml bundle exec rake beaker

If you don't have the generic Debian boxes yet, download them first:

vagrant box add debian/bullseye64 --provider libvirt
vagrant box add debian/bookworm64 --provider libvirt

## Reference

* [Openproject.org website documentation](https://www.openproject.org/docs)
* [installer.dat example](https://git.coop/webarch/openproject/-/issues/1)

## Limitations

* x86_64 architecture only
* Only Debian distribution is supported
* Only use this when using a dedicated VM
* no advanced configuration (yet)
* No tasks (yet)

## Development

* Make a fork
* Do your thing, please include tests.
* Once done, squash all your commits into one.
* Do pull request.
* ???
* BASTELFREAK NO!
* ???
* Get congratz or get feedback
