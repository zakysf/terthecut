-- Migration: Menambahkan kolom koordinat untuk fitur LBS (Modul 7)
ALTER TABLE branches ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE branches ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Mengisi koordinat GPS nyata 11 Cabang Ter The Cut di Daerah Istimewa Yogyakarta
UPDATE branches SET latitude = -7.8115, longitude = 110.3925 WHERE name ILIKE '%Warungboto%';
UPDATE branches SET latitude = -7.7554, longitude = 110.4289 WHERE name ILIKE '%Tajem%' OR name ILIKE '%Maguwoharjo%';
UPDATE branches SET latitude = -7.7942, longitude = 110.3421 WHERE name ILIKE '%Soragan%';
UPDATE branches SET latitude = -7.7328, longitude = 110.3789 WHERE name ILIKE '%Palagan%';
UPDATE branches SET latitude = -7.7712, longitude = 110.3934 WHERE name ILIKE '%Mrican 2%' OR name ILIKE '%Pringwulung%';
UPDATE branches SET latitude = -7.7785, longitude = 110.3912 WHERE name ILIKE '%Mrican 1%' OR name ILIKE '%Demangan%';
UPDATE branches SET latitude = -7.7761, longitude = 110.3347 WHERE name ILIKE '%Godean%';
UPDATE branches SET latitude = -7.8184, longitude = 110.3592 WHERE name ILIKE '%Gedongkiwo%';
UPDATE branches SET latitude = -7.8016, longitude = 110.3235 WHERE name ILIKE '%Gamping%';
UPDATE branches SET latitude = -7.7578, longitude = 110.4012 WHERE name ILIKE '%Concat%' OR name ILIKE '%Condongcatur%';
UPDATE branches SET latitude = -7.7472, longitude = 110.4183 WHERE name ILIKE '%Candi Gebang%';
