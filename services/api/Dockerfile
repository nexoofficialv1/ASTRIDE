FROM node:20-alpine AS deps
WORKDIR /app
COPY services/api/package*.json ./services/api/
RUN cd services/api && npm ci --omit=dev

FROM node:20-alpine AS runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=deps /app/services/api/node_modules ./services/api/node_modules
COPY services/api ./services/api
COPY packages ./packages
COPY apps/admin_control_console ./apps/admin_control_console
ENV NODE_ENV=production
USER app
WORKDIR /app/services/api
EXPOSE 3333
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD wget -qO- http://127.0.0.1:3333/health || exit 1
CMD ["node", "src/server.mjs"]
