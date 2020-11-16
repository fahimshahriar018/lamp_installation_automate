create database qorum;
create user 'fahim@localhost' identified by 'mypassword';
grant all privileges on *.* to 'fahim'@'localhost';
flush privileges;
