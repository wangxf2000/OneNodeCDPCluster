# Single Node CDP Private Cloud Base Cluster 

This script automatically sets up a CDP Private Cloud Base Trial cluster on the public cloud on a single VM with the services preconfigured in a template file.

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

For example, you can install NIFI once your host looks like the below:

```
$ ls -l /root/
-rw-r--r-- 1 root root 2856094189 Jul  8 11:31 CFM-2.0.1.0-71-el7.parcel
-rw-r--r-- 1 root root         41 Jul  8 11:31 CFM-2.0.1.0-71-el7.parcel.sha
-rw-r--r-- 1 root root      51956 Jul  8 11:31 NIFIREGISTRY-0.6.0.2.0.1.0-71.jar
-rw-r--r-- 1 root root      62604 Jul  8 11:31 NIFI-1.11.4.2.0.1.0-71.jar
```

To install NIFI, you must use an appropriate template file, like `all.json`.

### Configuration and installation
- If you created the VM on Azure and need to resize the OS disk, here are the [instructions](scripts/how-to-resize-os-disk.md).
- add 2 inbound rules to the Security Group:
  - to allow your IP only, for all ports.
  - to allow the VM's own IP, for all ports.
- ssh into VM and copy this repo.

```
sudo su -
yum install -y git unzip
git clone https://github.com/wangxf2000/OneNodeCDPCluster.git
cd OneNodeCDPCluster
```

### local repository prepare
if you use your local repository, you need to do the following first
```
#install the tools 
yum -y install httpd createrepo wget curl
sed -i 's/AddType application\/x-gzip .gz .tgz/AddType application\/x-gzip .gz .tgz .parcel/' /etc/httpd/conf/httpd.conf

#create the local repository directory
mkdir -p /var/www/html/cm7/7.4.4/redhat7/yum/RPMS/x86_64/
mkdir -p /var/www/html/cdh7/7.1.7.0/parcels/
mkdir -p /var/www/html/cdsw1/1.9.2/csd/
mkdir -p /var/www/html/cdsw1/1.9.2/parcels/
mkdir -p /var/www/html/CEM/centos7/1.x/updates/1.2.0.0/
mkdir -p /var/www/html/get/Downloads/Connector-J/
mkdir -p /var/www/html/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/
mkdir -p /var/www/html/CFM/centos7/2.x/updates/2.0.4.0/tars/parcel/
mkdir -p /var/www/html/pkgs/misc/parcels/archive/
mkdir -p /var/www/html/csa/1.4.1.0/parcels/
mkdir -p /var/www/html/csa/1.4.1.0/csd/
```

