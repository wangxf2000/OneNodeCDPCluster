# Single Node CDP Data Center Cluster 

This script automatically sets up a CDP Data Center Trial cluster on the public cloud on a single VM with the services preconfigured in a template file.

- CDSW
- MiNiFi
- EFM
- NiFi
- NiFi CA
- NiFi Registry
- Schema Registry
- Stream Messaging Manager
- Stream Replication Manager
- Kafka
- HBase
- Phoenix
- Kudu
- Impala
- Hue
- Hive
- Spark
- Solr
- Oozie
- HDFS
- YARN
- ZK

More services can be added or removed by updating the template used, example: HBase, Phoenix, Schema Registry, etc.
As this cluster is meant to be used for demos, experimenting, training, and workshops, it doesn't setup Kerberos and TLS.

## Instructions

Below are instructions for creating the cluster with or without CDSW service. CDSW requires some extra resources (more powerful instance, and a secondary disk for the docker device).

### Provisioning Cluster without CDSW
- Create a Centos 7 VM with at least 8 vCPUs/ 32 GB RAM. Choose the plain vanilla Centos image, not a cloudera-centos image.
- OS disk size: at least 50 GB.

### Provisioning Cluster with CDSW
- Create a Centos 7 VM with at least 16 vCPUs/ 64 GB RAM. Choose the plain vanilla Centos image, not a cloudera-centos image.
- OS disk size: at least 100 GB.
- Docker device disk: at least 200GB SSD disk.
  - Node: you need a fast disk more than you need a large disk: aim for a disk with 3000 IOPS. This might mean choosing a 1TB disk.

### Provisioning Cluster with Trial parcels

Currently, there is no automation process to download parcels for services such as Schema Registry. You need to download the required files from the official Cloudera website on your laptop. Then, sftp the `.parcel`, `.sha` and `.jar` files into the `/home/centos` or `/root` directory. The script takes care of placing these files into the correct folders during installation.

For example, you can install Schema Registry once your host looks like the below:

```
$ ls -l /root/
-rwxr-xr-x. 1 centos centos 148855790 Aug  5 18:41 SCHEMAREGISTRY-0.7.0.1.0.0.0-11-el7.parcel
-rw-r--r--. 1 centos centos        41 Aug  5 18:41 SCHEMAREGISTRY-0.7.0.1.0.0.0-11-el7.parcel.sha
-rwxr-xr-x. 1 centos centos     14525 Aug  5 18:41 SCHEMAREGISTRY-0.7.0.jar
```

To install Schema Registry, you must use an appropriate template file, like `all.json`.

### Configuration and installation
- If you created the VM on Azure and need to resize the OS disk, here are the [instructions](scripts/how-to-resize-os-disk.md).
- add 2 inbound rules to the Security Group:
  - to allow your IP only, for all ports.
  - to allow the VM's own IP, for all ports.
- ssh into VM and copy this repo.

```
sudo su -
yum install -y git
git clone https://github.com/wangxf2000/OneNodeCDPCluster.git
cd OneNodeCDPCluster
```

### local repository prepare
if you use your local repository, you need to do the following first
```
#install the tools 
yum -y install httpd git createrepo unzip
sed -i 's/AddType application\/x-gzip .gz .tgz/AddType application\/x-gzip .gz .tgz .parcel/' /etc/httpd/conf/httpd.conf

#create the local repository directory
mkdir -p /var/www/html/cm7/7.1.1/redhat7/yum/RPMS/x86_64/
mkdir -p /var/www/html/cdh7/7.1.1.0/parcels/
mkdir -p /var/www/html/CFM/csd/1.0.1.0/
mkdir -p /var/www/html/cdsw1/1.7.2/csd/
mkdir -p /var/www/html/spark2/csd/
mkdir -p /var/www/html/CEM/centos7/1.x/updates/1.0.0.0/
mkdir -p /var/www/html/get/Downloads/Connector-J/
mkdir -p /var/www/html/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/
mkdir -p /var/www/html/CFM/parcels/1.0.1.0/
mkdir -p /var/www/html/cdsw1/1.7.2/parcels/
mkdir -p /var/www/html/pkgs/misc/parcels/archive/
mkdir -p /var/www/html/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/
mkdir -p /var/www/html/pkgs/misc/parcels/archive/

```

