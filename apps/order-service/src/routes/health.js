const express = require("express");

const router = express.Router();

router.get("/", (_req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
  });
});

router.get("/live", (_req, res) => {
  res.status(200).send("OK");
});

router.get("/ready", (_req, res) => {
  res.status(200).json({ ready: true });
});

module.exports = router;
