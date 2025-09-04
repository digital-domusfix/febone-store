# Build + run in one image with Yarn
FROM node:20-alpine

# Enable Yarn via Corepack (bundled with Node 20)
RUN corepack enable

# For Yarn 2+/3+, make sure we use node_modules (no PnP)
ENV YARN_NODE_LINKER=node-modules

WORKDIR /app

# Copy only manifests first for better caching
COPY package.json yarn.lock ./
# Copy Yarn Berry config if present; this wildcard won't fail if absent
COPY .yarnrc.yml* ./

# Install deps using the lockfile:
# - Yarn v3+: --immutable
# - Yarn v1:  --frozen-lockfile
RUN if [ -f .yarnrc.yml ]; then \
      corepack yarn install --immutable; \
    else \
      corepack yarn install --frozen-lockfile; \
    fi

# Now copy the rest of your source (no .yarn/ copy needed)
COPY . .

# Build Medusa production bundle
RUN npx medusa build

ENV NODE_ENV=production
EXPOSE 9000

# Start Medusa (uses the built bundle)
CMD ["corepack", "yarn", "start"]