### download the public repository to your local directory
```
wget -nd -r  -l1 --no-parent https://archive.cloudera.com/cm7/7.0.3/redhat7/yum/RPMS/x86_64/ -P /var/www/html/cm7/7.0.3/redhat7/yum/RPMS/x86_64/
wget https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/RPM-GPG-KEY-cloudera -P /var/www/html/cm7/7.1.1/redhat7/yum
wget https://archive.cloudera.com/cm7/7.1.1/redhat7/yum/cloudera-manager-trial.repo -P /var/www/html/cm7/7.1.1/redhat7/yum
wget https://archive.cloudera.com/cm7/7.1.1/allkeys.asc -P /var/www/html/cm7/7.1.1
wget https://archive.cloudera.com/cdh7/7.1.1.0/parcels/CDH-7.1.1-1.cdh7.1.1.p0.3266817-el7.parcel -P /var/www/html/cdh7/7.1.1.0/parcels/
wget https://archive.cloudera.com/cdh7/7.1.1.0/parcels/CDH-7.1.1-1.cdh7.1.1.p0.3266817-el7.parcel.sha256 -P /var/www/html/cdh7/7.1.1.0/parcels/
wget https://archive.cloudera.com/cdh7/7.1.1.0/parcels/manifest.json -P /var/www/html/cdh7/7.1.1.0/parcels/
wget https://archive.cloudera.com/cdsw1/1.7.2/parcels/CDSW-1.7.2.p1.2066404-el7.parcel -P /var/www/html/cdsw1/1.7.2/parcels/
wget https://archive.cloudera.com/cdsw1/1.7.2/parcels/CDSW-1.7.2.p1.2066404-el7.parcel.sha -P /var/www/html/cdsw1/1.7.2/parcels/
wget https://archive.cloudera.com/cdsw1/1.7.2/parcels/manifest.json -P /var/www/html/cdsw1/1.7.2/parcels/
wget http://archive.cloudera.com/CFM/parcels/1.0.1.0/CFM-1.0.1.0-el7.parcel -P /var/www/html/CFM/parcels/1.0.1.0/
wget http://archive.cloudera.com/CFM/parcels/1.0.1.0/CFM-1.0.1.0-el7.parcel.sha -P /var/www/html/CFM/parcels/1.0.1.0/
wget http://archive.cloudera.com/CFM/parcels/1.0.1.0/manifest.json  -P /var/www/html/CFM/parcels/1.0.1.0/
wget http://archive.cloudera.com/CFM/csd/1.0.1.0/NIFI-1.9.0.1.0.1.0-12.jar -P /var/www/html/CFM/csd/1.0.1.0/
wget http://archive.cloudera.com/CFM/csd/1.0.1.0/NIFICA-1.9.0.1.0.1.0-12.jar -P /var/www/html/CFM/csd/1.0.1.0/
wget http://archive.cloudera.com/CFM/csd/1.0.1.0/NIFIREGISTRY-0.3.0.1.0.1.0-12.jar -P /var/www/html/CFM/csd/1.0.1.0/
wget https://archive.cloudera.com/cdsw1/1.7.2/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDPDC-1.7.2.jar	 -P /var/www/html/cdsw1/1.7.2/csd/
wget https://archive.cloudera.com/cdsw1/1.7.2/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDH6-1.7.2.jar -P /var/www/html/cdsw1/1.7.2/csd/
wget https://archive.cloudera.com/spark2/csd/SPARK2_ON_YARN-2.4.0.cloudera1.jar -P /var/www/html/spark2/csd/  
wget https://archive.cloudera.com/CEM/centos7/1.x/updates/1.0.0.0/CEM-1.0.0.0-centos7-tars-tarball.tar.gz -P /var/www/html/CEM/centos7/1.x/updates/1.0.0.0/
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz -P /var/www/html/get/Downloads/Connector-J/
wget http://central.maven.org/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/nifi-mqtt-nar-1.8.0.nar -P /var/www/html/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/
wget https://repo.continuum.io/pkgs/misc/parcels/archive/Anaconda-5.3.1-el7.parcel  -P /var/www/html/pkgs/misc/parcels/archive/
wget https://repo.continuum.io/pkgs/misc/parcels/archive/Anaconda-5.3.1-el7.parcel.sha -P /var/www/html/pkgs/misc/parcels/archive/
wget https://repo.continuum.io/pkgs/misc/parcels/archive/manifest.json -P /var/www/html/pkgs/misc/parcels/archive/
rm -rf /var/www/html/cm7/7.0.3/redhat7/yum/RPMS/x86_64/index.html
rm -rf /var/www/html/cm7/7.0.3/redhat7/yum/RPMS/x86_64/robots.txt

#create the cm7's repo information
cd /var/www/html/cm7/7.0.3/redhat7/yum/
createrepo .

### replace cloudera repository to your own repository 
### modify the repository in setup.sh, scripts/create_cluster.py ,templates/*json files
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDHCluster/setup.sh
sed -i "s/central.maven.org/`hostname -f`/g" ~/OneNodeCDHCluster/setup.sh
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDHCluster/setup.sh
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDHCluster/templates/*.json
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" /var/www/html/cm7/7.1.1/redhat7/yum/cloudera-manager-trial.repo
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDHCluster/scripts/create_cluster.py
sed -i "s?https://dev.mysql.com?http://`hostname -f`?g" ~/OneNodeCDHCluster/setup.sh
sed -i "s?https://repo.continuum.io?http://`hostname -f`?g" ~/OneNodeCDHCluster/templates/*.json

systemctl enable httpd
systemctl start httpd

```
### deploy cluster

