#!/usr/bin/env node

const { Client } = require('pg');
const fs = require('fs');

const DATABASE_URL = "postgresql://postgres:xzOUjBEfMEIbBcSFPaqxGjlhsFJnZsxm@crossover.proxy.rlwy.net:48939/railway";

async function runSQL() {
  const client = new Client({ connectionString: DATABASE_URL });
  
  try {
    console.log('🔌 Connecting to Railway database...');
    await client.connect();
    console.log('✅ Connected!\n');
    
    console.log('📖 Reading SQL file...');
    const sql = fs.readFileSync('./create-tables.sql', 'utf8');
    
    console.log('🚀 Creating tables...');
    await client.query(sql);
    
    console.log('✅ All tables created successfully!\n');
    
    // Test query
    console.log('🧪 Testing database...');
    const result = await client.query('SELECT count(*) FROM "User"');
    console.log(`✓ User table exists (${result.rows[0].count} users)\n`);
    
    console.log('🎉 Database setup complete!');
    console.log('\n📱 Now test your app:');
    console.log('   cd /home/felix/futureyou');
    console.log('   flutter run -d chrome');
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.message.includes('already exists')) {
      console.log('\n✅ Tables already exist! Database is ready.');
    } else {
      process.exit(1);
    }
  } finally {
    await client.end();
  }
}

runSQL();

