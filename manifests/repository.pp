# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only
#
# @summary sets up repository
#
# @param apt_sources
#   Hash of apt::source parameters (excluding location) for the
#   OpenProject repository. Only used on Debian-family systems.
#
# @param yum_config
#   Hash of yumrepo parameters (excluding baseurl) for the
#   OpenProject repository. Only used on RedHat-family systems.
#
# @param release_major
#   The major release number of OpenProject, used to construct the
#   repository URL
#
# @api private
class openproject::repository (
  Integer        $release_major,
  Optional[Hash] $apt_sources = undef,
  Optional[Hash] $yum_config  = undef,
) {
  case $facts['os']['family'] {
    'Debian': {
      require apt

      apt::source { 'openproject':
        *      => $apt_sources + {
          'location' => "https://dl.packager.io/srv/deb/opf/openproject/stable/${release_major}/debian",
        },
        notify => Exec['apt_update'],
      }
    }
    'RedHat': {
      yumrepo { 'openproject':
        *       => $yum_config + {
          'baseurl' => "https://dl.packager.io/srv/rpm/opf/openproject/stable/${release_major}/el/\$releasever/\$basearch",
        },
      }
    }
    default: {
      fail("Unsupported OS family: ${facts['os']['family']}")
    }
  }
}
