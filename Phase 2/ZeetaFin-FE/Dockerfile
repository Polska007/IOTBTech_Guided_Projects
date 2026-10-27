# syntax=docker/dockerfile:1

# ---------- Stage 1: install all dependencies (needed to build) ----------
FROM node:26-alpine AS deps
# Some native Node modules need this compatibility library on Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app
# Copy only the dependency files first so this layer is cached until they change
COPY package.json package-lock.json ./
RUN npm ci

# ---------- Stage 2: build the Next.js app ----------
FROM node:26-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1

ARG NEXT_PUBLIC_API_URL=/api
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# Requires  output: "standalone"  in next.config
RUN npm run build

# ---------- Stage 3: minimal runtime image ----------
FROM node:26-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0

# Create an unprivileged user
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs

# Static files, then the self-contained server produced by the standalone build
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Never run as root
USER nextjs

EXPOSE 3000

# Marks the container unhealthy if the app stops answering
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/ >/dev/null || exit 1

# Exec form so the app receives stop signals
CMD ["node", "server.js"]
