import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import OpenAI from "openai";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OpenAI API key not available");
    return null;
  }
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY.trim() });
}

// ===========================
// TYPE DEFINITIONS
// ===========================

export type AIPhase = "observer" | "architect" | "oracle";

export interface TimeWindow {
  time: string;
  description: string;
  frequency: number;
}

export interface Protocol {
  text: string;
  worked_count: number;
  last_used: Date;
}

export interface BehaviorPatterns {
  drift_windows: TimeWindow[];
  consistency_score: number;
  avoidance_triggers: string[];
  return_protocols: Protocol[];
  last_analyzed: Date;
}

export interface ReflectionHistory {
  themes: string[];
  emotional_arc: "ascending" | "flat" | "descending";
  depth_score: number;
}

export interface ArchitectData {
  structural_integrity_score: number;
  system_faults: Array<{ type: string; detected_at: Date; frequency: number }>;
  return_protocols: Protocol[];
  focus_pillars: string[];
  drag_map: Record<string, { severity: number; times: string[] }>;
}

export interface OracleData {
  legacy_code: string[];
  self_knowledge_journal: string[];
  meaning_graph: {
    core_motivations: string[];
    values_ranking: string[];
  };
}

export interface OSPhase {
  current_phase: AIPhase;
  started_at: Date;
  days_in_phase: number;
  phase_transitions: Array<{ from: AIPhase; to: AIPhase; at: Date }>;
}

export interface UserConsciousness {
  // Identity
  identity: {
    name: string;
    age: number | null;
    purpose: string | null;
    coreValues: string[];
    vision: string | null;
    discoveryCompleted: boolean;
  };
  
  // Patterns
  patterns: BehaviorPatterns;
  reflectionHistory: ReflectionHistory;
  
  // Short-term context
  recentConversation: any[];
  currentEmotionalState: string;
  contradictions: string[];
  
  // System metadata
  phase: AIPhase;
  os_phase: OSPhase;
  tone: string;
  nextEvolution: string;
  
  // Phase-specific data
  architect?: ArchitectData;
  oracle?: OracleData;
  
  // Reflection themes for quick access
  reflectionThemes: string[];
  legacyCode: string[];
}

export interface VoiceIntensity {
  curiosity?: number;
  gentleness?: number;
  directness?: number;
  precision?: number;
  authority?: number;
  empathy?: number;
  stillness?: number;
  wisdom?: number;
  mystery?: number;
}

// ===========================
// MEMORY INTELLIGENCE SERVICE
// ===========================

