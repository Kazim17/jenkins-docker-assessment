# Stage 1: Build & Test
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
COPY --from=builder /app/src ./src

EXPOSE 3000
USER node
CMD ["node", "src/index.js"]
