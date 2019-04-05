#Disable SELinux
setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

#Base Line Installed Packages
sudo yum -y install @core epel-release vim git tcpdump nmap-ncat
sudo yum -y install curl
sudo yum update -y

#Configure Firewall
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
#check
systemctl restart firewalld
firewall-cmd --zone=public --list-all

#nginx
sudo yum install -y nginx
systemctl start nginx
systemctl enable nginx
systemctl status nginx
curl http://localhost:80

#mariadb
sudo yum install -y mariadb-server
sudo yum install -y mariadb
systemctl start mariadb

mysql -u root < configs/mariadb_security_config.sql

systemctl restart mariadb
systemctl enable mariadb

#php
sudo yum install -y php
sudo yum install -y php-mysql
sudo yum install -y php-fpm
cp -f configs/php.ini /etc/php.ini
cp -f configs/www.conf /etc/php-fpm.d/www.conf
systemctl start php-fpm
systemctl enable php-fpm
cp -f configs/nginx.conf /etc/nginx/nginx.conf
cp -f configs/info.php /usr/share/nginx/html/info.php
systemctl restart nginx

#wordpress
mysql -u root -pP@ssw0rd < configs/wp_mariadb_config.sql

#wordpress source setup
yum install -y wget
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
cp wordpress/wp-config-sample.php wordpress/wp-config.php
cp -f configs/wp-config.php wordpress/wp-config.ph
sudo rsync -avP wordpress/ /usr/share/nginx/html/
sudo mkdir /usr/share/nginx/html/wp-content/uploads
sudo chown -R admin:nginx /usr/share/nginx/html/*
systemctl restart nginx
