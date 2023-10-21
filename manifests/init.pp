# @summary Configure backup tools
#
#
# @param frequency defines how often to run restic
# @param bootdelay defines how long to wait after boot for first run
# @param prunefrequency defines how often to run restic pruning
# @param prunebootdelay defines how long to wait after boot for first run of pruning
class backup (
  String $frequency = '86400',
  String $bootdelay = '600',
  String $prunefrequency = '172800',
  String $prunebootdelay = '3600',
) {
  package { ['restic', 'rclone']: }

  file { '/etc/systemd/system/restic@.service':
    ensure => file,
    source => 'puppet:///modules/backup/restic@.service',
  }

  file { '/etc/systemd/system/restic@.timer':
    ensure  => file,
    content => template('backup/restic@.timer.erb'),
  }

  file { '/etc/systemd/system/prune-restic@.service':
    ensure => file,
    source => 'puppet:///modules/backup/prune-restic@.service',
  }

  file { '/etc/systemd/system/prune-restic@.timer':
    ensure  => file,
    content => template('backup/prune-restic@.timer.erb'),
  }

  file { ['/etc/restic', '/etc/restic/environment/', '/etc/restic/rclone', '/var/lib/restic']:
    ensure => directory,
    mode   => '0700',
  }
}
