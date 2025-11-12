-- CreateTable
CREATE TABLE "FutureYouPurposeProfile" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "lifeTask" TEXT,
    "strengths" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "valuesRank" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "sdtAutonomy" INTEGER,
    "sdtCompetence" INTEGER,
    "sdtRelatedness" INTEGER,
    "flowContexts" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "redTags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "odysseyPlans" JSONB,
    "keystones" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "antiHabits" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "lastReviewAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FutureYouPurposeProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FutureYouChapter" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "phase" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "bodyMd" TEXT NOT NULL,
    "words" INTEGER NOT NULL,
    "draftHash" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'final',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FutureYouChapter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FutureYouBookEdition" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "bodyMd" TEXT NOT NULL,
    "chapterIds" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FutureYouBookEdition_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FutureYouJob" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'queued',
    "error" TEXT,
    "insertedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "startedAt" TIMESTAMP(3),
    "finishedAt" TIMESTAMP(3),
    "idemKey" TEXT NOT NULL,

    CONSTRAINT "FutureYouJob_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "FutureYouPurposeProfile_userId_key" ON "FutureYouPurposeProfile"("userId");

-- CreateIndex
CREATE INDEX "FutureYouChapter_userId_idx" ON "FutureYouChapter"("userId");

-- CreateIndex
CREATE INDEX "FutureYouChapter_draftHash_idx" ON "FutureYouChapter"("draftHash");

-- CreateIndex
CREATE INDEX "FutureYouChapter_userId_phase_idx" ON "FutureYouChapter"("userId", "phase");

-- CreateIndex
CREATE INDEX "FutureYouBookEdition_userId_idx" ON "FutureYouBookEdition"("userId");

-- CreateIndex
CREATE INDEX "FutureYouJob_userId_idx" ON "FutureYouJob"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "FutureYouJob_idemKey_key" ON "FutureYouJob"("idemKey");
