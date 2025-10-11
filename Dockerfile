FROM node:20-alpine AS base
WORKDIR /app

# Install backend dependencies first (better layer caching)
COPY backend/package*.json ./backend/
# Install deps without running scripts (postinstall) before sources are present
RUN cd backend && npm ci --ignore-scripts

# Copy backend source (including prisma/)
COPY backend ./backend
WORKDIR /app/backend

# Build now that schema exists
RUN npm run build

ENV NODE_ENV=production
EXPOSE 8080
CMD ["npm","start"]