### download the public repository to your local directory
```
wget -nd -r  -l1 --no-parent https://username:password@archive.cloudera.com/p/cm7/7.4.4/redhat7/yum/RPMS/x86_64/ -P /var/www/html/cm7/7.4.4/redhat7/yum/RPMS/x86_64/
wget https://username:password@archive.cloudera.com/p/cm7/7.4.4/redhat7/yum/RPM-GPG-KEY-cloudera -P /var/www/html/cm7/7.4.4/redhat7/yum
wget https://username:password@archive.cloudera.com/p/cm7/7.4.4/redhat7/yum/cloudera-manager-trial.repo -P /var/www/html/cm7/7.4.4/redhat7/yum
wget https://username:password@archive.cloudera.com/p/cm7/7.4.4/redhat7/yum/cloudera-manager.repo -P /var/www/html/cm7/7.4.4/redhat7/yum
wget https://username:password@archive.cloudera.com/p/cm7/7.4.4/allkeys.asc -P /var/www/html/cm7/7.4.4
wget https://username:password@archive.cloudera.com/p/cdh7/7.1.7.0/parcels/CDH-7.1.7-1.cdh7.1.7.p0.15945976-el7.parcel -P /var/www/html/cdh7/7.1.7.0/parcels/
wget https://username:password@archive.cloudera.com/p/cdh7/7.1.7.0/parcels/CDH-7.1.7-1.cdh7.1.7.p0.15945976-el7.parcel.sha256 -P /var/www/html/cdh7/7.1.7.0/parcels/
wget https://username:password@archive.cloudera.com/p/cdh7/7.1.7.0/parcels/manifest.json -P /var/www/html/cdh7/7.1.7.0/parcels/
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz -P /var/www/html/get/Downloads/Connector-J/
wget http://central.maven.org/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/nifi-mqtt-nar-1.8.0.nar -P /var/www/html/maven2/org/apache/nifi/nifi-mqtt-nar/1.8.0/
wget https://repo.anaconda.com/pkgs/misc/parcels/Anaconda-2020.11-el7.parcel.sha  -P /var/www/html/pkgs/misc/parcels/archive/
wget https://repo.anaconda.com/pkgs/misc/parcels/Anaconda-2020.11-el7.parcel.sha -P /var/www/html/pkgs/misc/parcels/archive/
wget https://repo.continuum.io/pkgs/misc/parcels/archive/manifest.json -P /var/www/html/pkgs/misc/parcels/archive/
rm -rf /var/www/html/cm7/7.4.4/redhat7/yum/RPMS/x86_64/index.html
rm -rf /var/www/html/cm7/7.4.4/redhat7/yum/RPMS/x86_64/robots.txt
```
### replace username and password with your license's username and password, if you need CEM,CFM, CSA and CDSW 
```
#cdsw
wget https://username:password@archive.cloudera.com/p/cdsw1/1.9.2/parcels/CDSW-1.9.2.p1.14556745-el7.parcel -P /var/www/html/cdsw1/1.9.2/parcels/
wget https://username:password@archive.cloudera.com/p/cdsw1/1.9.2/parcels/CDSW-1.9.2.p1.14556745-el7.parcel.sha -P /var/www/html/cdsw1/1.9.2/parcels/
wget https://username:password@archive.cloudera.com/p/cdsw1/1.9.2/parcels/manifest.json -P /var/www/html/cdsw1/1.9.2/parcels/
wget https://username:password@archive.cloudera.com/p/cdsw1/1.9.2/csd/CLOUDERA_DATA_SCIENCE_WORKBENCH-CDPDC-1.9.2.jar -P /var/www/html/cdsw1/1.9.2/csd/

#CFM
wget https://username:password@archive.cloudera.com/p/CFM/2.x/redhat7/yum/tars/parcel/manifest.json   -P /var/www/html/CFM/2.x/redhat7/yum/tars/parcel
wget https://username:password@archive.cloudera.com/p/CFM/2.x/redhat7/yum/tars/parcel/CFM-2.0.4.0-80-el7.parcel   -P /var/www/html/CFM/2.x/redhat7/yum/tars/parcel
wget https://username:password@archive.cloudera.com/p/CFM/2.x/redhat7/yum/tars/parcel/CFM-2.0.4.0-80-el7.parcel.sha  -P /var/www/html/CFM/2.x/redhat7/yum/tars/parcel
wget https://username:password@archive.cloudera.com/p/CFM/2.x/redhat7/yum/tars/parcel/NIFIREGISTRY-0.6.0.2.0.4.0-80.jar -P /var/www/html/CFM/2.x/redhat7/yum/tars/parcel
wget https://username:password@archive.cloudera.com/p/CFM/2.x/redhat7/yum/tars/parcel/NIFI-1.11.4.2.0.4.0-80.jar  -P /var/www/html/CFM/2.x/redhat7/yum/tars/parcel

#CSA
wget https://username:password@archive.cloudera.com/p/csa/1.4.1.0/parcels/FLINK-1.12-csa1.4.1.0-cdh7.1.6.0-297-15479260-el7.parcel -P /var/www/html/csa/1.4.1.0/parcels/
wget https://username:password@archive.cloudera.com/p/csa/1.4.1.0/parcels/FLINK-1.12-csa1.4.1.0-cdh7.1.6.0-297-15479260-el7.parcel.sha -P /var/www/html/csa/1.4.1.0/parcels/
wget https://username:password@archive.cloudera.com/p/csa/1.4.1.0/parcels/manifest.json -P /var/www/html/csa/1.4.1.0/parcels/
wget https://username:password@archive.cloudera.com/p/csa/1.4.1.0/csd/FLINK-1.12-csa1.4.1.0-cdh7.1.6.0-297-15479260.jar -P /var/www/html/csa/1.4.1.0/csd/
wget https://username:password@archive.cloudera.com/p/csa/1.4.1.0/csd/SQL_STREAM_BUILDER-1.12-csa1.4.1.0-cdh7.1.6.0-297-15479260.jar -P /var/www/html/csa/1.4.1.0/csd/

#CEM
wget https://username:password@archive.cloudera.com/p/CEM/centos7/1.x/updates/1.2.1.0/CEM-1.2.1.0-centos7-tars-tarball.tar.gz  -P /var/www/html/CEM/centos7/1.x/updates/1.2.1.0/
```
### create the cm7's repo information and replace the link to your local repository
```
cd /var/www/html/cm7/7.4.4/redhat7/yum/
createrepo .
sed -i "s?https://archive.cloudera.com/p?http://`hostname -f`?g" /var/www/html/cm7/7.4.4/redhat7/yum/cloudera-manager.repo
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" /var/www/html/cm7/7.4.4/redhat7/yum/cloudera-manager-trial.repo

### replace cloudera repository to your own repository 
### if your repository is the same as your Edge2AI Server, you can use the following replace statement.
### otherwise, update the statement with your own IP address
### modify the repository in setup.sh, scripts/create_cluster.py ,templates/*json files
sed -i "s?https://archive.cloudera.com/p?http://`hostname -f`?g" ~/OneNodeCDPCluster/setup*.sh
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDPCluster/setup*.sh
sed -i "s/central.maven.org/`hostname -f`/g" ~/OneNodeCDPCluster/setup*.sh
sed -i "s?https://archive.cloudera.com/p?http://`hostname -f`?g" ~/OneNodeCDPCluster/setup*.sh
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDPCluster/setup*.sh
sed -i "s?https://dev.mysql.com?http://`hostname -f`?g" ~/OneNodeCDPCluster/setup*.sh
sed -i "s?https://archive.cloudera.com/p?http://`hostname -f`?g" ~/OneNodeCDPCluster/templates/*.json
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDPCluster/templates/*.json
sed -i "s?https://repo.continuum.io?http://`hostname -f`?g" ~/OneNodeCDPCluster/templates/*.json
sed -i "s?https://archive.cloudera.com/p?http://`hostname -f`?g" ~/OneNodeCDPCluster/scripts/create_cluster*.py
sed -i "s?https://archive.cloudera.com?http://`hostname -f`?g" ~/OneNodeCDPCluster/scripts/create_cluster*.py


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
