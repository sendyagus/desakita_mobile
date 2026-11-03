// Format ulang assets/geo/kemiling_boundary.json agar mudah dibaca:
// satu titik koordinat per baris, struktur GeoJSON tetap utuh.
import fs from 'fs';

const p = 'assets/geo/kemiling_boundary.json';
const g = JSON.parse(fs.readFileSync(p, 'utf8'));
const ft = g.features[0];
const ring = ft.geometry.coordinates[0];
const props = JSON.stringify(ft.properties);

const pts = ring.map((c) => '        [' + c[0] + ', ' + c[1] + ']').join(',\n');

const out =
  '{\n' +
  '  "type": "FeatureCollection",\n' +
  '  "features": [\n' +
  '    {\n' +
  '      "type": "Feature",\n' +
  '      "geometry": {\n' +
  '        "type": "Polygon",\n' +
  '        "coordinates": [\n' +
  '          [\n' +
  pts +
  '\n          ]\n' +
  '        ]\n' +
  '      },\n' +
  '      "properties": ' + props + '\n' +
  '    }\n' +
  '  ]\n' +
  '}\n';

fs.writeFileSync(p, out);

// Verifikasi ulang hasil.
const check = JSON.parse(fs.readFileSync(p, 'utf8'));
const r2 = check.features[0].geometry.coordinates[0];
console.log('titik:', r2.length,
  '| closed:', JSON.stringify(r2[0]) === JSON.stringify(r2[r2.length - 1]),
  '| ukuran baru:', fs.statSync(p).size, 'byte');
