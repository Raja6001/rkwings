#! /bin/bash
#
# MySQL version 8.0.33 installation 
#
#
server_id=1
mysql_ver=33
prompt="MASTER"
root_pass="Admin@123"

read -p " Enter your new mysql root password: " root_pass
# Ensure the root password is set
if [ -z "${root_pass}" ]; then
    echo "Please provide a root user password."
    exit 1
fi

read -p "Which MySQL version you in MySQL 8.0._ like 23:" mysql_ver 
echo "YOU  ARE SELECTED MySQL 8.0.${mysql_ver} & INSTALLING"

read -p "Give the server_id for my.cnf file: " server_id
echo "You are given server_id=${server_id} & Installation started."

read -p "Enter the Linux prompt name like [centos@ MASTER ~]$ : " prompt
echo "PS1='[\u@\h ${prompt} \W]\$ '" >> ~/.bash_profile; source  ~/.bash_profile;
#echo "${prompt}" > /etc/hostname

echo ""
echo "Wait some time yum update is running."
yum update -y	

echo ""
echo "Removing mariadb."
yum remove mariadb* -y

#systemctl stop mysqld
#rm -rf /var/lib/mysql	
#yum remove mysql* -y	

# cat /dev/null > /var/log/mysqld.log
ps -ef | grep mysql

echo ""
echo "Disabling SElinux."
sestatus
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

echo ""
echo "Installing MySQL 8 repo."
rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-3.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022

echo ""
echo "Sit back MySQL 8.0.${mysql_ver} is installing."
yum install mysql-community*8.0.${mysql_ver}*64 -y  

echo ""
echo "Enable mysql_native_password plugin."
sed -i 's/^# default-authentication-plugin=mysql.*/default-authentication-plugin=mysql_native_password/g' /etc/my.cnf

echo ""
echo "Start the MySQL service"
systemctl start mysqld

# Check if the config file was good
if [ $? -eq 0 ]; then
    echo "Server ID ${server_id} and log_bin set successfully."
else
    echo "Server ID or someting missed. Kindly check the config file and error log"
	cat /etc/my.cnf
	echo ""
	cat /var/log/mysqld.log
	exit 1
fi

echo -e "[mysql]\nprompt='${prompt} mysql> '\n$(cat /etc/my.cnf)" > /etc/my.cnf

echo ""
echo "Setting up serverid ${server_id}."

# Changing the log file location:
systemctl stop mysqld
mkdir -p /mysql_data/logs
chown -R mysql:mysql /mysql_data/logs

cat >> /etc/my.cnf << EOF
# bin log variables:
server_id                		= ${server_id}
log_bin                       	= /mysql_data/logs/mysql_bin_log
binlog_format              		= ROW
expire_logs_days              	= 7 # days
# Slow query log variables
slow_query_log                	= 1
long_query_time                 = 2 # seconds
slow_query_log_file				= /mysql_data/logs/${prompt}_slow_query.log
log_queries_not_using_indexes
EOF

echo ""
echo "Start the MySQL service"
systemctl start mysqld
systemctl enable mysqld
systemctl status mysqld | grep Active

MASTER_IP=$(curl -s icanhazip.com)

password=`grep 'A temporary password' /var/log/mysqld.log | tail -1 | awk -F' ' '{print $NF}'` && echo $password
echo ""
# Use mysqladmin to set the root password
mysqladmin -u root -p"${password}" password "${root_pass}"

# Check if the password change was successful
if [ $? -eq 0 ]; then
    echo "MySQL root password has been set successfully."
else
    echo "Failed to set MySQL root password."
	exit 1
fi
echo ""
mysqladmin -u root -p"${root_pass}" ping version processlist

log_position=$(mysql -uroot -p"${root_pass}" -e "SHOW MASTER STATUS;" | grep -v Position | awk '{print $1, $2}')

# Assign log_file and position to separate variables
log_file=$(echo "$log_position" | awk '{print $1}')
position=$(echo "$log_position" | awk '{print $2}')

MASTER_IP=$(curl -s icanhazip.com)
echo ""

echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${root_pass}';"

mysql -uroot -p${root_pass} -e " select user , host, plugin from mysql.user;"
mysql -uroot -p${root_pass} -e " show master status;"

echo "
If you need setup slave you can use these commands in 

CREATE USER 'replica'@'%' IDENTIFIED WITH MYSQL_NATIVE_PASSWORD BY 'Replica@123';
GRANT REPLICATION SLAVE ON . TO 'replica'@'%';
GRANT ALL PRIVILEGES ON *.* TO 'replica'@'%';
FLUSH PRIVILEGES;

drop user 'replica'@'%';
stop slave;
reset slave;
CHANGE MASTER TO MASTER_HOST='${MASTER_IP}', MASTER_USER='replica', MASTER_PASSWORD='Replica@123', MASTER_LOG_FILE='${log_file}', MASTER_LOG_POS=${position};
start slave;
show slave status\G
mysql_config_editor set --login-path=client --host=localhost --user=root --password --port=3306
mysql_config_editor print --all
curl icanhazip.com " > /tmp/test

systemctl restart mysqld

cat /etc/my.cnf
cat /tmp/test
rm -rf /tmp/test
sestatus


reboot
