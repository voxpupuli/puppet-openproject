# @summary sets up repository
#
# @param apt_sources
#   Hash of apt::source parameters (excluding location) for the
#   OpenProject repository
#
# @param release_major
#   The major release number of OpenProject, used to construct the
#   repository URL
#
# @api private
class openproject::repository (
  Hash    $apt_sources,
  Integer $release_major,
) {
  require apt

  apt::source { 'openproject':
    *      => $apt_sources + {
      'location' => "https://dl.packager.io/srv/deb/opf/openproject/stable/${release_major}/debian",
    },
    notify => Exec['apt_update'],
  }
}
