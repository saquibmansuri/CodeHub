# Using the official Nginx image
FROM nginx

# Creating a directory to hold the static files in Nginx server
RUN mkdir /usr/share/nginx/html/myapp

# Removing default.conf if it exists
RUN if [ -f /etc/nginx/conf.d/default.conf ]; then rm /etc/nginx/conf.d/default.conf; fi

# Copying custom config file to conf.d directory
COPY fe.conf /etc/nginx/conf.d/

# Removing default index.html page
RUN rm /usr/share/nginx/html/index.html

# Copying the static files to the desired directory
COPY /dist/browser/. /usr/share/nginx/html/myapp

# Expose port 80 (default Nginx port)
EXPOSE 80

##########################################################################
#### this is custom fe.conf example
#server {
#    listen       80;
#    #listen  [::]:80;
#    server_name  localhost; #<subdomain.sentra.world>

#    location / {
#        root   /usr/share/nginx/html/sentra;
#        index  index.html index.htm;
#        try_files $uri $uri/ /index.html =404;
#    }
#}
