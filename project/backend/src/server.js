const app = require('./app');
const { migrate } = require('./models/db');
require('dotenv').config();

const PORT = process.env.PORT || 5003;


async function startServer() {
  try {
    // Run migrations before listening
    await migrate();
    console.log('Database migrated successfully.');

    app.listen(PORT, () => {
      console.log(`Server is running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

startServer();
