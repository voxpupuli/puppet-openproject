# SPDX-FileCopyrightText: 2026 Vox Pupuli
# SPDX-License-Identifier: GPL-3.0-only
#
# @summary installs openproject from package
#
# @param package_name
#   The name of the openproject package
#
# @param package_ensure
#   The ensure value for the openproject package
#
# @param package_hold
#   The apt mark state for the openproject package (Debian only)
#
# @api private
class openproject::install (
  String $package_name,
  String $package_ensure,
  Enum['none', 'hold'] $package_hold,
) {
  $_package_attrs = $facts['os']['family'] ? {
    'Debian' => { mark => $package_hold },
    default  => {},
  }

  package { $package_name:
    ensure  => $package_ensure,
    require => Class['openproject::repository'],
    *       => $_package_attrs,
  }
}
