#!/bin/bash

# Run as root
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

# Install Java, Git, Maven, and Wget
echo "Installing Java, Git, Maven, and Wget..."
dnf -y install java-11-openjdk java-11-openjdk-devel git maven wget

# Change to /tmp directory
echo "Changing directory to /tmp..."
cd /tmp/

# Download and extract Tomcat package
echo "Downloading and extracting Tomcat package..."
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.75/bin/apache-tomcat-9.0.75.tar.gz
tar xzvf apache-tomcat-9.0.75.tar.gz

# Add tomcat user
echo "Adding tomcat user..."
useradd --home-dir /usr/local/tomcat --shell /sbin/nologin tomcat

# Copy data to tomcat home directory
echo "Copying data to Tomcat home directory..."
mkdir -p /usr/local/tomcat
cp -r /tmp/apache-tomcat-9.0.75/* /usr/local/tomcat/

# Make tomcat user owner of tomcat home directory
echo "Making tomcat user owner of Tomcat home directory..."
chown -R tomcat:tomcat /usr/local/tomcat

# Create tomcat systemd service file
echo "Creating tomcat systemd service file..."
cat <<EOL > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk"
Environment="CATALINA_PID=/usr/local/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/usr/local/tomcat"
Environment="CATALINA_BASE=/usr/local/tomcat"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=/usr/local/tomcat/bin/startup.sh
ExecStop=/usr/local/tomcat/bin/shutdown.sh

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd files and start & enable tomcat service
echo "Reloading systemd files and starting & enabling tomcat service..."
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

# Enabling the firewall and allowing port 8080 to access Tomcat
echo "Enabling the firewall and allowing port 8080 to access Tomcat..."
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload

# Code build & deploy
# Download source code
echo "Downloading source code..."
cd /home
mkdir vagrant
git clone -b main https://github.com/alaadin2005/vprofile-project.git

# Update configuration
echo "Updating configuration..."
cd vprofile-project
sed -i 's|backend.server.url=.*|backend.server.url=http://db01.vprofile:3306|' src/main/resources/application.properties

# Build code
echo "Building code..."
mvn clean install

# Deploy artifact
echo "Deploying artifact..."
systemctl stop tomcat
rm -rf /usr/local/tomcat/webapps/ROOT*
cp target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war
chown -R tomcat:tomcat /usr/local/tomcat/webapps
systemctl start tomcat

echo "Tomcat setup and deployment is complete."
