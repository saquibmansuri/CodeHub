#!/bin/bash
set -e

echo "Installing docker and compose"
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install docker-compose-plugin
sudo systemctl enable docker

echo "Installing certbot"
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

echo "Installing nginx"
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "Installing aws cli"
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
sudo unzip awscliv2.zip
sudo ./aws/install
