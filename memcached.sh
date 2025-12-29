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
