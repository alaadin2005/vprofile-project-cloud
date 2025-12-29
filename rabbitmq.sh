#!/bin/bash

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