The script `setup.sh` takes 3 arguments:
- the cloud provider name: `aws`,`azure`,`gcp`.
- the template file.
- OPTIONAL the Docker Device disk mount point.

Example: create cluster without CDSW on AWS using default_template.json
```
$ ./setup.sh aws templates/base.json
```

Example: create cluster with CDSW on Azure using cdsw_template.json
```
$ ./setup.sh azure templates/iot_workshop.json /dev/sdc
```

Wait until the script finishes, check for any error.

## Use

Once the script returns, you can open Cloudera Manager at [http://\<public-IP\>:7180](http://<public-IP>:7180)

Wait for about 20-30 mins for CDSW to be ready. You can monitor the status of CDSW by issuing the `cdsw status` command.

You can use `kubectl get pods -n kube-system` to check if all the pods that the role `Master` is suppose to start have really started.

You can also check the CDSW deployment status on CM > CDSW service > Instances > Master role > Processes > stdout.

### Docker device

To find out what the docker device mount point is, use `lsblk`. See below examples:


AWS, using a M5.2xlarge or M5.4xlarge
```
$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
nvme0n1     259:1    0  100G  0 disk
+-nvme0n1p1 259:2    0  100G  0 part /
nvme1n1     259:0    0 1000G  0 disk

$ ./setup.sh aws templates/iot_workshop.json /dev/nvme1n1
```

Azure Standard D8s v3 or Standard D16s v3
```
$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
fd0      2:0    1    4K  0 disk
sda      8:0    0   30G  0 disk
+-sda1   8:1    0  500M  0 part /boot
+-sda2   8:2    0 29.5G  0 part /
sdb      8:16   0   56G  0 disk
+-sdb1   8:17   0   56G  0 part /mnt/resource
sdc      8:32   0 1000G  0 disk
sr0     11:0    1  628K  0 rom

$ ./setup.sh azure templates/iot_workshop.json /dev/sdc
```

GCP n1-standard-8 or n1-standard-16
```
$ lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  100G  0 disk
└─sda1   8:1    0  100G  0 part /
sdb      8:16   0 1000G  0 disk

$ ./setup.sh gcp templates/iot_workshop.json /dev/sdb
```
