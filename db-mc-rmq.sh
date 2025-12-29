#!/bin/bash

# Switch to root user
sudo -i

rm -rf /etc/yum.repos.d/*
cat << EOF > /etc/yum.repos.d/app.repo
[appstream]
name=CentOS Stream 9 - AppStream
baseurl=http://mirror.stream.centos.org/9-stream/AppStream/x86_64/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[baseos]
name=CentOS Stream 9 - BaseOS
baseurl=http://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[crb]
name = CentOS Stream 9 -CRB
baseurl = http://mirror.stream.centos.org/9-stream/CRB/x86_64/os/
enabled = 1
gpgcheck = 1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

EOF

# Update package list and install EPEL release
echo "Installing EPEL release..."
yum install epel-release -y

# Install MariaDB and Git
echo "Installing MariaDB and Git..."
yum install git mariadb-server -y

# Start and enable MariaDB service
echo "Starting and enabling MariaDB service..."
systemctl start mariadb
systemctl enable mariadb

# Run mysql_secure_installation script automatically
echo "Securing MariaDB..."
expect <<EOF
spawn mysql_secure_installation
expect "Enter current password for root (enter for none):"
send "\r"
expect "Set root password? \[Y/n\]"
send "y\r"
expect "New password:"
send "admin123\r"
expect "Re-enter new password:"
send "admin123\r"
expect "Remove anonymous users? \[Y/n\]"
send "y\r"
expect "Disallow root login remotely? \[Y/n\]"
send "y\r"
expect "Remove test database and access to it? \[Y/n\]"
send "y\r"
expect "Reload privilege tables now? \[Y/n\]"
send "y\r"
expect eof
EOF

# Configure MariaDB: Create database and user
echo "Configuring MariaDB database and user..."
mysql -u root -padmin123 <<MYSQL_SCRIPT
CREATE DATABASE accounts;
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Download source code and initialize database
echo "Cloning source code and initializing database..."
git clone -b main https://github.com/alaadin2005/vprofile-project.git
cd vprofile-project
mysql -u root -padmin123 accounts < src/main/resources/db_backup.sql

# Restart MariaDB service
echo "Restarting MariaDB service..."
systemctl restart mariadb

# Start and configure the firewall to allow access to MariaDB on port 3306
echo "Configuring firewall..."
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=3306/tcp --permanent
firewall-cmd --reload

echo "MariaDB setup is complete."

# Install EPEL release and Memcached
echo "Installing EPEL release and Memcached..."
dnf install memcached -y

# Start and enable Memcached service
echo "Starting and enabling Memcached service..."
systemctl start memcached
systemctl enable memcached
systemctl status memcached

# Configure Memcached to listen on all interfaces
echo "Configuring Memcached to listen on all interfaces..."
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/sysconfig/memcached

# Restart Memcached service to apply changes
echo "Restarting Memcached service..."
systemctl restart memcached

# Start and configure the firewall to allow access to Memcached on ports 11211 and 11111
echo "Configuring firewall for Memcached..."
firewall-cmd --add-port=11211/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --add-port=11111/udp
firewall-cmd --runtime-to-permanent

# Start Memcached with specific port settings
echo "Starting Memcached on port 11211 (TCP) and 11111 (UDP)..."
memcached -p 11211 -U 11111 -u memcached -d

echo "Memcached setup is complete."

# Install wget and RabbitMQ
echo "Installing wget and RabbitMQ..."
yum install wget -y
cd /tmp/
dnf -y install centos-release-rabbitmq-38
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server

# Start and enable RabbitMQ service
echo "Starting and enabling RabbitMQ service..."
systemctl enable --now rabbitmq-server

# Setup access to user 'test' and make it admin
echo "Configuring RabbitMQ user 'test'..."
sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator

# Restart RabbitMQ service to apply changes
echo "Restarting RabbitMQ service..."
systemctl restart rabbitmq-server

# Start and configure the firewall to allow access to RabbitMQ on port 5672
echo "Configuring firewall for RabbitMQ..."
firewall-cmd --add-port=5672/tcp
firewall-cmd --runtime-to-permanent

# Start RabbitMQ service
echo "Starting RabbitMQ service..."
systemctl start rabbitmq-server
systemctl enable rabbitmq-server
systemctl status rabbitmq-server

echo "RabbitMQ setup is complete."