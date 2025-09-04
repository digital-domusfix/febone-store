# ---------- runtime ----------
FROM node:20-alpine
RUN corepack enable
ENV NODE_ENV=production
ENV YARN_NODE_LINKER=node-modules
WORKDIR /app/.medusa/server

# Copy the built server
COPY --from=build /app/.medusa/server ./

# Install runtime deps for the built server (so ./node_modules/.bin/medusa exists here)
RUN if [ -f yarn.lock ]; then \
      corepack yarn install --immutable --production || corepack yarn install --frozen-lockfile --production; \
    elif [ -f package-lock.json ]; then \
      npm ci --omit=dev; \
    else \
      npm i --omit=dev; \
    fi

EXPOSE 9000

# Run DB migrations, then use the build's own start script (don't hard-code index.js)
CMD sh -c "./node_modules/.bin/medusa db:migrate && corepack yarn start"
