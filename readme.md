#Basement

A composer + vagrant boilerplate for building PHP applications.

##Ubuntu 12.04
The vagrant & puppet configuration will create an Ubuntu 12.04 64bit server running:

- PHP 5.4
- MySQL 5.5
- Nginx
- PHP-FPM

It will then install configuration making the `/app/www` into the web root, and route all requests for files that do not exist into `/app/www/index.php` (which includes `/app/main.php`).  Inside the VM, all these files will exist in the `/vagrant/` path.

Additionally, the following PHP modules are installed:

- php5-mysqlnd
- php5-gd
- php5-sqlite
- php5-xdebug
- php5-apc
- php5-mcrypt
- php5-curl
- php5-memcache

##MySQL

MySQL is configured with one database (`main`) and two user accounts:

- root (password: root)
- php (password: php)

The `php` account only has rights to access the `main` database.

##PHPunit

This repo also includes a phpunit.xml file configured to include the composer autoloader and generate coverage reports for all files in `/app/classes`.  Tests should go into the `/tests/classes` folder, matching the class path in `/app/classes`.

##Composer

Composer does not get installed within the vm, so it will need to be present on the host OS.  The composer.json file is configured to load all libraries into `/app/vendor`, including the autoloader files.

Composer is also configured to generate a classmap of the entire contents of `/app/classes`.