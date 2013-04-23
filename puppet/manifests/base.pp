
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


class system-update {

  exec { 'apt-get update':
    command => 'apt-get update',
  }

  $sysPackages = [ "build-essential" ]
  package { $sysPackages:
    ensure => "installed",
    require => Exec['apt-get update'],
  }
}

class apache2 {

  package { "apache2":
    ensure  => present,
    require => Exec["apt-get update"],
  }

  service { "apache2":
    ensure  => "running",
    require => Package["apache2"],
  }

  file { '/etc/apache2/sites-enabled/000-default':
    ensure => link,
    target => "/vagrant/puppet/conf/apache/000-default",
    notify => Service['apache2'],
    force  => true
  }

  file { '/etc/apache2/mods-enabled/rewrite.load':
    ensure => link,
    target => "/etc/apache2/mods-available/rewrite.load",
    notify => Service['apache2']
  }

}

class mysql {
  package { "mysql-server":
    ensure => installed,
    require => Exec['apt-get update']
  }

  service { 'mysql':
      ensure => 'running',
      enable => true,
      provider   => 'upstart',
      hasrestart => true,
      hasstatus => true,
      subscribe => Package['mysql-server'],
  }

  exec { "set-mysql-password":
    unless  => "mysql -uroot -proot",
    path    => ["/bin", "/usr/bin"],
    command => "mysqladmin -uroot password root",
    require => Service["mysql"],
  }

  # Equivalent to /usr/bin/mysql_secure_installation without providing or setting a password
  exec { 'mysql_secure_installation':
      command => '/usr/bin/mysql -uroot -proot -e "DELETE FROM mysql.user WHERE User=\'\'; DROP DATABASE IF EXISTS test; FLUSH PRIVILEGES;" mysql',
      require => Exec['set-mysql-password'],
  }

  exec { "create-database":
    unless  => "/usr/bin/mysql -uphp -pphp main",
    command => "/usr/bin/mysql -uroot -proot -e \"CREATE DATABASE IF NOT EXISTS main; GRANT ALL ON main.* to php@localhost IDENTIFIED BY 'php';\"",
    require => Exec["set-mysql-password"],
  }
}

class php {

    package { 'php5':
      ensure => present,
      require => Exec['apt-get update']
    }

    file { "/etc/php5/conf.d/custom.ini":
        owner  => root,
        group  => root,
        mode   => 664,
        require => Package['php5'],
        source => "/vagrant/puppet/conf/php/custom.ini",
        notify => Service['php5'],
    }

    package { [
      'php5-mysqlnd',
      'php5-sqlite',
      'php5-xdebug',
      'php5-mcrypt',
      'php5-curl'
      ]:
        ensure => 'present',
        require => Package['php5'],
    }

    service { 'php5':
        ensure => running,
        require => Package['php5'],
        notify => Service['php5'],
    }
}



class groups {
  group { "puppet":
      ensure => present,
  }
}


include groups
include system-update
include mysql
include apache2
include php
