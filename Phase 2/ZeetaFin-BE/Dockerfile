# Stage 1: Build the NestJS application
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build


# Stage 2: Install production dependencies only
FROM node:20-alpine AS production-deps

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev


# Stage 3: Production image
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=production-deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./

USER node

EXPOSE 3001

CMD ["node", "dist/main"]