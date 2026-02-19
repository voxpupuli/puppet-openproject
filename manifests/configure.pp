# @summary Configures openproject
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
  }

  # https://stackoverflow.com/a/45616735
  file { "${root_config_dir}/installer.dat":
    ensure  => 'file',
    content => epp('openproject/installer.dat.epp', { installer_dat_contents => $installer_dat_contents }),
    mode    => $file_mode,
    require => File[$root_config_dir],
    notify  => Exec['configure openproject'],
  }

  unless $environment_contents == undef {
    file { "${root_config_dir}/conf.d":
      ensure  => 'directory',
      mode    => '0750',
      require => File[$root_config_dir],
    }

    file { "${root_config_dir}/conf.d/env":
      ensure  => 'file',
      content => epp('openproject/env.epp', { environment_contents => $environment_contents }),
      mode    => $file_mode,
      require => File["${root_config_dir}/conf.d"],
      notify  => Exec['configure openproject'],
    }
  }

  exec { 'configure openproject':
    command     => '/usr/bin/openproject configure',
#    subscribe   => [ File["${root_config_dir}/installer.dat"],
#                     File["${root_config_dir}/conf.d/env"],
#                   ],
    timeout     => $timeout,
    logoutput   => $logoutput,
    refreshonly => true,
  }
}
