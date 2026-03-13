import { serve } from '@vercel/node';
import express from 'express';
import path from 'path';
import Database from 'better-sqlite3';

const app = express();

// Initialize database (note: data will reset on each deployment in serverless)
const dbPath = path.join('/tmp', 'itinerary.db');
const db = new Database(dbPath);

db.exec(`
  CREATE TABLE IF NOT EXISTS groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS itineraries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_id INTEGER,
    name TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id)
  );

  CREATE TABLE IF NOT EXISTS markers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    itinerary_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    address TEXT,
    lat REAL NOT NULL,
    lng REAL NOT NULL,
    type TEXT CHECK(type IN ('itinerary', 'favorite')) NOT NULL,
    category TEXT,
    style TEXT,
    notes TEXT,
    order_index INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (itinerary_id) REFERENCES itineraries(id)
  );

  CREATE TABLE IF NOT EXISTS attachments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    marker_id INTEGER NOT NULL,
    url TEXT NOT NULL,
    FOREIGN KEY (marker_id) REFERENCES markers(id)
  );
`);

app.use(express.json({ limit: '50mb' }));

// API Routes
app.get("/api/groups", (req, res) => {
  const groups = db.prepare("SELECT * FROM groups ORDER BY created_at DESC").all();
  res.json(groups);
});

app.post("/api/groups", (req, res) => {
  const { name } = req.body;
  const result = db.prepare("INSERT INTO groups (name) VALUES (?)").run(name);
  res.json({ id: result.lastInsertRowid, name });
});

app.get("/api/itineraries", (req, res) => {
  const itineraries = db.prepare("SELECT * FROM itineraries ORDER BY created_at DESC").all();
  res.json(itineraries);
});

app.post("/api/itineraries", (req, res) => {
  const { name, group_id } = req.body;
  const result = db.prepare("INSERT INTO itineraries (name, group_id) VALUES (?, ?)").run(name, group_id);
  res.json({ id: result.lastInsertRowid, name, group_id });
});

app.get("/api/itineraries/:id", (req, res) => {
  const itinerary = db.prepare("SELECT * FROM itineraries WHERE id = ?").get(req.params.id);
  if (!itinerary) return res.status(404).json({ error: "Not found" });

  const markers = db.prepare("SELECT * FROM markers WHERE itinerary_id = ? ORDER BY order_index ASC").all(req.params.id);

  const markersWithAttachments = markers.map(m => {
    const attachments = db.prepare("SELECT * FROM attachments WHERE marker_id = ?").all(m.id);
    return { ...m, attachments };
  });

  res.json({ ...itinerary, markers: markersWithAttachments });
});

app.post("/api/markers", (req, res) => {
  const { itinerary_id, name, address, lat, lng, type, category, style, notes, order_index, attachments } = req.body;

  const result = db.prepare(`
    INSERT INTO markers (itinerary_id, name, address, lat, lng, type, category, style, notes, order_index)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(itinerary_id, name, address, lat, lng, type, category, style, notes, order_index);

  const markerId = result.lastInsertRowid;

  if (attachments && Array.isArray(attachments)) {
    const stmt = db.prepare("INSERT INTO attachments (marker_id, url) VALUES (?, ?)");
    for (const url of attachments) {
      stmt.run(markerId, url);
    }
  }

  res.json({ id: markerId });
});

app.put("/api/markers/:id", (req, res) => {
  const { name, address, category, style, notes, order_index, attachments } = req.body;

  db.prepare(`
    UPDATE markers SET name = ?, address = ?, category = ?, style = ?, notes = ?, order_index = ?
    WHERE id = ?
  `).run(name, address, category, style, notes, order_index, req.params.id);

  if (attachments) {
    db.prepare("DELETE FROM attachments WHERE marker_id = ?").run(req.params.id);
    const stmt = db.prepare("INSERT INTO attachments (marker_id, url) VALUES (?, ?)");
    for (const url of attachments) {
      stmt.run(req.params.id, url);
    }
  }

  res.json({ success: true });
});

app.delete("/api/markers/:id", (req, res) => {
  db.prepare("DELETE FROM attachments WHERE marker_id = ?").run(req.params.id);
  db.prepare("DELETE FROM markers WHERE id = ?").run(req.params.id);
  res.json({ success: true });
});

app.put("/api/markers/bulk", (req, res) => {
  const { markers } = req.body;
  const updateStmt = db.prepare("UPDATE markers SET order_index = ? WHERE id = ?");

  for (const m of markers) {
    updateStmt.run(m.order_index, m.id);
  }

  res.json({ success: true });
});

export default serve(app);
