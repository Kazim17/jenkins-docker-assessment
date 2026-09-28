# Stage 1: Build & Unit Test
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run test

# Stage 2: Production Runtime
FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production

# Copy root app files directly (e.g., index.js)
COPY --from=builder /app/index.js ./index.js

EXPOSE 3000
USER node
CMD ["node", "index.js"]
