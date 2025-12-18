# syntax=docker/dockerfile:1

ARG NODE_VERSION=24.11.0

#######################################
# Base image
FROM node:${NODE_VERSION}-alpine AS base
WORKDIR /usr/src/app

# Set environment variables
ENV NODE_ENV=production

#######################################
# Dependencies stage (install all deps including dev for build)
FROM base AS deps

# Copy package files
COPY package.json package-lock.json ./

# Install all dependencies including devDependencies
RUN npm ci

#######################################
# Build stage
FROM deps AS build

# Copy rest of the app
COPY . .

# Build the app
RUN npm run build

#######################################
# Production stage
FROM base AS final

# Use non-root user
USER node

# Copy package.json for npm start
COPY package.json ./

# Copy node_modules from deps
COPY --from=deps /usr/src/app/node_modules ./node_modules

# Copy the built Next.js app
COPY --from=build /usr/src/app/.next ./.next
COPY --from=build /usr/src/app/public ./public
COPY --from=build /usr/src/app/next.config.js ./next.config.js

# Expose the port
EXPOSE 3000

# Start the app
CMD ["npm", "start"]
