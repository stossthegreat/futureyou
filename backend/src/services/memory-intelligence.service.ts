import { prisma } from "../utils/db";
import { memoryService } from "./memory.service";
import OpenAI from "openai";

const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o";

function getOpenAIClient() {
  if (process.env.NODE_ENV === "build" || process.env.RAILWAY_ENVIRONMENT === "build") return null;
  if (!process.env.OPENAI_API_KEY) return null;
  return new OpenAI({ apiKey: process.env.OPENAI_API_KEY.trim() });
}

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
  impact_theme?: string;
}

export interface OSPhase {
  current_phase: AIPhase;
  started_at: Date;
  days_in_phase: number;
  phase_transitions: Array<{ from: AIPhase; to: AIPhase; at: Date }>;
}

export interface UserConsciousness {
  identity: {
    name: string;
    age: number | null;
    purpose: string | null;
    coreValues: string[];
    vision: string | null;
    discoveryCompleted: boolean;
    createdAt?: Date;
  };

  patterns: BehaviorPatterns;
  reflectionHistory: ReflectionHistory;

  recentConversation: any[];
  currentEmotionalState: string;
  contradictions: string[];

  phase: AIPhase;
  os_phase: OSPhase;
  tone: string;
  nextEvolution: string;

  architect?: ArchitectData;
  oracle?: OracleData;

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

export class MemoryIntelligenceService {
  // ============================================================
  // 🧠 Build User Consciousness
  // ============================================================
  async buildUserConsciousness(userId: string): Promise<UserConsciousness> {
    const [user, facts, identity] = await Promise.all([
      prisma.user.findUnique({ where: { id: userId } }),
      prisma.userFacts.findUnique({ where: { userId } }),
      memoryService.getIdentityFacts(userId),
    ]);

    const factsData = (facts?.json as any) || {};
    const createdAt = user?.createdAt || new Date();

    const os_phase = this.getOrInitializePhase(factsData, createdAt);
    const phase = this.determinePhase(factsData, identity, createdAt);

    const patterns: BehaviorPatterns = factsData.behaviorPatterns || {
      drift_windows: [],
      consistency_score: 0,
      avoidance_triggers: [],
      return_protocols: [],
      last_analyzed: new Date(),
    };

    const reflectionHistory: ReflectionHistory = factsData.reflectionHistory || {
      themes: [],
      emotional_arc: "flat",
      depth_score: 0,
    };

    return {
      identity: {
        name: identity.name,
        age: identity.age,
        purpose: identity.purpose,
        coreValues: identity.coreValues,
        vision: identity.vision,
        discoveryCompleted: identity.discoveryCompleted,
        createdAt,
      },
      patterns,
      reflectionHistory,
      recentConversation: [],
      currentEmotionalState: "balanced",
      contradictions: [],
      phase,
      os_phase,
      tone: user?.tone || "balanced",
      nextEvolution: this.predictNextGrowth(patterns, reflectionHistory),
      architect: factsData.architect,
      oracle: factsData.oracle,
      reflectionThemes: reflectionHistory.themes,
      legacyCode: factsData.oracle?.legacy_code || [],
    };
  }

  // ============================================================
  // 🔥 Extract User Patterns
  // ============================================================
  async extractPatternsFromEvents(userId: string): Promise<void> {
    const since = new Date(Date.now() - 30 * 86400000);

    const events = await prisma.event.findMany({
      where: { userId, ts: { gte: since } },
      orderBy: { ts: "desc" },
    });

    const habitTicks = events.filter((e) => e.type === "habit_tick");
    const drift_windows = this.findDriftWindows(habitTicks);
    const consistency_score = this.calculateConsistency(habitTicks);

    const chatMessages = events.filter((e) => e.type === "chat_message");
    const reflectionThemes = await this.extractThemesWithAI(chatMessages);
    const depth_score = this.scoreReflectionDepth(chatMessages);

    const avoidance_triggers = this.detectAvoidance(events);
    const return_protocols = this.extractReturnProtocols(events);

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
  }

