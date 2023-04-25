#! /bin/bash
echo "Which MySQL version you in MySQL 8.0._ give above 27."
read mysql_ver
echo "YOU  ARE SELECTED MySQL 8.0.$mysql_ver & INSTALLING"
echo "Give the server_id for my.cnf file"
read server_id
echo "You are given server_id=$server_id & Installation started."
read -p "Enter the Linux prompt name like [centos@ MASTER ~]$ : " prompt
echo "PS1='[\u@ $prompt \W]\$ '" >> ~/.bash_profile; source  ~/.bash_profile;
echo -e "[mysql]\nprompt=mysql ${prompt} > " /etc/my.cnf
#
yum update -y
yum list installed |  grep mariadb
yum remove mariadb* -y
sestatus
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
yum list installed | grep mysql
yum install mysql-community*8.0.$mysql_ver*64 -y
sed -i 's/^# default-authentication-plugin=mysql.*/default-authentication-plugin=mysql_native_password/g' /etc/my.cnf
systemctl start mysqld
systemctl enable mysqld
echo "
server_id=$server_id
log_bin=binlog" >> /etc/my.cnf
cat /etc/my.cnf
systemctl status mysqld
password=`grep password /var/log/mysqld.log | cut -d ' ' -f 13`; echo $password
echo " After restarting run these cmds: mysql_secure_installation"
 echo "
mysql -uroot -p
ALTER USER 'root'@'localhost' IDENTIFIED WITH MYSQL_NATIVE_PASSWORD BY 'Admin@123';
show master status\G
create user 'replica'@'%' IDENTIFIED WITH MYSQL_NATIVE_PASSWORD BY 'Replica@123';
grant all privileges on *.* to 'replica'@'%';
flush privileges;
CHANGE MASTER TO MASTER_HOST = '13.229.28.173', MASTER_USER = 'ddr_slave_rpl', MASTER_PASSWORD = 'ddr_slave_rpl', MASTER_LOG_FILE = 'mysql-bin.000763', MASTER_LOG_POS = 121993598;
start slave;
show slave status\G 
curl icanhazip.com "
mysql -uroot -p${password}

reboot
