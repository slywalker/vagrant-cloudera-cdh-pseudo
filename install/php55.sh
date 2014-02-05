#! /bin/sh

echo "Add ppa:ondrej/php5 repository"
sudo apt-get update
sudo apt-get install -y python-software-properties
sudo add-apt-repository -y ppa:ondrej/php5
sudo apt-get update

echo "Install PHP"
sudo apt-get install -y php5-cli