  // ============================================================
  // 🎭 Should Transition Phase?
  // ============================================================
  shouldTransitionPhase(c: UserConsciousness): boolean {
    if (c.phase === "observer") {
      return (
        c.identity.discoveryCompleted &&
        c.reflectionHistory.themes.length >= 3 &&
        c.reflectionHistory.depth_score >= 4
      );
    }

    if (c.phase === "architect") {
      return (
        c.os_phase.days_in_phase >= 30 &&
        c.patterns.consistency_score >= 60 &&
        c.reflectionHistory.depth_score >= 7
      );
    }

    return false;
  }

  // ============================================================
  // 🔥 Phase Logic (PUBLIC, correct signature, 3 args)
  // ============================================================
  determinePhase(factsData: any, identity: any, createdAt: Date): AIPhase {
    const days = Math.floor((Date.now() - createdAt.getTime()) / 86400000);

    const depth = factsData.reflectionHistory?.depth_score || 0;
    const discovery = identity.discoveryCompleted;
    const current = factsData.os_phase?.current_phase;

    // OBSERVER
    if (!discovery || days < 14) return "observer";

    // ARCHITECT
    if (current === "architect" || (days >= 14 && depth >= 5)) {
      if (current === "architect") {
        const daysInPhase = factsData.os_phase?.days_in_phase || 0;
        const consistency = factsData.behaviorPatterns?.consistency_score || 0;

        if (daysInPhase >= 30 && depth >= 7 && consistency >= 60) return "oracle";
      }
      return "architect";
    }

    // ORACLE
    if (current === "oracle" || (days >= 60 && depth >= 7)) return "oracle";

    return current || "observer";
  }

  // ============================================================
  // 📈 Growth Prediction
  // ============================================================
  predictNextGrowth(patterns: BehaviorPatterns, r: ReflectionHistory): string {
    if (patterns.consistency_score > 70 && r.themes.length < 3) return "deepen_meaning";
    if (patterns.avoidance_triggers.length > 3) return "confront_avoidance";
    if (r.depth_score < 5) return "deepen_reflection";
    if (patterns.drift_windows.length > 2) return "build_structure";
    return "maintain_momentum";
  }

  // ============================================================
  // 🎚 Voice Intensity
  // ============================================================
  determineVoiceIntensity(c: UserConsciousness): any {
    if (c.phase === "observer") {
      const p = Math.min(c.reflectionHistory.themes.length / 10, 1);
      return { curiosity: 1 - p * 0.3, gentleness: 0.9, directness: p * 0.4 };
    }

    if (c.phase === "architect") {
      const i = c.patterns.consistency_score / 100;
      return { precision: 0.8 + i * 0.2, authority: 0.6 + i * 0.3, empathy: 0.5 - i * 0.2 };
    }

    if (c.phase === "oracle") {
      const m = Math.min(c.os_phase.days_in_phase / 60, 1);
      return { stillness: 0.5 + m * 0.5, wisdom: 0.7 + m * 0.3, mystery: m * 0.6 };
    }

    return {};
  }

  // ============================================================
  // Helper Functions
  // ============================================================
  private getOrInitializePhase(factsData: any, createdAt: Date): OSPhase {
    if (factsData.os_phase) {
      const days = Math.floor(
        (Date.now() - new Date(factsData.os_phase.started_at).getTime()) / 86400000
      );
      return { ...factsData.os_phase, days_in_phase: days };
    }

    return {
      current_phase: "observer",
      started_at: createdAt,
      days_in_phase: Math.floor((Date.now() - createdAt.getTime()) / 86400000),
      phase_transitions: [],
    };
  }

