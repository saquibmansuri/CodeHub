# This repository explains how to setup basic authentication using NGINX
Reference - https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/

## Step 1 
Install nginx
```
sudo apt install nginx -y
```

## Step 2
Go to /etc/nginx directory and run these commands to setup users with their encrypted password
```
sudo sh -c "echo -n 'SAQUIB:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/.htpasswd"    (this command will ask for the password for the above user as a prompt)
```

Add new user in similar manner
```
sudo sh -c "echo -n 'NEW_USER:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/.htpasswd" (this command will ask for the password for the above user as a prompt)
```

NOTE: 1. You can't use multiple passwords for same user
      2. To delete any user, simple delete it from the file /etc/nginx/.htpasswd
      3. To change password for a particular user - first delete the user and then recreate the user with the new password


## Step 3
Setup basic conf file in sites-available and link it to sites-enabled directory and add "auth_basic" property
```
upstream test_servers {
  server localhost:8080;
}
server {
  listen 80;
  # server_name test.saquib.publicvm.com ;
  location / {
    proxy_pass http://test_servers;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    auth_basic "Restricted Content";
    auth_basic_user_file /etc/nginx/.htpasswd;
  }
}
```

## Step 4
```
sudo systemctl reload nginx
```
