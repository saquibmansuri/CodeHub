# Stage 1: Build the Angular project 
FROM node:22 AS builder # choose node version that is supported by your app

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package.json package-lock.json ./

# Install dependencies with npm ci (using --force to override potential issues)
RUN npm ci --force

# Copy the rest of the application source code
COPY . .

# Build the Angular project (this command can be found in the scripts section in package.json && and angular.json should have the block for this script)
RUN npm run build-myapp

######################################################################

# Stage 2: Serve the static files with Nginx
FROM nginx:alpine

# Set the Nginx static files directory
RUN mkdir -p /usr/share/nginx/html/myapp

# Remove the default Nginx configuration, if it exists
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy your custom Nginx configuration
COPY fe.conf /etc/nginx/conf.d/

# Copy static files from the build stage to the Nginx static directory
COPY --from=builder /app/dist/path/to/staticfiles/. /usr/share/nginx/html/myapp

# Expose port 80 (default for Nginx)
EXPOSE 80

# Start Nginx when the container runs
CMD ["nginx", "-g", "daemon off;"]
