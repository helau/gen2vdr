#!/bin/bash
#set -x
stp mysql
mysqld_safe --skip-grant-tables --user=root --skip-networking &
sleep 10
mysql -u root <<EOF
FLUSH PRIVILEGES;
UPDATE mysql.user SET password=password("gen2vdr") WHERE user="root";
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'gen2vdr' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
killall mysqld
sleep 5
stt mysql