export class MemoryIntelligenceService {
  /**
   * 🧠 CORE FUNCTION: Build complete user consciousness for AI
   */
  async buildUserConsciousness(userId: string): Promise<UserConsciousness> {
    const [user, facts, identity] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.userFacts.findUnique({ where: { userId } }),
      memoryService.getIdentityFacts(userId),
    ]);

    const factsData = (facts?.json as Record<string, any>) || {};
    
    // Get or initialize OS phase
    const os_phase = this.getOrInitializePhase(factsData, user?.createdAt || new Date());
    
    // Determine current phase based on data
    const phase = this.determinePhase(factsData, identity, user?.createdAt || new Date());
    
    // Get behavior patterns
    const patterns: BehaviorPatterns = factsData.behaviorPatterns || {
      drift_windows: [],
      consistency_score: 0,
      avoidance_triggers: [],
      return_protocols: [],
      last_analyzed: new Date(),
    };
    
    // Get reflection history
    const reflectionHistory: ReflectionHistory = factsData.reflectionHistory || {
      themes: [],
      emotional_arc: "flat",
      depth_score: 0,
    };
    
    // Build consciousness object
    const consciousness: UserConsciousness = {
      identity: {
        name: identity.name,
        age: identity.age,
        purpose: identity.purpose,
        coreValues: identity.coreValues || [],
        vision: identity.vision,
        discoveryCompleted: identity.discoveryCompleted,
      },
      patterns,
      reflectionHistory,
      recentConversation: [],
      currentEmotionalState: "balanced",
      contradictions: [],
      phase,
      os_phase,
      tone: user?.tone || "balanced",
      nextEvolution: this.predictNextGrowth(patterns, reflectionHistory, factsData),
      architect: factsData.architect,
      oracle: factsData.oracle,
      reflectionThemes: reflectionHistory.themes || [],
      legacyCode: factsData.oracle?.legacy_code || [],
    };
    
    return consciousness;
  }

  /**
   * 📊 PATTERN EXTRACTION: Learn from Events
   */
  async extractPatternsFromEvents(userId: string): Promise<void> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const events = await prisma.event.findMany({
      where: {
        userId,
        ts: { gte: thirtyDaysAgo },
      },
      orderBy: { ts: "desc" },
    });

    // Analyze habit_tick events for drift windows and consistency
    const habitTicks = events.filter((e) => e.type === "habit_tick");
    const drift_windows = this.findDriftWindows(habitTicks);
    const consistency_score = this.calculateConsistency(habitTicks);

    // Analyze chat_message events for reflection themes
    const chatMessages = events.filter((e) => e.type === "chat_message");
    const reflectionThemes = await this.extractThemesWithAI(chatMessages);
    const depth_score = this.scoreReflectionDepth(chatMessages);

    // Analyze for avoidance patterns
    const avoidance_triggers = this.detectAvoidance(events);

    // Extract return protocols (what works when they recover)
    const return_protocols = this.extractReturnProtocols(events);

    // Update UserFacts with patterns (additive)
    await memoryService.upsertFacts(userId, {
      behaviorPatterns: {
        drift_windows,
        consistency_score,
        avoidance_triggers,
        return_protocols,
        last_analyzed: new Date(),
      },
      reflectionHistory: {
        themes: reflectionThemes,
        depth_score,
        emotional_arc: this.detectEmotionalArc(chatMessages),
      },
    });

    console.log(`✅ Pattern extraction complete for user ${userId}`);
  }

  /**
   * 🎭 PHASE DETERMINATION: Observer → Architect → Oracle
   */
  determinePhase(factsData: any, identity: any, createdAt: Date): AIPhase {
    const daysSinceStart = Math.floor((Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24));
    const reflectionDepth = factsData.reflectionHistory?.depth_score || 0;
    const discoveryComplete = identity.discoveryCompleted;

    // Check if phase is already set
    const currentPhase = factsData.os_phase?.current_phase;

    // Phase 1: OBSERVER (Building trust, learning)
    if (!discoveryComplete || daysSinceStart < 14) {
      return "observer";
    }

    // Phase 2: ARCHITECT (Building systems, 30-60 days)
    if (currentPhase === "architect" || (daysSinceStart >= 14 && reflectionDepth >= 5)) {
      // Only transition to oracle if criteria met
      if (currentPhase === "architect") {
        const daysInPhase = factsData.os_phase?.days_in_phase || 0;
        const consistency = factsData.behaviorPatterns?.consistency_score || 0;
        if (daysInPhase >= 30 && reflectionDepth >= 7 && consistency >= 60) {
          return "oracle";
        }
      }
      return "architect";
    }

    // Phase 3: ORACLE (Meaning & legacy, 60+ days)
    if (currentPhase === "oracle" || (daysSinceStart >= 60 && reflectionDepth >= 7)) {
      return "oracle";
    }

    return currentPhase || "observer";
  }

  /**
   * 🔮 PREDICTIVE: What growth is next?
   */
  predictNextGrowth(patterns: BehaviorPatterns, reflectionHistory: ReflectionHistory, factsData: any): string {
    // If consistency high but meaning low → push toward purpose work
    if (patterns.consistency_score > 70 && reflectionHistory.themes.length < 3) {
      return "deepen_meaning";
    }

    // If avoiding specific triggers → address them directly
    if (patterns.avoidance_triggers.length > 3) {
      return "confront_avoidance";
    }

    // If reflections shallow → encourage depth
    if (reflectionHistory.depth_score < 5) {
      return "deepen_reflection";
    }

    // If drift windows detected → build structure
    if (patterns.drift_windows.length > 2) {
      return "build_structure";
    }

    return "maintain_momentum";
  }

  /**
   * ✅ Check if user should transition to next phase
   */
  shouldTransitionPhase(consciousness: UserConsciousness): boolean {
    const { phase, identity, reflectionHistory, patterns, os_phase } = consciousness;

    // Observer → Architect: Discovery complete + 10 reflections + depth ≥5
    if (phase === "observer") {
      const reflectionCount = reflectionHistory.themes.length;
      return (
        identity.discoveryCompleted &&
        reflectionCount >= 10 &&
        reflectionHistory.depth_score >= 5
      );
    }

    // Architect → Oracle: 30+ days in Architect + depth ≥7 + consistency ≥60%
    if (phase === "architect") {
      const daysInPhase = os_phase.days_in_phase;
      return (
        daysInPhase >= 30 &&
        reflectionHistory.depth_score >= 7 &&
        patterns.consistency_score >= 60
      );
    }

    return false;
  }

  /**
   * 🎨 GRADUAL TONE EVOLUTION: Voice intensity within phases
   */
  determineVoiceIntensity(consciousness: UserConsciousness): VoiceIntensity {
    const { phase, patterns, reflectionHistory, os_phase } = consciousness;

    if (phase === "observer") {
      const progress = Math.min(reflectionHistory.themes.length / 10, 1.0);
      return {
        curiosity: 1.0 - progress * 0.3,
        gentleness: 0.9,
        directness: progress * 0.4,
      };
    } else if (phase === "architect") {
      const integrity = patterns.consistency_score / 100;
      return {
        precision: 0.8 + integrity * 0.2,
        authority: 0.6 + integrity * 0.3,
        empathy: 0.5 - integrity * 0.2,
      };
    } else if (phase === "oracle") {
      const daysInPhase = os_phase.days_in_phase;
      const maturity = Math.min(daysInPhase / 60, 1.0);
      return {
        stillness: 0.5 + maturity * 0.5,
        wisdom: 0.7 + maturity * 0.3,
        mystery: maturity * 0.6,
      };
    }

    return {};
  }

  // ===========================
  // HELPER METHODS
  // ===========================

  private getOrInitializePhase(factsData: any, createdAt: Date): OSPhase {
    if (factsData.os_phase) {
      const daysInPhase = Math.floor(
        (Date.now() - new Date(factsData.os_phase.started_at).getTime()) / (1000 * 60 * 60 * 24)
      );
      return {
        ...factsData.os_phase,
        days_in_phase: daysInPhase,
      };
    }

    return {
      current_phase: "observer",
      started_at: createdAt,
      days_in_phase: Math.floor((Date.now() - createdAt.getTime()) / (1000 * 60 * 60 * 24)),
      phase_transitions: [],
    };
  }

  private findDriftWindows(habitTicks: any[]): TimeWindow[] {
    const hourCounts: Record<number, { total: number; completed: number }> = {};

    habitTicks.forEach((tick) => {
      const hour = new Date(tick.ts).getHours();
      const completed = (tick.payload as any)?.completed || false;

      if (!hourCounts[hour]) {
        hourCounts[hour] = { total: 0, completed: 0 };
      }
      hourCounts[hour].total++;
      if (completed) hourCounts[hour].completed++;
    });

    const driftWindows: TimeWindow[] = [];
    Object.entries(hourCounts).forEach(([hour, counts]) => {
      const completionRate = counts.completed / counts.total;
      if (completionRate < 0.5 && counts.total >= 3) {
        driftWindows.push({
          time: `${hour}:00`,
          description: `Low completion rate (${Math.round(completionRate * 100)}%)`,
          frequency: counts.total,
        });
      }
    });

    return driftWindows.sort((a, b) => b.frequency - a.frequency).slice(0, 3);
  }

  private calculateConsistency(habitTicks: any[]): number {
    if (habitTicks.length === 0) return 0;

    const completed = habitTicks.filter((tick) => (tick.payload as any)?.completed === true).length;
    return Math.round((completed / habitTicks.length) * 100);
  }

  private async extractThemesWithAI(chatMessages: any[]): Promise<string[]> {
    const openai = getOpenAIClient();
    if (!openai || chatMessages.length < 3) return [];

    try {
      const recentMessages = chatMessages
        .slice(0, 20)
        .map((m) => (m.payload as any)?.text || "")
        .filter((t) => t.length > 20)
        .join("\n");

      if (!recentMessages) return [];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_tokens: 200,
        messages: [
          {
            role: "system",
            content:
              "Extract 3-5 recurring themes from these reflections. Return only a JSON array of theme strings.",
          },
          { role: "user", content: recentMessages },
        ],
      });

      const content = completion.choices[0]?.message?.content?.trim() || "[]";
      const themes = JSON.parse(content.replace(/```json|```/g, ""));
      return Array.isArray(themes) ? themes.slice(0, 5) : [];
    } catch (err) {
      console.warn("Failed to extract themes with AI:", err);
      return [];
    }
  }

  private scoreReflectionDepth(chatMessages: any[]): number {
    if (chatMessages.length === 0) return 0;

    const avgLength =
      chatMessages.reduce((sum, m) => sum + ((m.payload as any)?.text?.length || 0), 0) /
      chatMessages.length;

    // Score based on message length and frequency
    const lengthScore = Math.min(avgLength / 100, 5);
    const frequencyScore = Math.min(chatMessages.length / 10, 5);

    return Math.round(lengthScore + frequencyScore);
  }

  private detectAvoidance(events: any[]): string[] {
    const avoidance: Record<string, number> = {};

    events
      .filter((e) => e.type === "habit_action" && (e.payload as any)?.completed === false)
      .forEach((e) => {
        const habitId = (e.payload as any)?.habitId;
        if (habitId) {
          avoidance[habitId] = (avoidance[habitId] || 0) + 1;
        }
      });

    return Object.entries(avoidance)
      .filter(([_, count]) => count >= 5)
      .map(([habitId]) => habitId);
  }

  private extractReturnProtocols(events: any[]): Protocol[] {
    // Look for events after a period of inactivity followed by completion
    const protocols: Protocol[] = [];

    const reflections = events
      .filter((e) => e.type === "chat_message" || e.type === "debrief")
      .slice(0, 10);

    reflections.forEach((r) => {
      const text = (r.payload as any)?.text || "";
      if (text.includes("came back") || text.includes("returned") || text.includes("got back")) {
        protocols.push({
          text: text.slice(0, 100),
          worked_count: 1,
          last_used: r.ts,
        });
      }
    });

    return protocols.slice(0, 5);
  }

  private detectEmotionalArc(chatMessages: any[]): "ascending" | "flat" | "descending" {
    if (chatMessages.length < 5) return "flat";

    // Simple heuristic: look at sentiment keywords
    const recentMessages = chatMessages.slice(0, 10);
    const positive = ["better", "good", "great", "progress", "improved"];
    const negative = ["worse", "struggling", "failed", "hard", "difficult"];

    let posScore = 0;
    let negScore = 0;

    recentMessages.forEach((m) => {
      const text = ((m.payload as any)?.text || "").toLowerCase();
      positive.forEach((word) => {
        if (text.includes(word)) posScore++;
      });
      negative.forEach((word) => {
        if (text.includes(word)) negScore++;
      });
    });

    if (posScore > negScore * 1.5) return "ascending";
    if (negScore > posScore * 1.5) return "descending";
    return "flat";
  }
}

export const memoryIntelligence = new MemoryIntelligenceService();

