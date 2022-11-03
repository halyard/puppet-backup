# @summary Define a specific backup repo
#
# @param source sets the source directory for this backup
# @param target sets the rclone destination for this backup
# @param watchdog_url sets the URL to ping after a successful backup
# @param password sets the restic repository password
# @param environment sets extra environment variables for backup
define backup::repo (
  String $source,
  String $target,
  String $watchdog_url,
  String $password,
  Hash[String, String] $environment = {},
) {
  include backup

  $init_env = [
    "RESTIC_REPOSITORY=${target}",
    "RESTIC_PASSWORD=${password}",
  ] + $environment.map |$key, $value| { "${key}=${value}" }

  file { "/etc/restic/${name}":
    ensure  => file,
    content => template('backup/environment.erb'),
  }

  -> exec { '/usr/bin/restic init':
    environment => $init_env,
    unless      => '/usr/bin/restic snapshots',
  }

  -> service { "restic@${name}.timer":
    ensure => running,
    enable => true,
  }
}
