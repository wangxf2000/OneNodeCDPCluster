#! /bin/bash
echo "-- Configure and optimize the OS"
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.d/rc.local
# add tuned optimization https://www.cloudera.com/documentation/enterprise/6/6.2/topics/cdh_admin_performance.html
echo  "vm.swappiness = 1" >> /etc/sysctl.conf
sysctl vm.swappiness=1
timedatectl set-timezone UTC

echo "-- Install Java OpenJDK8 and other tools"
yum install -y java-1.8.0-openjdk-devel vim wget curl git bind-utils rng-tools bind bind-chroot
yum install -y epel-release
yum install -y python-pip iproute
pip install --upgrade pip==19.3
sudo yum -y install python3-pip
mkdir -p /usr/share/python3
sudo pip3 install mysql-connector-python==8.0.23 -t /usr/share/python3

cp /usr/lib/systemd/system/rngd.service /etc/systemd/system/
systemctl daemon-reload
systemctl start rngd
systemctl enable rngd

#echo "-- Installing requirements for Stream Messaging Manager"
# ignore to install nodejs
#yum install -y gcc-c++ make 
#curl -sL https://rpm.nodesource.com/setup_10.x | sudo -E bash - 
#yum install nodejs -y
#npm install forever -g 

# Check input parameters
case "$1" in
        aws)
            echo "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4" >> /etc/chrony.conf
            systemctl restart chronyd
            ;;
        azure)
# default root disk in most Azure Centos images is often small so second disk may be needed for /opt
# if you are already using /opt before the CDH install you may need to adjust this step as appropriate
# the temp disk used in the Cloudera Centos image on Azure on /mnt/resource may be an option if not persisting image
#            umount /mnt/resource
#            mount /dev/sdb1 /opt
            echo "server time.windows.com prefer iburst minpoll 4 maxpoll 4" >> /etc/chrony.conf
            systemctl restart chronyd
            ;;
        gcp)
            ;;
        *)
            echo $"Usage: $0 {aws|azure|gcp} template-file [docker-device]"
            echo $"example: ./setup.sh azure templates/essential.json"
            echo $"example: ./setup.sh aws template/cml.json /dev/xvdb"
            exit 1
esac

TEMPLATE=$2
DOCKERDEVICE=$3

echo "-- Configure networking"
PUBLIC_IP=`curl https://api.ipify.org/`
hostnamectl set-hostname `hostname -f`
echo "`hostname -I` `hostname`" >> /etc/hosts
sed -i "s/HOSTNAME=.*/HOSTNAME=`hostname`/" /etc/sysconfig/network
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


echo "-- Install CM and MariaDB"

## CM 7
wget https://archive.cloudera.com/cm7/7.4.4/redhat7/yum/cloudera-manager-trial.repo -P /etc/yum.repos.d/

## MariaDB 10.1
cat - >/etc/yum.repos.d/MariaDB.repo <<EOF
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF


yum clean all
rm -rf /var/cache/yum/
yum repolist

## CM
yum install -y cloudera-manager-agent cloudera-manager-daemons cloudera-manager-server

## MariaDB
yum install -y MariaDB-server MariaDB-client
cat conf/mariadb.config > /etc/my.cnf

echo "--Enable and start MariaDB"
systemctl enable mariadb
systemctl start mariadb

echo "-- Install JDBC connector"
wget https://downloads.mysql.com/archives/get/p/3/file/mysql-connector-java-5.1.49.tar.gz -P ~
tar zxf ~/mysql-connector-java-5.1.49.tar.gz -C ~
mkdir -p /usr/share/java/
cp ~/mysql-connector-java-5.1.49/mysql-connector-java-5.1.49-bin.jar /usr/share/java/mysql-connector-java.jar
rm -rf ~/mysql-connector-java-5.1.49*

#wget https://downloads.mysql.com/archives/get/p/3/file/mysql-connector-java-8.0.22.tar.gz -P ~
#tar zxf ~/mysql-connector-java-8.0.22.tar.gz -C ~
#mkdir -p /usr/share/java/
#cp ~/mysql-connector-java-8.0.22/mysql-connector-java-8.0.22-bin.jar /usr/share/java/mysql-connector-java.jar
#rm -rf ~/mysql-connector-java-8.0.22*

