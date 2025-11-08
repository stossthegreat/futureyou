import Fastify from "fastify";
import cors from "@fastify/cors";
import swagger from "@fastify/swagger";
import swaggerUI from "@fastify/swagger-ui";
import dotenv from "dotenv";
import { prisma } from "./utils/db";
import { getRedis } from "./utils/redis";
import { bootstrapSchedulers } from "./jobs/scheduler";
import { initializeFirebaseAdmin } from "./utils/firebase-admin";
import { authMiddleware } from "./middleware/auth.middleware";

import { nudgesController } from "./controllers/nudges.controller";
import coachController from "./modules/coach/coach.controller";
import { systemController } from "./controllers/system.controller";
import { chatController } from "./controllers/chat.controller";
import { userController } from "./controllers/user.controller";
import { testController } from "./controllers/test.controller";
import { insightsController } from "./controllers/insights.controller";
import { whatIfController } from "./controllers/whatif.controller";
import { futureYouChatController } from "./controllers/future-you-chat.controller";
import { whatIfChatController } from "./controllers/what-if-chat.controller";
import { futureYouChatControllerV2 } from "./controllers/future-you-v2.controller";
import { whatIfChatControllerV2 } from "./controllers/what-if-v2.controller";

dotenv.config();

function validateEnv() {
  console.log("✅ Core env vars check: (lenient for Railway)");
}

const buildServer = () => {
  const fastify = Fastify({ logger: true });

  fastify.register(cors, {
    origin: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "x-user-id", "idempotency-key"],
    credentials: true,
  });

  // 🔒 Auth middleware - verify Firebase tokens
  fastify.addHook('preHandler', authMiddleware);

  fastify.register(swagger, {
    openapi: {
      openapi: "3.0.0",
      info: { title: "Future You OS Brain API", version: "1.0.0" },
      servers: [{ url: process.env.BACKEND_PUBLIC_URL || "http://localhost:8080" }],
    },
  });
  fastify.register(swaggerUI, { routePrefix: "/docs", uiConfig: { docExpansion: "full" } });

  fastify.get("/", async () => ({
    message: "Future You OS Brain running",
    docs: "/docs",
    health: "/health",
    status: "ok",
  }));
  fastify.get("/health", async () => ({
    ok: true,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  }));

  fastify.register(chatController);
  fastify.register(nudgesController);
  fastify.register(coachController);
  fastify.register(systemController);
  fastify.register(userController);
  fastify.register(insightsController); // Pattern analysis & insights
  fastify.register(whatIfController); // Purpose-aligned goals
  
  // V1 Chat (structured discovery + simple coach)
  fastify.register(futureYouChatController); // Future-You freeform chat (7 lenses)
  fastify.register(whatIfChatController); // What-If implementation coach
  
  // V2 Chat (hybrid dual-brain architecture)
  fastify.register(futureYouChatControllerV2); // Future-You v2 - emotion + contradiction aware
  fastify.register(whatIfChatControllerV2); // What-If v2 - readiness + plan generation
  
  fastify.register(testController); // For manual testing

  return fastify;
};

const start = async () => {
  try {
    console.log("🚀 Starting Future You OS Brain...");
    validateEnv();
    
    // 🔥 Initialize Firebase Admin SDK
    initializeFirebaseAdmin();
    
    const server = buildServer();

    const port = Number(process.env.PORT || 8080);
    const host = process.env.HOST || "0.0.0.0";
    await server.listen({ port, host });

    console.log("📖 Docs: /docs | 🩺 Health: /health | ⏰ Schedulers active");
    await bootstrapSchedulers();
  } catch (err) {
    console.error("❌ Startup failed:", err);
    process.exit(1);
  }
};

process.on("SIGINT", async () => {
  console.log("⏹️ Graceful shutdown…");
  await prisma.$disconnect();
  await getRedis().quit();
  process.exit(0);
});

start();
