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
COPY /dist/path/to/staticfiles/. /usr/share/nginx/html/myapp

# Expose port 80 (default Nginx port)
EXPOSE 80
