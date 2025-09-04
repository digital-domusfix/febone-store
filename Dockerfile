# Simple, reliable: build and run in one image with Yarn
FROM node:20-alpine

# Ensure Yarn via Corepack and use node_modules linker (works for Yarn v1 & v3+)
RUN corepack enable
ENV YARN_NODE_LINKER=node-modules

WORKDIR /app

# Copy only manifests for better Docker layer caching
COPY package.json yarn.lock ./
# If you have Yarn Berry config, keep these too (safe to copy even if absent)
COPY .yarnrc.yml* ./
COPY .yarn/ .yarn/

# Install deps using the lockfile (works with Yarn v1: --frozen-lockfile, Yarn v3+: --immutable)
RUN if [ -f .yarnrc.yml ]; then corepack yarn install --immutable; else corepack yarn install --frozen-lockfile; fi

# Copy the rest of the source
COPY . .

# Build Medusa’s production bundle
RUN npx medusa build

ENV NODE_ENV=production
EXPOSE 9000

# Start Medusa (uses the built bundle)
CMD ["corepack", "yarn", "start"]
