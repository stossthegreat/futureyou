FROM node:20-alpine AS base
WORKDIR /app

# Install backend dependencies first (better layer caching)
COPY backend/package*.json ./backend/
RUN cd backend && npm ci

# Copy backend source
COPY backend ./backend
WORKDIR /app/backend

# Build (runs prisma generate via script)
RUN npm run build

ENV NODE_ENV=production
EXPOSE 8080
CMD ["npm","start"]


