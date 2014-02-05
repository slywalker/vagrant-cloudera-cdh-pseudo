#! /bin/sh

cd /home/vagrant/

echo "Add Cloudera repositories"
wget -c http://archive.cloudera.com/cdh4/one-click-install/precise/amd64/cdh4-repository_1.0_all.deb
sudo dpkg -i cdh4-repository_1.0_all.deb
curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key | sudo apt-key add -

sudo apt-get update

echo "Install Java"
sudo apt-get install --force-yes --yes openjdk-7-jdk

echo "Install Hadoop with YARN"
sudo apt-get install --yes hadoop-conf-pseudo

echo "Starting Hadoop and Verifying it is Working Properly"
dpkg -L hadoop-conf-pseudo

echo "Format the NameNode."
sudo -u hdfs hdfs namenode -format

echo "Start HDFS"
for x in `cd /etc/init.d ; ls hadoop-hdfs-*` ; do sudo service $x start ; done

# echo "Remove the old /tmp if it exists:"
# sudo -u hdfs hadoop fs -rm -r /tmp

echo "Create a new /tmp directory and set permissions:"
sudo -u hdfs hadoop fs -mkdir /tmp
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp

echo "Create Staging and Log Directories"
sudo -u hdfs hadoop fs -mkdir /tmp/hadoop-yarn/staging
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp/hadoop-yarn/staging
sudo -u hdfs hadoop fs -mkdir /tmp/hadoop-yarn/staging/history/done_intermediate
sudo -u hdfs hadoop fs -chmod -R 1777 /tmp/hadoop-yarn/staging/history/done_intermediate
sudo -u hdfs hadoop fs -chown -R mapred:mapred /tmp/hadoop-yarn/staging
sudo -u hdfs hadoop fs -mkdir /var/log/hadoop-yarn
sudo -u hdfs hadoop fs -chown yarn:mapred /var/log/hadoop-yarn

echo "Verify the HDFS File Structure:"
sudo -u hdfs hadoop fs -ls -R /

echo "Start YARN"
sudo service hadoop-yarn-resourcemanager restart
sudo service hadoop-yarn-nodemanager restart
sudo service hadoop-mapreduce-historyserver restart

echo "Create User Directories"
sudo -u hdfs hadoop fs -mkdir /user
sudo -u hdfs hadoop fs -chown hive /user
sudo -u hdfs hadoop fs -mkdir /user/vagrant
sudo -u hdfs hadoop fs -chown vagrant /user/vagrant

echo "Install Hive"
sudo apt-get install --yes hive hive-metastore hive-server hive-server2
sudo sh -c "sudo echo 'export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce' >> /etc/default/hive-server2"
sudo cp /etc/hive/conf/hive-site.xml /etc/hive/conf/hive-site.xml.bak
sudo cp /home/vagrant/install/cdh4/hive/hive-site.xml /etc/hive/conf/hive-site.xml

echo "Install MYSQL"
sudo sh -c "echo 'mysql-server-5.5 mysql-server/root_password password root' | debconf-set-selections"
sudo sh -c "echo 'mysql-server-5.5 mysql-server/root_password_again password root' | debconf-set-selections"
sudo apt-get install --force-yes --yes mysql-server
sudo apt-get install --yes libmysql-java
sudo ln -s /usr/share/java/mysql-connector-java.jar /usr/lib/hive/lib/mysql-connector-java.jar

echo "Create Local Metastore..."
sudo mysql -uroot -proot -e "CREATE DATABASE metastore DEFAULT CHARACTER SET 'latin1'"
sudo mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON metastore.* TO hive@localhost IDENTIFIED BY 'hive'"
sudo mysql -uroot -proot -e "FLUSH PRIVILEGES"
sudo mysql -uroot -proot metastore < /usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-0.10.0.mysql.sql

echo "Restart..."
for x in `cd /etc/init.d ; ls hive-*` ; do sudo service $x stop ; done
for x in `cd /etc/init.d ; ls hive-*` ; do sudo service $x start ; done
