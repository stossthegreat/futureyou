#!/bin/bash
# Run Prisma migrations
# This script can be run manually or as part of deployment

echo "🔄 Running Prisma migrations..."

cd "$(dirname "$0")/.." || exit 1

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  echo "❌ ERROR: DATABASE_URL environment variable is not set"
  exit 1
fi

echo "📊 Database URL: ${DATABASE_URL:0:20}..."

# Run migrations
npx prisma migrate deploy

if [ $? -eq 0 ]; then
  echo "✅ Migrations completed successfully!"
else
  echo "❌ Migration failed!"
  exit 1
fi

