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
WORKDIR /app/.medusa/server
ENV NODE_ENV=production
COPY --from=build /app/.medusa/server ./
# run migrations then boot
CMD sh -c "node ../../node_modules/.bin/medusa db:migrate && node index.js"
EXPOSE 9000
