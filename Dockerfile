# syntax=docker/dockerfile:1

ARG NODE_VERSION=20.11.1

################################################################################
# Base image
FROM node:${NODE_VERSION}-alpine AS base

WORKDIR /usr/src/app

################################################################################
# Dependencies stage (production only)
FROM base AS deps

RUN apk add --no-cache libc6-compat

COPY package.json package-lock.json ./

RUN npm ci --omit=dev

################################################################################
# Build stage
FROM base AS build

RUN apk add --no-cache libc6-compat

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

RUN npm run build

################################################################################
# Runtime stage (minimal)
FROM base AS final

ENV NODE_ENV=production

# Create non-root user
USER node

WORKDIR /usr/src/app

COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/.next ./.next
COPY --from=build /usr/src/app/public ./public
COPY --from=build /usr/src/app/package.json ./package.json

EXPOSE 3000

CMD ["npm", "start"]
