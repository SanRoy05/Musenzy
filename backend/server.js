require("dotenv").config();
const express = require("express");
const cors = require("cors");
const ytdl = require("ytdl-core");
const yts = require("yt-search");
const rateLimit = require("express-rate-limit");
const helmet = require("helmet");

const app = express();
const PORT = process.env.PORT || 3000;

// Security
app.use(helmet());
app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS?.split(",") || "*",
  })
);
app.use(express.json());

// Rate limiting — 100 requests per 15 minutes per IP
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: "Too many requests, please try again later." },
});
app.use("/api/", limiter);

// ── SEARCH endpoint ──────────────────────────────────────────────────
// GET /api/search?q=shape+of+you&limit=20
app.get("/api/search", async (req, res) => {
  try {
    const { q, limit = 20 } = req.query;
    if (!q) return res.status(400).json({ error: "Query required" });

    const result = await yts(q);
    const songs = result.videos.slice(0, parseInt(limit)).map((v) => ({
      videoId: v.videoId,
      title: v.title,
      artist: v.author.name,
      thumbnailUrl: v.thumbnail,
      duration: v.seconds,
      durationText: v.timestamp,
      views: v.views,
    }));

    res.json({ songs });
  } catch (err) {
    console.error("Search error:", err);
    res.status(500).json({ error: "Search failed" });
  }
});

// ── STREAM URL endpoint ───────────────────────────────────────────────
// GET /api/stream-url?videoId=dQw4w9WgXcQ
app.get("/api/stream-url", async (req, res) => {
  try {
    const { videoId } = req.query;
    if (!videoId) return res.status(400).json({ error: "videoId required" });

    const info = await ytdl.getInfo(videoId);
    const format = ytdl.chooseFormat(info.formats, {
      quality: "highestaudio",
      filter: "audioonly",
    });

    if (!format)
      return res.status(404).json({ error: "No audio stream found" });

    res.json({
      url: format.url,
      mimeType: format.mimeType,
      bitrate: format.audioBitrate,
      expiresIn: 21600, // ~6 hours in seconds
    });
  } catch (err) {
    console.error("Stream URL error:", err.message);
    if (err.message?.includes("age-restricted")) {
      return res.status(403).json({ error: "age_restricted" });
    }
    if (err.message?.includes("private")) {
      return res.status(403).json({ error: "private_video" });
    }
    res.status(500).json({ error: "Failed to get stream URL" });
  }
});

// ── TRENDING endpoint ─────────────────────────────────────────────────
// GET /api/trending?genre=pop
app.get("/api/trending", async (req, res) => {
  try {
    const { genre = "top hits" } = req.query;
    const result = await yts(
      `${genre} ${new Date().getFullYear()}`
    );
    const songs = result.videos.slice(0, 20).map((v) => ({
      videoId: v.videoId,
      title: v.title,
      artist: v.author.name,
      thumbnailUrl: v.thumbnail,
      duration: v.seconds,
      durationText: v.timestamp,
      views: v.views,
    }));
    res.json({ songs });
  } catch (err) {
    res.status(500).json({ error: "Failed to get trending" });
  }
});

// ── SONG DETAILS endpoint ─────────────────────────────────────────────
// GET /api/song?videoId=dQw4w9WgXcQ
app.get("/api/song", async (req, res) => {
  try {
    const { videoId } = req.query;
    if (!videoId) return res.status(400).json({ error: "videoId required" });

    const info = await ytdl.getBasicInfo(videoId);
    const details = info.videoDetails;

    res.json({
      videoId: details.videoId,
      title: details.title,
      artist: details.author.name,
      thumbnailUrl: details.thumbnails.at(-1)?.url ?? "",
      duration: parseInt(details.lengthSeconds),
      views: details.viewCount,
    });
  } catch (err) {
    res.status(500).json({ error: "Failed to get song details" });
  }
});

// Health check
app.get("/health", (_, res) => res.json({ status: "ok" }));

app.listen(PORT, () => {
  console.log(`🎵 Musenzy proxy server running on port ${PORT}`);
});
