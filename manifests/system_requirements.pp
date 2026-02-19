# @summary sets up system requirements
#
# @api private
class openproject::system_requirements {
  package { lookup('openproject::system_requirements'):
    ensure => 'present',
  }

  if $openproject::enable_full_text_extract {
    package { lookup('openproject::full_text_extract_packages'):
      ensure => 'present',
    }
  }
}