echo "-- Create DBs required by CM"
mysql -u root < scripts/create_db.sql

echo "-- Secure MariaDB"
mysql -u root < scripts/secure_mariadb.sql

echo "-- Prepare CM database 'scm'"
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm cloudera


## PostgreSQL see: https://www.postgresql.org/download/linux/redhat/
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql12
yum install -y postgresql12-server
pip install psycopg2==2.7.5 --ignore-installed

echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
/usr/pgsql-12/bin/postgresql-12-setup initdb

cat conf/pg_hba.conf > /var/lib/pgsql/12/data/pg_hba.conf
cat conf/postgresql.conf > /var/lib/pgsql/12/data/postgresql.conf

echo "--Enable and start pgsql"
systemctl enable postgresql-12
systemctl start postgresql-12

echo "-- Create DBs required by CM"
sudo -u postgres psql <<EOF 
CREATE DATABASE ranger;
CREATE USER ranger WITH PASSWORD 'cloudera';
GRANT ALL PRIVILEGES ON DATABASE ranger TO ranger;
CREATE DATABASE das;
CREATE USER das WITH PASSWORD 'cloudera';
GRANT ALL PRIVILEGES ON DATABASE das TO das;
CREATE ROLE ssb_admin LOGIN PASSWORD 'cloudera';
CREATE DATABASE ssb_admin OWNER ssb_admin ENCODING 'UTF8';
CREATE ROLE ssb_mve LOGIN PASSWORD 'cloudera';
CREATE DATABASE ssb_mve OWNER ssb_mve ENCODING 'UTF8';
EOF

wget https://jdbc.postgresql.org/download/postgresql-42.2.23.jar
mv postgresql-42.2.23.jar postgresql-connector-java.jar
cp postgresql-connector-java.jar /usr/share/java
#yum install -y python3-pip
#mkdir -p /usr/share/python3
pip3 install psycopg2-binary==2.8.5 -t /usr/share/python3


echo "-- Install CSDs"
wget https://archive.cloudera.com/p/cfm2/2.1.1.0/redhat7/yum/tars/parcel/NIFI-1.13.2.2.1.1.0-13.jar  -P /opt/cloudera/csd/
wget https://archive.cloudera.com/p/cfm2/2.1.1.0/redhat7/yum/tars/parcel/NIFIREGISTRY-0.8.0.2.1.1.0-13.jar  -P /opt/cloudera/csd/
wget https://archive.cloudera.com/p/csa/1.4.1.0/csd/FLINK-1.12-csa1.4.1.0-cdh7.1.6.0-297-15479260.jar  -P /opt/cloudera/csd/
wget https://archive.cloudera.com/p/csa/1.4.1.0/csd/SQL_STREAM_BUILDER-1.12-csa1.4.1.0-cdh7.1.6.0-297-15479260.jar   -P /opt/cloudera/csd/
wget https://archive.cloudera.com/p/cdsw1/1.9.2/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDPDC-1.9.2.jar -P /opt/cloudera/csd/


