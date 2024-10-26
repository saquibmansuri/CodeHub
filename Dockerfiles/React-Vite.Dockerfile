################## Build stage ##################################

# Use desired/latest Node.js image as the base for building the application
FROM node:20 as build-stage       

# Set the working directory inside the container to /app
WORKDIR /app

# Add arguments and environment variables
# These arguments can be passed inside dockerfile while building the image/project, example - docker compose build --build-arg ARG1='value'....
ARG ARG1
ENV ARG1 $ARG1

ARG ARG2
ENV ARG2 $ARG2

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./             

# Install all dependencies defined in package.json necessary for building the application
RUN npm install                   

# Copy all application source files to the working directory
COPY . .                          

# Build the application with the configured build script in package.json
RUN npm run build

################################ Production stage #########################################

# Use a slim version of Node.js for a lightweight production image
FROM node:20-slim                 

# Set the working directory inside the container to /app
WORKDIR /app                      

# Copy the built application files from the build stage to production stage
# Ensure this directory matches the output directory used by Vite, in this case it is 'dist'
COPY --from=build-stage /app/dist /app/build   

# Install the `serve` package globally to serve static files in the production environment
RUN npm install -g serve          

# Expose port for serving the application
EXPOSE 80                       

# Run the `serve` command to host the application on port 80
CMD ["serve", "-s", "build", "-l", "80"]
