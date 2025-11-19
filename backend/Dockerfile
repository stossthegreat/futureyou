FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
# Use --legacy-peer-deps for chromadb compatibility with openai@6
RUN npm ci --only=production --legacy-peer-deps

# Copy built application
COPY dist/ ./dist/
COPY prisma/ ./prisma/

# Expose port
EXPOSE 3000

# Start the scheduler worker
CMD ["node", "dist/workers/scheduler.worker.js"]