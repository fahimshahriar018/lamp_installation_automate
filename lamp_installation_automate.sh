#!/bin/bash

#------------ LAMP Install Automation script -----------#
######### Author: Fahim Shahriar



#########################
# Print a meassage in a mentioned Color 
#Arguments:
#color. eg: red, green
function print_color(){
	NC='\033[0m'  # No color
	
	case $1 in
		"green") color='\033[0;32m' ;;
		"red") color='\033[0;31m'  ;;
		"*") color='\033[0m'  ;;
	esac
	echo -e "${color} $2 ${NC}"
}

####### Check user is a sudoers or not

if [[ "$(id -u)" -ne 0 ]]
then 
	print_color "red" "Only sudo users can run the script"
	exit 1
fi
###############
#Check the service is active or not. if not it exit the script with 1 
#Argument:
# Service name. eg: mariadb, httpd
function is_service_active(){
	service_active=$(systemctl is-active $1)
	if [[ $service_active = "active" ]]
	then
		print_color "green" "$1 is active and running"
	else
		print_color "red" "$1 is not active/running"
		exit 1
	fi
}

###############
#Check the service is enabled or not. if not it will exit the script with 1 
#Argument:
# Service name. eg: mariadb, httpd
function is_service_enabled(){

	service_enable=$(systemctl is-enabled $1)
	if [[ $service_enable = "enabled" ]]
	then
		print_color "green" "$1 is Enabled"
	else
		print_color "red" "$1 is not Enabled"
		exit 1
	fi
}

###############
#Check the service port is open or notin the firewall. if not it will exit the script with 1 
#Argument:
# Service name. eg: 80, 443
function is_firewall_port_open(){
	firewalld_ports=$(firewall-cmd --list-ports)
	if [[ $firewalld_ports == *$1*  ]]
	then	
		print_color "green" "$1 port is open in firewall"
	else
		print_color "red" "$1 port is not open in firewall"
		exit 1
	fi
}

###############
#Check the service is enabled or not in the firewall. if not it will exit the script with 1 
#Argument:
# Service name. eg: mariadb, httpd
function is_firewall_service_open(){
	firewalld_service=$(firewall-cmd --list-service)
	if [[ $firewalld_service == *$1*  ]]
	then	
		print_color "green" "$1 service is open in firewall"
	else
		print_color "red" "$1 service is not open in firewall"
		exit 1
	fi
}
##### Install, start enable firewalld ##############
print_color "green" "installing Firewalld..."

 yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld

is_service_active "firewalld"
is_service_enabled "firewalld"

#####  Install Config Mariadb ##############

print_color "green" "--------------Database Server Setup------------"
 
yum install mariadb-server mariadb -y
systemctl start mariadb
systemctl enable mariadb
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd  --zone=public --add-port=3306/tcp

is_service_active "mariadb"
is_service_enabled "mariadb"
is_firewall_port_open "3306/tcp"
###### Config Database user and create tables #########
print_color "green" "Setting Up Database..."
cat > setup-db.sql <<-EOF
	create database qorum;
	create user 'fahim@localhost' identified by 'mypassword';
	grant all privileges on *.* to 'fahim'@'localhost';
	flush privileges;
EOF

mysql < setup-db.sql


############### Install php 7.3  ##################
print_color "green" "Start Installing php........"
yum install yum-utils -y
yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum-config-manager --enable remi-php73   # Enable repo for php 7.3
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-dom php-mbstring -y    # install php 7.3 with all necesary modules

#check php version
 print_color "green" "$(php -v)" 

########### Install Global Composer ######
print_color "green" "Start Installing global composer.........."
# Download Composer 

php -r "readfile('https://getcomposer.org/installer');" | php

# move to composer.phar to /usr/bin/composer to installl composer as global 
 mv ./composer.phar /usr/bin/composer



############ Install, config httpd ##########
print_color "green" "Start Installing Apache......."
yum install httpd -y

# Config virtual host for website
cat > /etc/httpd/conf.d/vhost.conf <<-EOF
#<VirtualHost *:80>
#	ServerName example.com
#	ServerAlias www.example.com
#        ServerAdmin admin@example.com
#        DocumentRoot "/var/www/html/"
#        ErrorLog  "/var/log/httpd/error.log"
#        CustomLog "/var/log/httpd/access.log" 
#</VirtualHost>
        
 #<Directory /var/www/html/>
#        Options Indexes FollowSymLinks MultiViews
#        AllowOverride All
#        Order allow,deny
#        allow from all
#</Directory>
EOF

#### Start and enable httpd service ###

systemctl start httpd
systemctl enable httpd
firewall-cmd --permanent --zone=public --add-service={http,https}
firewall-cmd  --zone=public --add-service={http,https}

is_service_active "httpd"
is_service_enabled "httpd"
is_firewall_service_open "http"
is_firewall_service_open "https"
############ Install &  phpmyadmin ##############

#install epel-release Repo to install additional packages like phpmyadmin

print_color "green" "Start Installing phpmyadmin....."
yum install epel-release -y
yum install phpmyadmin -y


