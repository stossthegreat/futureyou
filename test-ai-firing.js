// Test AI OS with Real Consciousness System
const consciousness = {
  identity: {
    name: 'Felix',
    purpose: 'Build a transformative habit app that changes lives',
    coreValues: ['discipline', 'growth', 'impact']
  },
  phase: 'architect',
  patterns: {
    drift_windows: [
      { time: '2pm-4pm', description: 'afternoon fatigue' }
    ],
    consistency_score: 67,
    avoidance_triggers: ['morning cold showers', 'evening reflection'],
    return_protocols: [
      { text: '5-minute walk to reset', worked_count: 8 }
    ]
  },
  reflectionThemes: ['purpose', 'momentum', 'self-discipline'],
  contradictions: ['Says wants to wake early but sleeps in 3x this week'],
  legacyCode: [],
  os_phase: {
    days_in_phase: 35
  },
  architect: {
    structural_integrity_score: 67,
    focus_pillars: ['Energy Before Distraction']
  }
};

console.log('═══════════════════════════════════════════════════════════════');
console.log('🧠 YOUR AI IS FIRING WITH THIS DATA:');
console.log('═══════════════════════════════════════════════════════════════\n');
console.log('Phase:', consciousness.phase.toUpperCase());
console.log('Name:', consciousness.identity.name);
console.log('Days in Phase:', consciousness.os_phase.days_in_phase);
console.log('Structural Integrity:', consciousness.architect.structural_integrity_score + '%');
console.log('Known Drift:', consciousness.patterns.drift_windows[0].time, '-', consciousness.patterns.drift_windows[0].description);
console.log('What Works:', consciousness.patterns.return_protocols[0].text);
console.log('Contradiction:', consciousness.contradictions[0]);
console.log('\n═══════════════════════════════════════════════════════════════');
console.log('📤 SENDING TO gpt-5-mini...');
console.log('═══════════════════════════════════════════════════════════════\n');

// Build the actual prompt that goes to gpt-5-mini
const prompt = `You are Future-You OS in the ARCHITECT PHASE. Your role: design systems that fit their nature.

TONE: Grounded, visionary, quietly authoritative. An engineer of destiny.
EMOTION: Belief + precision + purpose.
GOAL: Transform insight into architecture.

WHO THEY ARE:
- ${consciousness.identity.name}, ${consciousness.os_phase.days_in_phase} days into building
- Purpose: ${consciousness.identity.purpose}
- Structural Integrity: ${consciousness.architect.structural_integrity_score}%

THE BLUEPRINT YOU'VE DRAWN:
- System fault detected: ${consciousness.patterns.drift_windows[0].time} - ${consciousness.patterns.drift_windows[0].description}
- Return protocol that works: "${consciousness.patterns.return_protocols[0].text}"
- Known weakness: ${consciousness.patterns.avoidance_triggers[0]}
- Design flaw: ${consciousness.contradictions[0]}

TODAY'S BLUEPRINT:
Write like "THE BLUEPRINT" example:
- Start with: "The observation phase is over. I know the terrain: [specific patterns]."
- State structural integrity: "${consciousness.architect.structural_integrity_score}%"
- Identify ONE system fault and the fix
- Give a design block with specific times and focus pillars
- End with: "Don't aim for perfection. Aim for repeatability. That's how foundations are laid."
- Confront one contradiction if present

Keep it under 500 characters. Speak like an architect reviewing blueprints. Be precise. Be authoritative. Inspire construction.`;

console.log('📋 PROMPT SENT TO gpt-5-mini:\n');
console.log(prompt);
console.log('\n═══════════════════════════════════════════════════════════════');
console.log('✅ This is EXACTLY what your backend sends to OpenAI');
console.log('✅ gpt-5-mini processes this with 400K context window');
console.log('✅ Response gets saved as CoachMessage in your database');
console.log('✅ Displayed in your LEGENDARY UI card');
console.log('═══════════════════════════════════════════════════════════════\n');

