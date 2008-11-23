# sudo gem install passenger
# apt-get install apache2-mpm-prefork apache2-prefork-dev
# passenger-install-apache2-module


git clone git://github.com/FooBarWidget/passenger.git
# Install a certain version
git checkout -b release-2.0.2 release-2.0.2

# XXX automate
./bin/passenger-install-apache2-module


# Put something like this in passenger.conf
# XXX Get the right version from output?
LoadModule passenger_module /Users/mbailey/work/passenger/ext/apache2/mod_passenger.so
PassengerRoot /Users/mbailey/work/passenger
PassengerRuby /usr/local/bin/ruby

# Put something like this in for vhost
<VirtualHost *:80>
  ServerName tubemarks.local
  DocumentRoot "/Users/mbailey/work/tubemarks/public"
  RailsEnv development
  RailsAllowModRewrite off
  <directory "/Users/mbailey/work/tubemarks/public">
    Order allow,deny
    Allow from all
  </directory>
</VirtualHost>