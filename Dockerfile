# ---------- build ----------
FROM node:20-alpine AS build
RUN corepack enable
ENV YARN_NODE_LINKER=node-modules
WORKDIR /app

COPY package.json yarn.lock ./
COPY .yarnrc.yml* ./
RUN if [ -f .yarnrc.yml ]; then corepack yarn install --immutable; else corepack yarn install --frozen-lockfile; fi

COPY . .
RUN npx medusa build

# ---------- runtime ----------
FROM node:20-alpine
RUN corepack enable
ENV NODE_ENV=production
ENV YARN_NODE_LINKER=node-modules
WORKDIR /app/.medusa/server

# bring in the built server
COPY --from=build /app/.medusa/server ./

# install runtime deps for the built server
# (Yarn v3+: --immutable; Yarn v1: --frozen-lockfile; fall back to npm if no yarn.lock)
RUN if [ -f yarn.lock ]; then \
      corepack yarn install --immutable --production || corepack yarn install --frozen-lockfile --production; \
    elif [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm i --omit=dev; \
    fi

EXPOSE 9000

# use the CLI that was just installed in THIS folder
CMD sh -c "./node_modules/.bin/medusa db:migrate && node index.js"
