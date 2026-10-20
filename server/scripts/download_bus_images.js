const fs = require('fs');
const path = require('path');
const https = require('https');

const IMAGES = [
  {
    name: 'bus_super_luxury.jpg',
    url: 'https://upload.wikimedia.org/wikipedia/commons/e/e4/APSRTC_BUS_25062016.jpg'
  },
  {
    name: 'bus_ultra_deluxe.jpg',
    url: 'https://upload.wikimedia.org/wikipedia/commons/c/cf/APSRTC_Ultra_Deluxe_bus.jpg'
  },
  {
    name: 'bus_volvo_multi_axle.jpg',
    url: 'https://upload.wikimedia.org/wikipedia/commons/f/fd/Airavat_Club_Class_Volvo_B11R_bus_in_Bangalore-Mysuru_Expressway.jpg'
  },
  {
    name: 'bus_interior_seats.jpg',
    url: 'https://upload.wikimedia.org/wikipedia/commons/d/d1/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_5_-_interior.jpg'
  },
  {
    name: 'bus_interior_cabin.jpg',
    url: 'https://upload.wikimedia.org/wikipedia/commons/5/56/King_Long_XMQ-6129Y_-_Autotech-2013_-_image_6_-_interior.jpg'
  },
  {
    name: 'bus_coach_modern.jpg',
    url: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=1000&auto=format&fit=crop&q=80'
  },
  {
    name: 'bus_tour_luxury.jpg',
    url: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=1000&auto=format&fit=crop&q=80'
  },
  {
    name: 'bus_luxury_seats.jpg',
    url: 'https://images.unsplash.com/photo-1509749837427-ac94a2553d0e?w=1000&auto=format&fit=crop&q=80'
  },
  {
    name: 'bus_express_transit.jpg',
    url: 'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=1000&auto=format&fit=crop&q=80'
  }
];

const mobileDir = path.resolve(__dirname, '../../apsrtc_mobile/assets/images/buses');
const serverDir = path.resolve(__dirname, '../public/images/buses');

function download(item) {
  return new Promise((resolve, reject) => {
    const mobileDest = path.join(mobileDir, item.name);
    const serverDest = path.join(serverDir, item.name);

    const req = https.get(
      item.url,
      {
        headers: {
          'User-Agent': 'APSRTCApp/1.0 (contact: student@amrita.edu)'
        }
      },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          // Handle redirect
          https.get(
            res.headers.location,
            { headers: { 'User-Agent': 'APSRTCApp/1.0 (contact: student@amrita.edu)' } },
            (redirectRes) => {
              if (redirectRes.statusCode !== 200) {
                return reject(new Error(`Failed ${item.name}: ${redirectRes.statusCode}`));
              }
              const mStream = fs.createWriteStream(mobileDest);
              const sStream = fs.createWriteStream(serverDest);
              redirectRes.pipe(mStream);
              redirectRes.pipe(sStream);
              mStream.on('finish', () => {
                console.log(`Saved: ${item.name} (${fs.statSync(mobileDest).size} bytes)`);
                resolve();
              });
            }
          ).on('error', reject);
          return;
        }

        if (res.statusCode !== 200) {
          return reject(new Error(`Failed ${item.name}: ${res.statusCode}`));
        }

        const mStream = fs.createWriteStream(mobileDest);
        const sStream = fs.createWriteStream(serverDest);
        res.pipe(mStream);
        res.pipe(sStream);
        mStream.on('finish', () => {
          console.log(`Saved: ${item.name} (${fs.statSync(mobileDest).size} bytes)`);
          resolve();
        });
      }
    );
    req.on('error', reject);
  });
}

async function run() {
  console.log('Downloading 100% bus images (Zero cars)...');
  for (const img of IMAGES) {
    try {
      await download(img);
    } catch (err) {
      console.error(`Error downloading ${img.name}:`, err.message);
    }
  }
  console.log('Finished downloading bus images.');
}

run();
