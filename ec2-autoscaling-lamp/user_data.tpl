#!/bin/bash
####  Installing Apache, Mysql and PHP #### 
yum install httpd php php-mysql -y
yum update -y
chkconfig httpd on
service httpd start
echo "<?php phpinfo();?>" > /var/www/html/index.php


### Establishing connection with already existing RDS ####

RDS_MYSQL_ENDPOINT= "myrds.us-east-1.rds.amazonaws.com";
RDS_MYSQL_USER="ayush";
RDS_MYSQL_PASS="***************";
RDS_MYSQL_BASE="customer table";

mysql -h $RDS_MYSQL_ENDPOINT -u $RDS_MYSQL_USER -p$RDS_MYSQL_PASS -D $RDS_MYSQL_BASE -e 'quit';

if [[ $? -eq 0 ]]; then
    echo "MySQL connection: OK";
else
    echo "MySQL connection: Fail";
fi;