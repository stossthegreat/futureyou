-- ✨ Manual User Creation for Railway PostgreSQL
-- Copy and paste this into Railway PostgreSQL console

-- Create your main user (use the ID from the error log: user_1761700736030)
INSERT INTO "User" (
  id, 
  email, 
  tz, 
  tone, 
  intensity, 
  "mentorId",
  "nudgesEnabled",
  "briefsEnabled",
  "debriefsEnabled",
  "createdAt", 
  "updatedAt"
)
VALUES (
  'user_1761700736030',           -- Use the ID from your logs
  'felix@futureyou.app',          -- Your email
  'Europe/London',                -- Your timezone
  'balanced',                     -- Coaching tone
  2,                              -- Intensity level (1-5)
  'marcus',                       -- Mentor personality
  true,                           -- Enable nudges
  true,                           -- Enable morning briefs
  true,                           -- Enable evening debriefs
  NOW(), 
  NOW()
)
ON CONFLICT (id) DO NOTHING;      -- Don't fail if already exists

-- Verify user was created
SELECT id, email, tz, "mentorId", "createdAt" FROM "User" WHERE id = 'user_1761700736030';

-- You should see: 1 row returned with your user details

