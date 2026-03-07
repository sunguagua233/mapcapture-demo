-- MapCapture Database Schema
-- Version: 1

CREATE TABLE IF NOT EXISTS trips (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    cover_image_path TEXT,
    start_date INTEGER,
    end_date INTEGER,
    display_order INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS markers (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL,
    title TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    notes TEXT,
    link TEXT,
    category TEXT,
    color TEXT DEFAULT '#FF5722',
    display_order INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS marker_images (
    id TEXT PRIMARY KEY,
    marker_id TEXT NOT NULL,
    file_path TEXT NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (marker_id) REFERENCES markers(id) ON DELETE CASCADE
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_markers_trip_id ON markers(trip_id);
CREATE INDEX IF NOT EXISTS idx_marker_images_marker_id ON marker_images(marker_id);
CREATE INDEX IF NOT EXISTS idx_trips_display_order ON trips(display_order);
CREATE INDEX IF NOT EXISTS idx_markers_display_order ON markers(display_order);
