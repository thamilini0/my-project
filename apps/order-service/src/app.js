const express = require("express");
const helmet = require("helmet");
const pinoHttp = require("pino-http");
const { config } = require("./config");
const healthRouter = require("./routes/health");

function createApp() {
  const app = express();
  app.disable("x-powered-by");
  app.use(helmet());
  app.use(
    pinoHttp({
      level: config.nodeEnv === "production" ? "info" : "debug",
    }),
  );
  app.use(express.json({ limit: "100kb" }));
  app.use("/health", healthRouter);
  app.get("/", (_req, res) => {
    res.json({ service: config.serviceName, status: "ok" });
  });
  return app;
}

module.exports = { createApp };
