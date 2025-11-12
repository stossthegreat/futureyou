#!/usr/bin/env node

const { execSync } = require('child_process');

const DATABASE_URL = "postgresql://postgres:xzOUjBEfMEIbBcSFPaqxGjlhsFJnZsxm@crossover.proxy.rlwy.net:48939/railway";

console.log('🚀 Setting up Railway database...\n');

try {
  console.log('📦 Installing dependencies...');
  execSync('npm install --no-save prisma @prisma/client', { stdio: 'inherit' });
  
  console.log('\n🔄 Pushing schema to database...');
  execSync(`DATABASE_URL="${DATABASE_URL}" npx prisma db push --skip-generate --accept-data-loss`, { 
    stdio: 'inherit',
    timeout: 30000 
  });
  
  console.log('\n✅ Database setup complete!');
  console.log('\n🧪 Test user creation:');
  console.log('curl -X POST https://futureyou-production.up.railway.app/api/v1/users \\');
  console.log('  -H "Content-Type: application/json" \\');
  console.log('  -H "x-user-id: test123" \\');
  console.log('  -d "{}"');
  
} catch (error) {
  console.error('\n❌ Error:', error.message);
  process.exit(1);
}

