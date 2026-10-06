# syntax=docker/dockerfile:1.7

# --- Dependencies (prod only) ---
FROM node:20.18-alpine3.20 AS deps
WORKDIR /app
RUN apk add --no-cache libc6-compat \
  && addgroup -g 10001 -S nodejs \
  && adduser -S -u 10001 -G nodejs nodejs
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# --- Build / dev deps for optional compile step ---
FROM node:20.18-alpine3.20 AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --ignore-scripts
COPY src ./src
# Pure JS service: no compile; run tests in CI instead
RUN npm prune --omit=dev

# --- Production runtime ---
FROM node:20.18-alpine3.20 AS runtime
WORKDIR /app

RUN apk add --no-cache dumb-init \
  && addgroup -g 10001 -S nodejs \
  && adduser -S -u 10001 -G nodejs nodejs

ENV NODE_ENV=production \
  PORT=3000

COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=nodejs:nodejs /app/package.json ./
COPY --chown=nodejs:nodejs src ./src

USER nodejs
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:3000/health/live',(r)=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "src/index.js"]
