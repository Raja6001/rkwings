#! /bin/bash
echo "Which MySQL version you in MySQL 8.0._ give above 27."
read mysql_ver
echo "YOU  ARE SELECTED MySQL 8.0.$mysql_ver & INSTALLING"
echo "Give the server_id for my.cnf file"
read server_id
echo "You are given server_id=$server_id & Installation started."
read -p "Enter the Linux prompt name like [centos@ MASTER ~]$ : " prompt
echo "PS1='[\u@ $prompt \W]\$ '" >> ~/.bash_profile; source  ~/.bash_profile;
echo -e "[mysql]\nprompt=mysql ${prompt}>  \n$(cat /etc/my.cnf)" > /etc/my.cnf
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
 cat /etc/my.cnf
sestatus
read -p " Enter your new mysql root password: " root_pass
 echo "
mysql -uroot -p$root_pass
ALTER USER 'root'@'localhost' IDENTIFIED WITH MYSQL_NATIVE_PASSWORD BY '$root_pass';
show master status\G
select user , host, plugin from mysql.user;
CREATE USER 'replica'@'%' IDENTIFIED WITH MYSQL_NATIVE_PASSWORD BY 'Replica@123';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'replica'@'%';
FLUSH PRIVILEGES;

drop user 'replica'@'%';
systemctl restart mysql
stop slave;
reset slave;
CHANGE MASTER TO MASTER_HOST = '13.59.184.150', MASTER_USER = 'replica', MASTER_PASSWORD = 'Replica@123', MASTER_LOG_FILE = 'binlog.000004', MASTER_LOG_POS = 157;
start slave;
show slave status\G
curl icanhazip.com " > test
cat test
mysql -uroot -p${password}

reboot
