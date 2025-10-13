// src/config/mentors.config.ts
/**
 * 🧭 Mentor configuration — defines tones and default settings
 * for AI / TTS persona selection.
 */

export const MENTORS = {
  marcus: {
    name: "Marcus Aurelius",
    tone: "stoic",
    voiceId: process.env.ELEVENLABS_VOICE_MARCUS || "",
  },
  drill: {
    name: "Drill Sergeant",
    tone: "strict",
    voiceId: process.env.ELEVENLABS_VOICE_DRILL || "",
  },
  confucius: {
    name: "Confucius",
    tone: "balanced",
    voiceId: process.env.ELEVENLABS_VOICE_CONFUCIUS || "",
  },
  lincoln: {
    name: "Abraham Lincoln",
    tone: "balanced",
    voiceId: process.env.ELEVENLABS_VOICE_LINCOLN || "",
  },
  buddha: {
    name: "Buddha",
    tone: "light",
    voiceId: process.env.ELEVENLABS_VOICE_BUDDHA || "",
  },
} as const;

export type MentorId = keyof typeof MENTORS;

/** Utility: get voice ID for a given mentor */
export function getVoiceId(mentor: MentorId): string {
  return MENTORS[mentor]?.voiceId ?? "";
}
