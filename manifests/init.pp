# @summary Openproject Main class
#
# This is the public class that sets up openproject
#
# @param release_major
#   The major release number of openproject, affects major version repo and 
#   package
#
# @param enable_full_text_extract
#   When set to true, this will provide the required dependencies for full-text
#   extraction of attachments. 
class openproject (
  Integer $release_major,
  Boolean $enable_full_text_extract,
) {
  unless $facts['os']['name'] == 'Debian' {
    fail('Unsupported Operating system!')
  }
  unless $facts['os']['architecture'] == 'amd64' {
    fail('Unsupported hardware achitecture!')
  }

  contain openproject::system_requirements
  contain openproject::repository
  contain openproject::install
  contain openproject::configure
  contain openproject::service

  Class['openproject::system_requirements']
  -> Class['openproject::repository']
  -> Class['openproject::install']
  -> Class['openproject::configure']
  -> Class['openproject::service']
}
