## @summary sets uprepository
#
# @api private
class openproject::repository {
  require apt

  apt::source {
    'openproject':
      *      => lookup('openproject::apt::sources.openproject'),
      notify => Exec['apt_update'],
      ;
  }
}
