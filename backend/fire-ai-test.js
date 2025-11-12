const fetch = require('node-fetch');

async function fireAI() {
  const userId = 'iUuMNoVLeyNpn9eMP9xaBY4howt1'; // Your actual user ID from logs
  
  console.log('🧠 Building consciousness for user:', userId);
  console.log('📡 Calling: https://futureyou-production.up.railway.app/admin/consciousness/' + userId);
  console.log('');
  
  try {
    const response = await fetch(
      `https://futureyou-production.up.railway.app/admin/consciousness/${userId}`,
      {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );
    
    if (!response.ok) {
      console.log('❌ Response not OK:', response.status, response.statusText);
      const text = await response.text();
      console.log('Response:', text);
      return;
    }
    
    const consciousness = await response.json();
    
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('✅ YOUR ACTUAL USER CONSCIOUSNESS:');
    console.log('═══════════════════════════════════════════════════════════════\n');
    console.log('Phase:', consciousness.phase?.toUpperCase() || 'OBSERVER');
    console.log('Days in Phase:', consciousness.os_phase?.days_in_phase || 0);
    console.log('Purpose:', consciousness.identity?.purpose || 'Discovering...');
    console.log('Consistency Score:', Math.round(consciousness.patterns?.consistency_score || 0) + '%');
    console.log('Drift Windows:', consciousness.patterns?.drift_windows?.length || 0);
    console.log('Return Protocols:', consciousness.patterns?.return_protocols?.length || 0);
    console.log('Reflections:', consciousness.reflectionHistory?.themes?.length || 0);
    console.log('Contradictions:', consciousness.contradictions?.length || 0);
    
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('🎯 FULL CONSCIOUSNESS DATA:');
    console.log('═══════════════════════════════════════════════════════════════\n');
    console.log(JSON.stringify(consciousness, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

fireAI();
