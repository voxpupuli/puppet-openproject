# @summary installs openproject from package
#
# @param package_name
#   The name of the openproject package
#
# @param package_ensure
#   The ensure value for the openproject package
#
# @param package_hold
#   The apt mark state for the openproject package
#
# @api private
class openproject::install (
  String $package_name,
  String $package_ensure,
  Enum['none', 'hold'] $package_hold,
) {
  package { $package_name:
    ensure  => $package_ensure,
    mark    => $package_hold,
    require => Class['openproject::repository'],
  }
}