# install local CSDs
mv ~/*.jar /opt/cloudera/csd/
mv /home/centos/*.jar /opt/cloudera/csd/
chown cloudera-scm:cloudera-scm /opt/cloudera/csd/*
chmod 644 /opt/cloudera/csd/*

echo "-- Install local parcels"
mv ~/*.parcel ~/*.parcel.sha /opt/cloudera/parcel-repo/
mv /home/centos/*.parcel /home/centos/*.parcel.sha /opt/cloudera/parcel-repo/
chown cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/*

echo "-- Install CEM Tarballs"
mkdir -p /opt/cloudera/cem
wget https://archive.cloudera.com/p/CEM/centos7/1.x/updates/1.2.2.0/CEM-1.2.2.0-centos7-tars-tarball.tar.gz -P /opt/cloudera/cem
tar xzf /opt/cloudera/cem/CEM-1.2.2.0-centos7-tars-tarball.tar.gz -C /opt/cloudera/cem
tar xzf /opt/cloudera/cem/CEM/centos7/1.2.2.0-14/tars/efm/efm-1.0.0.1.2.2.0-14-bin.tar.gz -C /opt/cloudera/cem
tar xzf /opt/cloudera/cem/CEM/centos7/1.2.2.0-14/tars/minifi/minifi-0.6.0.1.2.2.0-14-bin.tar.gz -C /opt/cloudera/cem
tar xzf /opt/cloudera/cem/CEM/centos7/1.2.2.0-14/tars/minifi/minifi-toolkit-0.6.0.1.2.2.0-14-bin.tar.gz -C /opt/cloudera/cem
rm -f /opt/cloudera/cem/CEM-1.2.2.0-centos7-tars-tarball.tar.gz
ln -s /opt/cloudera/cem/efm-1.0.0.1.2.2.0-14 /opt/cloudera/cem/efm
ln -s /opt/cloudera/cem/minifi-0.6.0.1.2.2.0-14 /opt/cloudera/cem/minifi
ln -s /opt/cloudera/cem/efm/bin/efm.sh /etc/init.d/efm
chown -R root:root /opt/cloudera/cem/efm-1.0.0.1.2.2.0-14
chown -R root:root /opt/cloudera/cem/minifi-0.6.0.1.2.2.0-14
chown -R root:root /opt/cloudera/cem/minifi-toolkit-0.6.0.1.2.2.0-14

rm -f /opt/cloudera/cem/efm/conf/efm.properties
cp conf/efm.properties /opt/cloudera/cem/efm/conf
rm -f /opt/cloudera/cem/minifi/conf/bootstrap.conf
cp conf/bootstrap.conf /opt/cloudera/cem/minifi/conf
sed -i "s/YourHostname/`hostname -f`/g" /opt/cloudera/cem/efm/conf/efm.properties
sed -i "s/YourHostname/`hostname -f`/g" /opt/cloudera/cem/minifi/conf/bootstrap.conf
/opt/cloudera/cem/minifi/bin/minifi.sh install

echo "--Now install required libs and start the mosquitto broker"

yum install -y mosquitto
pip install wheel paho-mqtt
systemctl enable mosquitto
systemctl start mosquitto

echo "--Download the NiFi MQTT Processor to read from mosquitto"
mkdir -p /opt/cloudera/cem/minifi/lib/
wget https://repo1.maven.org/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/nifi-mqtt-nar-1.8.0.nar -P /opt/cloudera/cem/minifi/lib
chown root:root /opt/cloudera/cem/minifi/lib/nifi-mqtt-nar-1.8.0.nar
chmod 660 /opt/cloudera/cem/minifi/lib/nifi-mqtt-nar-1.8.0.nar


echo "-- Enable passwordless root login via rsa key"
ssh-keygen -f ~/myRSAkey -t rsa -N ""
mkdir ~/.ssh
cat ~/myRSAkey.pub >> ~/.ssh/authorized_keys
chmod 400 ~/.ssh/authorized_keys
ssh-keyscan -H `hostname` >> ~/.ssh/known_hosts
#sed -i 's/.*PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config
systemctl restart sshd

echo "-- Start CM, it takes about 2 minutes to be ready"
systemctl start cloudera-scm-server

while [ `curl -s -X GET -u "admin:admin"  http://localhost:7180/api/version` -z ] ;
    do
    echo "waiting 10s for CM to come up..";
    sleep 10;
done

echo "-- Now CM is started and the next step is to automate using the CM API"


pip install cm_client


sed -i "s/YourHostname/`hostname -f`/g" $TEMPLATE
sed -i "s/YourCDSWDomain/cdsw.$PUBLIC_IP.nip.io/g" $TEMPLATE
sed -i "s/YourPrivateIP/`hostname -I | tr -d '[:space:]'`/g" $TEMPLATE
sed -i "s#YourDockerDevice#$DOCKERDEVICE#g" $TEMPLATE

sed -i "s/YourHostname/`hostname -f`/g" scripts/create_cluster.py

python scripts/create_cluster.py $TEMPLATE

echo "-- At this point you can login into Cloudera Manager host on port 7180 and follow the deployment of the cluster"

#echo "--Now start efm and minifi"
# configure and start EFM and Minifi
#systemctl enable efm
#systemctl start efm
#systemctl enable minifi
#systemctl start minifi

