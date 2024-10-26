########## BUILD STAGE ##########
# Define the base node image for the build stage
FROM node:lts AS build

# Change working directory inside container
WORKDIR /app

# Add arguments and environment variables
# Pass values of these arguments while building the image/project, example- docker compose --build --build-arg ARG1='value' --build-arg ARG2='value' <servicename> 
ARG ARG1
ENV ARG1 $ARG1

ARG ARG2
ENV ARG2 $ARG2

# Copy package.json and package-lock.json for dependency installation
COPY package*.json ./

# Install dependencies
RUN npm install --force

# Copy the rest of your app's source code
COPY . .

# Build the application, use correct build command from the package.json script
RUN npm run build

########## FINAL STAGE ##########
# Final Stage
FROM node:lts AS final

# Change working directory inside container
WORKDIR /app

# Copy only the necessary files from the build stage
COPY --from=build /app/dist /app/dist
COPY --from=build /app/node_modules /app/node_modules

# HOST: Set to 0.0.0.0 to allow external connections
ENV HOST=0.0.0.0

# PORT: Set to 4321 to match the exposed port
ENV PORT=4321

# Expose port 4321 for the application
EXPOSE 4321

# Start the application using Node.js
CMD node ./dist/server/entry.mjs
