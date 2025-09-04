# ---------- build stage ----------
FROM node:20-alpine AS builder
RUN corepack enable
ENV YARN_NODE_LINKER=node-modules
WORKDIR /app

# Copy manifests first for better layer cache
COPY package.json yarn.lock ./
COPY .yarnrc.yml* ./

# Install deps from lockfile (works for Yarn v1 or v3+)
RUN if [ -f .yarnrc.yml ]; then \
      corepack yarn install --immutable; \
    else \
      corepack yarn install --frozen-lockfile; \
    fi

# Copy the rest of the source and build the production bundle
COPY . .
RUN npx medusa build

# ---------- runtime stage ----------
FROM node:20-alpine
RUN corepack enable
ENV NODE_ENV=production
ENV YARN_NODE_LINKER=node-modules
WORKDIR /app/.medusa/server

# Bring in ONLY the built server
COPY --from=builder /app/.medusa/server ./

# Install runtime deps for the built server (so ./node_modules/.bin/medusa exists here)
RUN if [ -f yarn.lock ]; then \
      corepack yarn install --immutable --production || corepack yarn install --frozen-lockfile --production; \
    elif [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm i --omit=dev; \
    fi

EXPOSE 9000

# Run DB migrations, then start using the built package's start script
CMD sh -c "./node_modules/.bin/medusa db:migrate && corepack yarn start"
