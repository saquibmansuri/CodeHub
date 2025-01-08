# Multistage Dockerfile
# Stage 1: Install all dependencies/packages
# Stage 2: Build the application
# Stage 3: Setup runtime environment
########################################################################################

# Stage 1: Install Dependencies
FROM node:22.12.0-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json from the front directory
COPY --chown=appuser:appgroup package*.json ./

# Install dependencies
RUN npm ci

########################################################################################

# Stage 2: Rebuild the source code only when needed
FROM base AS builder

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy node modules from base image
COPY --from=deps --chown=appuser:appgroup /usr/src/app/node_modules ./node_modules

# Copy the rest of your application's code
COPY --chown=appuser:appgroup . .

# Build the app for production
RUN npm run build

########################################################################################

# Stage 2: Setup the runtime container
FROM base AS runner

# Create a non-root user and group in the runtime stage
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set the working directory in the container
WORKDIR /usr/src/app

# Optimize the application for production
ENV NODE_ENV=production

# Set max HTTP header size environment variable
ENV NODE_OPTIONS="--max-http-header-size=32768"

# Copy only the build artifacts and other necessary files like npm packages
COPY --from=builder --chown=appuser:appgroup /usr/src/app/.next ./.next
COPY --from=builder --chown=appuser:appgroup /usr/src/app/package*.json ./
COPY --from=builder --chown=appuser:appgroup /usr/src/app/startup.sh ./startup.sh
# COPY --from=builder --chown=appuser:appgroup /usr/src/app/node_modules ./node_modules

# Ensure the startup script is executable
RUN chmod +x ./startup.sh

# Switch to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 3000

# Start the app using the startup script
CMD ["sh", "startup.sh"]



#####################################################################################

## CONTENT OF startup.sh

##!/bin/sh
## Startup message
#echo "Docker image setup complete, starting now....."
## Start the application
#NODE_OPTIONS="$NODE_OPTIONS --max-http-header-size=32768" npm start

