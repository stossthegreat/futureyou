#!/bin/bash
# Force Prisma migration deployment on production
echo "🔄 Deploying Prisma migrations..."
npx prisma migrate deploy
echo "✅ Migrations deployed!"

