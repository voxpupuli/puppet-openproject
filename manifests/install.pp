# @summary installs openproject from package
#
# @api private
class openproject::install {
  package { lookup('openproject::package_name'):
    ensure => present,
  }
}
