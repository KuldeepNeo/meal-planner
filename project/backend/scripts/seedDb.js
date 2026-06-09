const { getDatabase } = require('../src/models/db');

async function seed() {
  try {
    console.log('Seeding Database...');
    const db = await getDatabase();
    
    // Seed Vendors
    await db.exec('BEGIN TRANSACTION;');
    try {
      const vendors = [
        { id: 1, name: 'FreshMart', status: 'ACTIVE' },
        { id: 2, name: 'SuperGrocery', status: 'ACTIVE' },
        { id: 3, name: 'OrganicFarms', status: 'ACTIVE' }
      ];
      
      for (const vendor of vendors) {
        await db.run(
          'INSERT OR IGNORE INTO Vendor (id, vendor_name, status) VALUES (?, ?, ?)',
          [vendor.id, vendor.name, vendor.status]
        );
      }
      await db.exec('COMMIT;');
      console.log('Database seeded successfully.');
      process.exit(0);
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
}

seed();
