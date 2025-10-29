#!/bin/bash

# 🚀 Run Prisma Migrations on Railway Database
# 
# USAGE:
#   1. Get DATABASE_URL from Railway dashboard:
#      Railway → PostgreSQL service → Variables → Copy DATABASE_URL
#   
#   2. Run this script:
#      export DATABASE_URL="postgresql://postgres:..."
#      bash run-railway-migrations.sh

set -e

echo "🔍 Checking DATABASE_URL..."
if [ -z "$DATABASE_URL" ]; then
    echo "❌ ERROR: DATABASE_URL not set!"
    echo ""
    echo "Please get it from Railway dashboard:"
    echo "  1. Go to https://railway.app/dashboard"
    echo "  2. Click on your futureyou project"
    echo "  3. Click on PostgreSQL service"
    echo "  4. Click 'Variables' tab"
    echo "  5. Copy the DATABASE_URL value"
    echo ""
    echo "Then run:"
    echo "  export DATABASE_URL='postgresql://...'"
    echo "  bash run-railway-migrations.sh"
    exit 1
fi

echo "✅ DATABASE_URL found"
echo ""

echo "📦 Installing dependencies..."
npm install

echo ""
echo "🔄 Generating Prisma Client..."
npx prisma generate

echo ""
echo "🚀 Running migrations..."
npx prisma migrate deploy

echo ""
echo "✅ Migrations complete!"
echo ""
echo "🧪 Testing database connection..."
npx prisma db execute --stdin <<'EOF'
SELECT count(*) FROM "User";
EOF

echo ""
echo "🎉 Database setup complete! Now test your app:"
echo "   cd /home/felix/futureyou"
echo "   flutter run -d chrome"

