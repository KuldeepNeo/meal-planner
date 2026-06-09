const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const dbFile = process.env.DB_FILE || 'database.sqlite';
const isTest = process.env.NODE_ENV === 'test';
const dbPath = isTest ? ':memory:' : (path.isAbsolute(dbFile) ? dbFile : path.join(__dirname, '../../', dbFile));

let dbInstance = null;

async function getDatabase() {
  if (dbInstance) return dbInstance;
  dbInstance = await open({
    filename: dbPath,
    driver: sqlite3.Database
  });
  // Enable foreign key constraints
  await dbInstance.exec('PRAGMA foreign_keys = ON;');
  return dbInstance;
}

module.exports = { getDatabase };