  private findDriftWindows(habitTicks: any[]): TimeWindow[] {
    const hours: Record<number, { total: number; completed: number }> = {};

    for (const t of habitTicks) {
      const h = new Date(t.ts).getHours();
      if (!hours[h]) hours[h] = { total: 0, completed: 0 };
      hours[h].total++;
      if ((t.payload as any)?.completed) hours[h].completed++;
    }

    return Object.entries(hours)
      .map(([hourStr, counts]) => {
        const rate = counts.completed / counts.total;
        if (rate < 0.5 && counts.total >= 3) {
          return {
            time: `${hourStr}:00`,
            description: `Low completion rate (${Math.round(rate * 100)}%)`,
            frequency: counts.total,
          };
        }
        return null;
      })
      .filter(Boolean)
      .sort((a: any, b: any) => b.frequency - a.frequency)
      .slice(0, 3);
  }

  private calculateConsistency(habitTicks: any[]) {
    if (habitTicks.length === 0) return 0;
    const completed = habitTicks.filter((t) => (t.payload as any)?.completed).length;
    return Math.round((completed / habitTicks.length) * 100);
  }

  private async extractThemesWithAI(messages: any[]) {
    if (!messages.length || messages.length < 3) return [];

    const openai = getOpenAIClient();
    if (!openai) return [];

    try {
      const text = messages
        .slice(0, 20)
        .map((m) => (m.payload as any)?.text || "")
        .filter((t) => t.length > 20)
        .join("\n");

      if (!text) return [];

      const completion = await openai.chat.completions.create({
        model: OPENAI_MODEL,
        max_completion_tokens: 200,
        messages: [
          { role: "system", content: "Extract 3–5 themes. Output ONLY JSON array." },
          { role: "user", content: text },
        ],
      });

      const raw = completion.choices[0]?.message?.content?.trim() || "[]";
      return JSON.parse(raw.replace(/```json|```/g, "")).slice(0, 5);
    } catch {
      return [];
    }
  }

  private scoreReflectionDepth(messages: any[]) {
    if (messages.length === 0) return 0;
    const avg =
      messages.reduce((sum, m) => sum + ((m.payload as any)?.text?.length || 0), 0) /
      messages.length;
    const lengthScore = Math.min(avg / 100, 5);
    const freqScore = Math.min(messages.length / 10, 5);
    return Math.round(lengthScore + freqScore);
  }

  private detectAvoidance(events: any[]) {
    const map: Record<string, number> = {};
    for (const ev of events) {
      if (ev.type === "habit_action" && !(ev.payload as any)?.completed) {
        const id = (ev.payload as any)?.habitId;
        if (id) map[id] = (map[id] || 0) + 1;
      }
    }
    return Object.entries(map)
      .filter(([, count]) => count >= 5)
      .map(([id]) => id);
  }

  private extractReturnProtocols(events: any[]) {
    const out: Protocol[] = [];
    const refs = events
      .filter((e) => e.type === "chat_message" || e.type === "debrief")
      .slice(0, 10);

    for (const r of refs) {
      const text = (r.payload as any)?.text || "";
      if (
        text.includes("came back") ||
        text.includes("returned") ||
        text.includes("got back")
      ) {
        out.push({
          text: text.slice(0, 100),
          worked_count: 1,
          last_used: r.ts,
        });
      }
    }

    return out.slice(0, 5);
  }

  private detectEmotionalArc(messages: any[]): "ascending" | "flat" | "descending" {
    if (messages.length < 5) return "flat";

    let p = 0;
    let n = 0;

    const pos = ["better", "great", "progress", "improved", "good"];
    const neg = ["worse", "struggling", "failed", "hard", "difficult"];

    const recent = messages.slice(0, 10);

    for (const m of recent) {
      const text = ((m.payload as any)?.text || "").toLowerCase();
      for (const w of pos) if (text.includes(w)) p++;
      for (const w of neg) if (text.includes(w)) n++;
    }

    if (p > n * 1.5) return "ascending";
    if (n > p * 1.5) return "descending";
    return "flat";
  }
}

export const memoryIntelligence = new MemoryIntelligenceService();
