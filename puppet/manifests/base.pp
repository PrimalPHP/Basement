
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }


class system-update {

    file { "/etc/apt/sources.list.d/dotdeb.list":
        owner  => root,
        group  => root,
        mode   => 664,
        source => "/vagrant/conf/apt/dotdeb.list",
    }

    exec { 'dotdeb-apt-key':
        cwd     => '/tmp',
        command => "wget http://www.dotdeb.org/dotdeb.gpg -O dotdeb.gpg &&
                    cat dotdeb.gpg | apt-key add -",
        unless  => 'apt-key list | grep dotdeb',
        require => File['/etc/apt/sources.list.d/dotdeb.list'],
        notify  => Exec['apt-get update'],
    }

  exec { 'apt-get update':
    command => 'apt-get update',
  }

  $sysPackages = [ "build-essential" ]
  package { $sysPackages:
    ensure => "installed",
    require => Exec['apt-get update'],
  }
}

class nginx {

  package { 'nginx':
  	ensure => present,
  	require => Exec['apt-get update'],
  }

  service { 'nginx':
  	ensure => running,
  	require => Package['nginx'],
  }

  file { "/etc/nginx/sites-available/php-fpm":
    owner  => root,
    group  => root,
    mode   => 664,
    source => "/vagrant/conf/nginx/default",
    require => Package["nginx"],
    notify => Service["nginx"],
  }

  file { "/etc/nginx/sites-enabled/default":
    owner  => root,
    ensure => link,
    target => "/etc/nginx/sites-available/php-fpm",
    require => Package["nginx"],
    notify => Service["nginx"],
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

class php-fpm {

    package { 'php5-cli':
      ensure => present,
      require => Exec['apt-get update']
    }

    file { "/etc/php5/conf.d/custom.ini":
        owner  => root,
        group  => root,
        mode   => 664,
        require => Package['php5-cli'],
        source => "/vagrant/conf/php/custom.ini",
        notify => Service['php5-fpm'],
    }

    file { "/etc/php5/fpm/pool.d/www.conf":
        owner  => root,
        group  => root,
        mode   => 664,
        require => Package['php5-fpm'],
        source => "/vagrant/conf/php-fpm/www.conf",
        notify => Service['php5-fpm'],
    }

    package { [
      'php5-fpm',
      'php5-mysqlnd',
      'php5-gd',
      'php5-sqlite',
      'php5-xdebug',
      'php5-apc',
      'php5-mcrypt',
      'php5-curl',
      'php5-memcache'
      ]:
        ensure => 'present',
        require => Package['php5-cli'],
    }

    service { 'php5-fpm':
        ensure => running,
        require => Package['php5-fpm'],
        notify => Service['php5-fpm'],
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
include nginx
include php-fpm

