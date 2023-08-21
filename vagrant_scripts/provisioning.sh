#!/bin/bash

echo "---- update package list ----"
apt-get update
apt-get -y --fix-broken install

echo "---- setting up postgresql ----"
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
 wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
apt-get update
apt-get install -y postgresql-15 postgresql-client-15
sudo -u postgres psql <<EOF
CREATE ROLE developper WITH LOGIN PASSWORD '12345' SUPERUSER CREATEDB;
CREATE DATABASE developper;
GRANT ALL PRIVILEGES ON DATABASE developper TO developper;
EOF
echo "configuring remote access to PostgreSQL..."
cat <<EOF | sudo tee -a /etc/postgresql/15/main/postgresql.conf
#
# Custom settings
#
listen_addresses = '*'
EOF
cat <<EOF | sudo tee -a /etc/postgresql/15/main/pg_hba.conf
#
# Custom settings
#
host    all             all             0.0.0.0/0            md5
EOF
service postgresql restart

echo "---- install nodejs ----"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs
npm install pm2 -g

echo "---- setting up docker ----"
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker vagrant


echo "---- setting up nginx ----"
apt-get install -y nginx
bash /vagrant_scripts/configure_nginx.sh
nginx -s reload
ufw allow 80
