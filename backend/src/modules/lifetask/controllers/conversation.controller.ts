import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { ConverseRequestDTO, ConverseResponseDTO, SaveChapterRequestDTO, SaveChapterResponseDTO } from '../dto/conversation.dto';
import { excavationCoach } from '../services/excavation-coach.service';
import { depthValidator } from '../services/depth-validator.service';
import { patternExtractor } from '../services/pattern-extractor.service';
import { proseWriter } from '../services/prose-writer.service';
import { chaptersRepo } from '../repo/chapters.repo';
import { artifactsRepo } from '../repo/artifacts.repo';

/**
 * CONVERSATION CONTROLLER
 * Handles the deep excavation conversation flow
 */

export async function conversationController(fastify: FastifyInstance) {
  
  /**
   * POST /api/lifetask/converse
   * Generate next coach response in conversation
   */
  fastify.post<{ Body: ConverseRequestDTO }>(
    '/converse',
    async (req: FastifyRequest<{ Body: ConverseRequestDTO }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const { chapterNumber, messages, sessionStartTime } = req.body;

      if (!chapterNumber || chapterNumber < 1 || chapterNumber > 7) {
        return reply.code(400).send({ error: 'Invalid chapter number (must be 1-7)' });
      }

      if (!messages || !Array.isArray(messages)) {
        return reply.code(400).send({ error: 'Messages array required' });
      }

      console.log(`[Conversation] User ${userId} - Chapter ${chapterNumber} - ${messages.length} messages`);

      try {
        // Generate coach response
        const coachMessage = await excavationCoach.generateCoachResponse(
          chapterNumber,
          messages,
          sessionStartTime
        );

        // Validate depth with MASTERY criteria (no artificial limits)
        const validation = depthValidator.validateDepth(
          chapterNumber,
          messages,
          sessionStartTime,
          1 // TODO: track actual session number
        );

        // Extract patterns (ongoing extraction for context)
        const patterns = patternExtractor.extractPatterns(messages, chapterNumber);

        // If validation says to send user away, override coach message
        let finalCoachMessage = coachMessage;
        if (validation.reflectionPrompt) {
          finalCoachMessage = `I can feel you're reaching for something that's not quite there yet. That's completely okay.\n\n${validation.reflectionPrompt}\n\nTake your time. Come back when you're ready. This isn't a race—it's the most important work you'll ever do.`;
        }

        // If chapter can complete, AI should signal readiness
        if (!validation.canComplete && validation.missingElements.length > 0) {
          // Add context about what's still needed
          finalCoachMessage = `${coachMessage}\n\n[Internal note: Still need - ${validation.nextFocus}]`;
        }

        const response: ConverseResponseDTO = {
          coachMessage: finalCoachMessage,
          shouldContinue: !validation.canComplete, // Inverted - true means keep going
          depthMetrics: {
            exchangeCount: validation.metrics.exchangeCount,
            timeElapsedMinutes: validation.metrics.timeElapsedMinutes,
            specificScenesCollected: validation.metrics.specificScenesCollected,
            emotionalMarkersDetected: validation.metrics.emotionalMarkersDetected,
            vagueResponseRatio: validation.metrics.vagueResponseRatio,
            minimumExchangesMet: validation.metrics.exchangeCount >= 50, // Informational only
            minimumTimeMet: validation.metrics.timeElapsedMinutes >= 30, // Informational only
            qualityChecksPassed: validation.canComplete,
          },
          extractedPatterns: {
            redThreads: patterns.redThreads,
            values: patterns.values,
            strengths: patterns.strengths,
            flowContexts: patterns.flowContexts,
            emotionalMarkers: patterns.emotionalMarkers,
          },
          nextPromptHint: validation.nextFocus,
        };

        console.log(`[Conversation] canComplete: ${validation.canComplete}`);
        console.log(`[Conversation] AI Confidence: ${validation.metrics.aiConfidenceScore}/10`);
        console.log(`[Conversation] Missing: ${validation.missingElements.join(', ')}`);
        return response;
      } catch (error: any) {
        console.error('[Conversation] Error:', error);
        return reply.code(500).send({ error: error.message || 'Conversation generation failed' });
      }
    }
  );

  /**
   * POST /api/lifetask/save-chapter
   * Save completed chapter with prose generation
   */
  fastify.post<{ Body: SaveChapterRequestDTO }>(
    '/save-chapter',
    async (req: FastifyRequest<{ Body: SaveChapterRequestDTO }>, reply: FastifyReply) => {
      const userId = (req as any).user?.id || req.headers['x-user-id'] as string;
      
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const { chapterNumber, messages, timeSpentMinutes, sessionStartTime } = req.body;

      if (!chapterNumber || chapterNumber < 1 || chapterNumber > 7) {
        return reply.code(400).send({ error: 'Invalid chapter number (must be 1-7)' });
      }

      console.log(`[SaveChapter] User ${userId} - Chapter ${chapterNumber} - ${messages.length} messages, ${timeSpentMinutes} mins`);

      try {
        // Extract patterns
        const patterns = patternExtractor.extractPatterns(messages, chapterNumber);
        
        // Format transcript for prose generation
        const transcript = messages
          .map(m => `${m.role.toUpperCase()}: ${m.text}`)
          .join('\n\n');

        // Generate prose
        console.log('[SaveChapter] Generating prose...');
        const { proseText, wordCount } = await proseWriter.generateChapterProse(
          chapterNumber,
          transcript,
          {
            redThreads: patterns.redThreads,
            values: patterns.values,
            strengths: patterns.strengths,
            flowContexts: patterns.flowContexts,
            emotionalMarkers: patterns.emotionalMarkers,
            keyQuotes: patterns.keyQuotes,
            themes: patterns.themes,
          }
        );

        console.log(`[SaveChapter] Prose generated: ${wordCount} words`);

        // Save chapter to database
        const chapter = await chaptersRepo.createOrUpdateChapter(
          userId,
          chapterNumber,
          messages,
          timeSpentMinutes,
          {
            redThreads: patterns.redThreads,
            values: patterns.values,
            strengths: patterns.strengths,
            flowContexts: patterns.flowContexts,
            emotionalMarkers: patterns.emotionalMarkers,
            themes: patterns.themes,
          },
          proseText
        );

        console.log(`[SaveChapter] Chapter saved: ${chapter.id}`);

        // Update artifacts based on chapter
        const artifactsUpdated = await this.updateArtifacts(
          userId,
          chapterNumber,
          patterns,
          messages
        );

        const response: SaveChapterResponseDTO = {
          chapterId: chapter.id,
          proseGenerated: true,
          proseText,
          artifactsUpdated,
        };

        return response;
      } catch (error: any) {
        console.error('[SaveChapter] Error:', error);
        return reply.code(500).send({ error: error.message || 'Chapter save failed' });
      }
    }
  );

  /**
   * Helper: Update artifacts based on chapter completion
   */
  async function updateArtifacts(
    userId: string,
    chapterNumber: number,
    patterns: any,
    messages: any[]
  ): Promise<string[]> {
    const updated: string[] = [];

    try {
      switch (chapterNumber) {
        case 1:
          // Story Map
          await artifactsRepo.createOrUpdateArtifact(userId, 'story_map', {
            peakMoments: patterns.keyQuotes.slice(0, 3),
            childhoodObsessions: patterns.themes,
            redThreadTags: patterns.redThreads,
            emotionalMarkers: patterns.emotionalMarkers,
          });
          updated.push('story_map');
          break;

        case 2:
          // Shadow Map
          await artifactsRepo.createOrUpdateArtifact(userId, 'shadow_map', {
            envyMap: [], // Would need more sophisticated extraction
            embarrassmentTest: patterns.keyQuotes,
            falsePaths: patterns.themes,
            shadowDesires: patterns.emotionalMarkers,
          });
          updated.push('shadow_map');
          break;

        case 3:
          // Strengths Grid
          await artifactsRepo.createOrUpdateArtifact(userId, 'strengths_grid', {
            topStrengths: patterns.strengths,
            valuesRanked: patterns.values,
            sdtScores: {
              autonomy: 0, // Would need specific diagnostic
              competence: 0,
              relatedness: 0,
            },
          });
          updated.push('strengths_grid');
          break;

        case 4:
          // Flow Map
          await artifactsRepo.createOrUpdateArtifact(userId, 'flow_map', {
            flowContexts: patterns.flowContexts,
            energySources: patterns.themes,
            skillPatterns: patterns.strengths,
          });
          updated.push('flow_map');
          break;

        case 5:
          // Odyssey Plans + Job Crafting
          await artifactsRepo.createOrUpdateArtifact(userId, 'odyssey_plans', {
            doubleDown: null, // Would need structured extraction
            adjacent: null,
            wildCard: null,
          });
          await artifactsRepo.createOrUpdateArtifact(userId, 'job_crafting', {
            tasksToAdd: [],
            tasksToRemove: [],
            relationalShifts: [],
            cognitiveReframes: [],
          });
          updated.push('odyssey_plans', 'job_crafting');
          break;

        case 6:
          // Purpose Card
          await artifactsRepo.createOrUpdateArtifact(userId, 'purpose_card', {
            lifeTaskSentence: '', // Would need specific extraction
            sixMonthMission: '',
            keystoneHabits: [],
            antiHabits: [],
          });
          updated.push('purpose_card');
          break;

        case 7:
          // Mastery Path
          await artifactsRepo.createOrUpdateArtifact(userId, 'mastery_path', {
            skillToMaster: '',
            practiceStructure: '',
            monthlyReviewQuestions: [],
            legacyVision: '',
          });
          updated.push('mastery_path');
          break;
      }
    } catch (error) {
      console.error('[UpdateArtifacts] Error:', error);
    }

    return updated;
  }
}

