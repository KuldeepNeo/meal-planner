const { migrate } = require('../src/models/db');

async function run() {
  try {
    console.log('Initializing SQLite Database...');
    await migrate();
    console.log('Database initialized successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Error initializing database:', error);
    process.exit(1);
  }
}

run();
