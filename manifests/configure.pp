# @summary Configures openproject
#
# @param root_config_dir
#   Absolute path String of the configuration directory
#   Default: '/etc/openproject'
#
# @param file_mode
#   ACL file mode Integer of the openproject configuration files
#   Default: 0640
#
# @param installer_dat_contents
#   Hash of configuration settings that make up for openproject's setup
#   In it's default setting it provides a basic install with the Apache
#   webserver as a default reverse proxy.
#   It should be noted that when using eyaml, the entire hash needs to be
#   inside your hieradata file where you configure secrets
#   Default: See 'data/common.yml' for defaults
#
# @param timeout
#   Integer value determining the timout for configuring and launching the
#   Openproject service. Depending on your installation you might want to
#   increase this.
#   Default: 600
#
# @param logoutput
#   String value allowing for logging output of the openproject setup
#   Default 'on_failure'
#
# @param environment_contents
#   Hash of shell environment keys/values that configure openproject outside
#   of 'installer.dat' configuration file. This is advanced configuration, be
#   sure to read on the openproject docmentation site for your version for more
#   information: https://www.openproject.org/docs/installation-and-operations/configuration/environment/
#   Default: undef
#
class openproject::configure (
  Stdlib::Absolutepath  $root_config_dir,
  String                $file_mode,
  Hash                  $installer_dat_contents,
  Integer               $timeout,
  String                $logoutput,
  Optional[Hash]        $environment_contents,
) {
  file { $root_config_dir:
    ensure => 'directory',
    mode   => '0750',
    owner  => lookup('openproject::system_user'),
    group  => lookup('openproject::system_group'),
  }

  unless $environment_contents == undef {
    file { "${root_config_dir}/conf.d":
      ensure  => 'directory',
      mode    => '0750',
      owner   => lookup('openproject::system_user'),
      group   => lookup('openproject::system_group'),
      require => File[$root_config_dir],
    }

    file { "${root_config_dir}/conf.d/env":
      ensure  => 'file',
      content => epp('openproject/env.epp', { environment_contents => $environment_contents }),
      mode    => $file_mode,
      owner   => lookup('openproject::system_user'),
      group   => lookup('openproject::system_group'),
      require => File["${root_config_dir}/conf.d"],
      notify  => Exec['reconfigure openproject'],
    }
  }

  # This....is a messy part, but sadly necessary
  # The openproject installer uses a dat file instead of any other structured
  # data format like YAML... (they had it!!!)
  # and.... it is needed to perform an unattended installation, basically
  # it is an answer file to a TUI installer.
  # Sadly, templating this is hard, especially when openproject has it's own
  # ideas of how to order things, oh and add whitelines in it...
  # So we have to trick it.
  #
  # We achieve this by having the template render an intermediary file and then
  # compare it semantically. this semantic comparison is achieved by sorting
  # the dat file after the 'openproject configure' command and cleaning it up
  # from any empty lines, so it matches the previously rendered intermediary
  # file.
  #
  #
  # Reference file holding the desired installer.dat state. We do not manage
  # installer.dat directly because 'openproject configure' rewrites it
  # (reordering/reformatting), which would cause a content diff on every
  # Puppet run and break idempotency.
  file { "${root_config_dir}/installer.dat.puppet":
    ensure  => 'file',
    content => epp('openproject/installer.dat.epp', { installer_dat_contents => $installer_dat_contents }),
    mode    => $file_mode,
    owner   => lookup('openproject::system_user'),
    group   => lookup('openproject::system_group'),
    require => File[$root_config_dir],
  }

  #
  # Initial configuration — only runs when installer.dat does not yet exist.
  #
  # Forgive the ugly exec
  exec { 'configure openproject':
    command   => "cp ${root_config_dir}/installer.dat.puppet ${root_config_dir}/installer.dat \
&& /usr/bin/openproject configure \
&& /usr/bin/sort -o ${root_config_dir}/installer.dat ${root_config_dir}/installer.dat \
&& /usr/bin/sed -i '/^$/d' ${root_config_dir}/installer.dat",
    creates   => "${root_config_dir}/installer.dat",
    provider  => 'shell',
    timeout   => $timeout,
    logoutput => $logoutput,
    require   => File["${root_config_dir}/installer.dat.puppet"],
  }

  # Reconfiguration — runs when the desired state (sorted reference file)
  # semantically differs from the actual installer.dat on disk, or when
  # notified by the env file.
  exec { 'reconfigure openproject':
    command   => "cp ${root_config_dir}/installer.dat.puppet ${root_config_dir}/installer.dat \
&& /usr/bin/openproject configure \
&& /usr/bin/sort -o ${root_config_dir}/installer.dat ${root_config_dir}/installer.dat \
&& /usr/bin/sed -i '/^$/d' ${root_config_dir}/installer.dat",
    onlyif    => "test -f ${root_config_dir}/installer.dat",
    unless    => "/bin/bash -c 'diff <(sort ${root_config_dir}/installer.dat.puppet) <(sort ${root_config_dir}/installer.dat)'",
    provider  => 'shell',
    timeout   => $timeout,
    logoutput => $logoutput,
    require   => [File["${root_config_dir}/installer.dat.puppet"], Exec['configure openproject']],
  }
}
