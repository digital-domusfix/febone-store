# --- build stage ---
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
COPY . .
RUN npm ci
RUN npx medusa build

# --- runtime stage ---
FROM node:20-alpine
WORKDIR /app/.medusa/server
ENV NODE_ENV=production
COPY --from=build /app/.medusa/server ./
RUN npm ci --omit=dev
EXPOSE 9000
CMD ["npm","start"]
