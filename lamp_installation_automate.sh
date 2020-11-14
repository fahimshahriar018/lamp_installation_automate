#!/bin/bash

#------------ LAMP Install Automation script -----------#
######### Author: Fahim Shahriar


####### Check user is a sudoers or not

if [[ "$(id -u)" -ne 0 ]]
then 
	echo "Only sudo users can run the script"
	exit 1
fi

#########################
# Print a meassage in a mentioned Color 

function print_color(){

}


##### Install, start enable firewalld ##############
echo "installing Firewalld..."

 yum install firewalld -y
systemctl start firewalld
systemctl enable firewalld

echo "firwalld is enabled"

#####  Install Config Mariadb ##############

echo "--------------Database Server Setup------------"
 
yum install mariadb-server mariadb -y
systemctl start mariadb
systemctl enable mariadb
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd  --zone=public --add-port=3306/tcp

###### Config Database user and create tables #########
echo "Setting Up Database..."
cat > setup-db.sql <<-EOF
	create database qorum;
	create user 'fahim@localhost' identified by 'mypassword';
	grant all privileges on *.* to 'fahim'@'localhost';
	flush privileges;
EOF

mysql < setup-db.sql






############### Install php ##################



############ Install, config httpd ##########

############ Install &  phpmyadmin ##############

