yum update -y
yum install yum-utils -y 
yum list installed |  grep mariadb
yum remove mariadb* -y
sestatus
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
yum list installed | grep mysql
yum install mysql*8.0.28*64 -y
sed -i 's/^# default-authentication-plugin=mysql.*/default-authentication-plugin=mysql_native_password/g' /etc/my.cnf

systemctl start mysqld
systemctl enable mysqld

echo "
server_id=1
log_bin=binlog" >> /etc/my.cnf

systemctl status mysqld
grep password /var/log/mysqld.log
reboot
 
echo " After restarting run these cmds:
mysql_secure_installation"
