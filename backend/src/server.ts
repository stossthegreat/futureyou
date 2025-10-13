import Fastify from "fastify";
import cors from "@fastify/cors";
import swagger from "@fastify/swagger";
import swaggerUI from "@fastify/swagger-ui";
import dotenv from "dotenv";
import { prisma } from "./utils/db";
import { getRedis } from "./utils/redis";
import { bootstrapSchedulers } from "./jobs/scheduler";

// ✅ Keep only these core controllers
import { nudgesController } from "./controllers/nudges.controller";
import coachController from "./modules/coach/coach.controller";
// optional: keep for uptime monitoring
import { systemController } from "./controllers/system.controller";
import { chatController } from "./controllers/chat.controller";
fastify.register(chatController);
dotenv.config();

function validateEnv() {
  console.log("✅ Core env vars check: (lenient for Railway)");
}

const buildServer = () => {
  const fastify = Fastify({ logger: true });

  // --- CORS ---
  fastify.register(cors, {
    origin: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "x-user-id", "idempotency-key"],
    credentials: true,
  });

  // --- Swagger ---
  fastify.register(swagger, {
    openapi: {
      openapi: "3.0.0",
      info: { title: "Future You OS Brain API", version: "1.0.0" },
      servers: [{ url: process.env.BACKEND_PUBLIC_URL || "http://localhost:8080" }],
    },
  });
  fastify.register(swaggerUI, { routePrefix: "/docs", uiConfig: { docExpansion: "full" } });

  // --- Base routes ---
  fastify.get("/", async () => ({
    message: "Future You OS Brain is running",
    docs: "/docs",
    health: "/health",
    status: "ok",
  }));
  fastify.get("/health", async () => ({
    ok: true,
    status: "healthy",
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  }));
  fastify.get("/healthz", async () => ({ status: "ok" }));

  // --- Controllers (only the brain) ---
  fastify.register(nudgesController);
  fastify.register(coachController);
  fastify.register(systemController); // optional

  return fastify;
};

const start = async () => {
  try {
    console.log("🚀 Starting Future You OS Brain...");
    validateEnv();
    const server = buildServer();

    const port = Number(process.env.PORT || 8080);
    const host = process.env.HOST || "0.0.0.0";
    await server.listen({ port, host });

    console.log("📖 Docs: /docs | 🩺 Health: /health | ⏰ Schedulers active");
    await bootstrapSchedulers();
  } catch (err) {
    console.error("❌ Server startup failed:", err);
    process.exit(1);
  }
};

process.on("SIGINT", async () => {
  console.log("⏹️ Shutting down gracefully...");
  await prisma.$disconnect();
  await getRedis().quit();
  process.exit(0);
});

start();
