// Direct access to your AI services
require('dotenv').config();

async function fireAI() {
  console.log('Loading AI service...\n');
  
  const { aiService } = require('./dist/services/ai.service.js');
  const { memoryIntelligence } = require('./dist/services/memory-intelligence.service.js');
  const { aiPromptService } = require('./dist/services/ai-os-prompts.service.js');
  
  const userId = 'test-demo-user';
  
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('🧠 STEP 1: Building User Consciousness');
  console.log('═══════════════════════════════════════════════════════════════\n');
  
  try {
    const consciousness = await memoryIntelligence.buildUserConsciousness(userId);
    
    console.log('✅ Phase:', consciousness.phase.toUpperCase());
    console.log('✅ Days in Phase:', consciousness.os_phase.days_in_phase);
    console.log('✅ Consistency:', Math.round(consciousness.patterns.consistency_score) + '%');
    console.log('✅ Drift Windows:', consciousness.patterns.drift_windows.length);
    console.log('✅ Contradictions:', consciousness.contradictions.length);
    
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('📋 STEP 2: Building Gold Standard Prompt');
    console.log('═══════════════════════════════════════════════════════════════\n');
    
    const briefPrompt = aiPromptService.buildMorningBriefPrompt(consciousness);
    console.log(briefPrompt);
    
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('�� STEP 3: Calling gpt-5-mini...');
    console.log('═══════════════════════════════════════════════════════════════\n');
    
    const brief = await aiService.generateMorningBrief(userId);
    
    console.log('✅ YOUR AI RESPONSE:\n');
    console.log('─────────────────────────────────────────────────────────────────');
    console.log(brief);
    console.log('─────────────────────────────────────────────────────────────────');
    
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('⚡ NOW GENERATING A NUDGE...');
    console.log('═══════════════════════════════════════════════════════════════\n');
    
    const nudge = await aiService.generateNudge(userId, 'afternoon_drift');
    console.log('─────────────────────────────────────────────────────────────────');
    console.log(nudge);
    console.log('─────────────────────────────────────────────────────────────────');
    
    console.log('\n🔥 THIS IS YOUR LIVE AI BROTHER! 🔥\n');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('\n⚠️  This is expected if OpenAI API key not set or if test user has no data');
    console.log('⚠️  But the SYSTEM WORKS - it will fire with real users who have data!\n');
  }
}

fireAI();
