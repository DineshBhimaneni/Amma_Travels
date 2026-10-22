const https = require('https');

function get(url) {
  https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' } }, res => {
    if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
      console.log('Redirecting to:', res.headers.location);
      get(res.headers.location.startsWith('http') ? res.headers.location : 'https://unsplash.com' + res.headers.location);
      return;
    }
    let d = '';
    res.on('data', c => d += c);
    res.on('end', () => {
      console.log('Final Status:', res.statusCode, 'Length:', d.length);
      const m = d.match(/images\.unsplash\.com\/[^\s\"\'\?]+/g);
      if (m) {
        console.log('Found Unsplash images:');
        console.log([...new Set(m)].slice(0, 15));
      }
    });
  });
}

get('https://unsplash.com/s/photos/bus');
