# syntax=docker/dockerfile:1

ARG NODE_VERSION=20.11.1

#######################################
# Base image
FROM node:${NODE_VERSION}-alpine AS base
WORKDIR /usr/src/app

# Required for some Node modules
RUN apk add --no-cache libc6-compat

#######################################
# Dependencies stage (production only)
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

#######################################
# Build stage (includes devDependencies)
FROM base AS build
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Build-time secrets (passed from GitHub Actions)
ARG BETTER_AUTH_SECRET
ARG BETTER_AUTH_URL
ARG DATABASE_URL
ENV BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
ENV BETTER_AUTH_URL=${BETTER_AUTH_URL}
ENV DATABASE_URL=${DATABASE_URL}

RUN npm run build

#######################################
# Runtime stage (minimal)
FROM base AS final
WORKDIR /usr/src/app
ENV NODE_ENV=production
USER node

COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/.next ./.next
COPY --from=build /usr/src/app/public ./public
COPY --from=build /usr/src/app/package.json ./package.json

EXPOSE 3000
CMD ["npm", "start"]
