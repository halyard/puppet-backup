# @summary Define a specific backup repo
#
# @param source sets the source directory for this backup
# @param target sets the rclone destination for this backup
# @param watchdog_url sets the URL to ping after a successful backup
# @param password sets the restic repository password
# @param keep_dailies sets how many daily backups to keep
# @param keep_weeklies sets how many weekly backups to keep
# @param environment sets extra environment variables for backup
# @param rclone_config sets the rclone backend configuration file contents
# @param args sets extra restic command line flags
define backup::repo (
  String $source,
  String $target,
  String $watchdog_url,
  String $password,
  Integer $keep_dailies = 5,
  Integer $keep_weeklies = 4,
  Hash[String, String] $environment = {},
  Array[String] $args = ['--cleanup-cache', '-orclone.args=serve restic --addr 127.0.0.1:0 --stdio --use-mmap'],
  Optional[String] $rclone_config = undef,
) {
  include backup

  $init_env = [
    "RESTIC_REPOSITORY=${target}",
    "RESTIC_PASSWORD=${password}",
    "RCLONE_CONFIG=/etc/restic/rclone/${name}",
  ] + $environment.map |$key, $value| { "${key}=${value}" }

  file { "/etc/restic/${name}":
    ensure  => file,
    content => template('backup/environment.erb'),
  }

  file { "/etc/restic/environment/${name}":
    ensure  => file,
    content => template('backup/environment.erb'),
  }

  -> exec { "restic-init-${name}":
    command     => '/usr/bin/restic init',
    environment => $init_env,
    unless      => '/usr/bin/restic snapshots',
  }

  -> service { "restic@${name}.timer":
    ensure => running,
    enable => true,
  }

  file { "/etc/restic/environment/${name}.source":
    ensure  => file,
    content => template('backup/environment.source.erb'),
  }

  if $rclone_config != undef {
    file { "/etc/restic/rclone/${name}":
      ensure  => file,
      content => $rclone_config,
      before  => Exec["restic-init-${name}"],
    }
  }

  service { "prune-restic@${name}.timer":
    ensure => stopped,
    enable => false,
  }
}
