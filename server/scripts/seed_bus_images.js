const db = require('../config/db');

const BUS_IMAGES_CATALOG = [
  {
    primary: 'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg',
    gallery: [
      'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg'
    ]
  },
  {
    primary: 'https://upload.wikimedia.org/wikipedia/commons/f/fd/Airavat_Club_Class_Volvo_B11R_bus_in_Bangalore-Mysuru_Expressway.jpg',
    gallery: [
      'https://upload.wikimedia.org/wikipedia/commons/f/fd/Airavat_Club_Class_Volvo_B11R_bus_in_Bangalore-Mysuru_Expressway.jpg',
      'https://images.unsplash.com/photo-1509749837427-ac94a2553d0e?w=800&auto=format&fit=crop&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg'
    ]
  },
  {
    primary: 'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg',
    gallery: [
      'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg',
      'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&auto=format&fit=crop&q=80'
    ]
  },
  {
    primary: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&auto=format&fit=crop&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1509749837427-ac94a2553d0e?w=800&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop&q=80'
    ]
  },
  {
    primary: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&auto=format&fit=crop&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=800&auto=format&fit=crop&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg'
    ]
  },
  {
    primary: 'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop&q=80',
    gallery: [
      'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop&q=80',
      'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg',
      'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg'
    ]
  }
];

async function seed() {
  try {
    const [cols] = await db.query("SHOW COLUMNS FROM buses LIKE 'image_url'");
    if (cols.length === 0) {
      await db.query("ALTER TABLE buses ADD COLUMN image_url VARCHAR(500) NULL, ADD COLUMN images TEXT NULL");
      console.log('image_url and images columns added to buses table');
    }

    const [buses] = await db.query('SELECT id, bus_name, bus_type FROM buses');
    for (let i = 0; i < buses.length; i++) {
      const b = buses[i];
      const cat = BUS_IMAGES_CATALOG[i % BUS_IMAGES_CATALOG.length];
      await db.query('UPDATE buses SET image_url = ?, images = ? WHERE id = ?', [
        cat.primary,
        JSON.stringify(cat.gallery),
        b.id
      ]);
    }
    console.log(`Successfully updated ${buses.length} buses with realistic images!`);
    process.exit(0);
  } catch (err) {
    console.error('Error seeding bus images:', err);
    process.exit(1);
  }
}

seed();
