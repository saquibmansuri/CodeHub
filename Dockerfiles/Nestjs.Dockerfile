# Build stage
FROM node:22 AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

###########################

# Production stage
FROM node:22-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Copy .env file
COPY .env ./

# Copy prisma directory
COPY prisma ./prisma

# Copy startup script
COPY startup.sh ./

# Make the startup script executable
RUN chmod +x ./startup.sh

# Generate prisma client
RUN npx prisma generate

# Expose the port the app runs on
EXPOSE 3001

# Start the application using the startup script
CMD ["sh", "startup.sh"]



########### Startup.sh Content ##############
##!/bin/bash
#echo "Performing database migrations..."
#npx prisma migrate deploy

#echo "Starting the application..."
#node dist/src/main.js
#############################################
