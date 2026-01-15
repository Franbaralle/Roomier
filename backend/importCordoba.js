const mongoose = require('mongoose');
const Neighborhood = require('./models/neighborhood');
const https = require('https');
require('dotenv').config();

/**
 * Script simplificado para importar barrios de Córdoba
 * Usa datos directos de Overpass con query optimizada
 */

const CITY_CONFIG = {
  cityName: 'Córdoba',
  provinceName: 'Córdoba',
  cityId: '1401401003'
};

// Query simplificada de Overpass usando bounding box de Córdoba
const OVERPASS_QUERY = `
[out:json][timeout:90];
// Bounding box de Córdoba Capital (aproximado)
// lat: -31.3 a -31.5, lon: -64.3 a -64.0
(
  way["place"="neighbourhood"](-31.5,-64.3,-31.3,-64.0);
  relation["place"="neighbourhood"](-31.5,-64.3,-31.3,-64.0);
  way["boundary"="neighbourhood"](-31.5,-64.3,-31.3,-64.0);
  relation["boundary"="neighbourhood"](-31.5,-64.3,-31.3,-64.0);
  way["name"]["place"="suburb"](-31.5,-64.3,-31.3,-64.0);
  way["name"]["landuse"="residential"](-31.5,-64.3,-31.3,-64.0);
);
out body;
>;
out skel qt;
`;

async function downloadFromOverpass() {
  return new Promise((resolve, reject) => {
    const postData = OVERPASS_QUERY;
    
    const options = {
      hostname: 'overpass-api.de',
      port: 443,
      path: '/api/interpreter',
      method: 'POST',
      headers: {
        'Content-Type': 'text/plain',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 120000
    };

    console.log('📡 Enviando consulta a Overpass API...');
    
    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
        process.stdout.write('.');
      });

      res.on('end', () => {
        console.log('\n✓ Datos recibidos');
        try {
          const jsonData = JSON.parse(data);
          resolve(jsonData);
        } catch (e) {
          reject(new Error('Error al parsear JSON: ' + e.message));
        }
      });
    });

    req.on('error', (e) => {
      reject(new Error('Error de red: ' + e.message));
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Timeout de la solicitud'));
    });

    req.write(postData);
    req.end();
  });
}

function osmToGeoJSON(osmData) {
  const ways = {};
  const nodes = {};
  const features = [];

  // Indexar nodos
  for (const element of osmData.elements) {
    if (element.type === 'node') {
      nodes[element.id] = [element.lon, element.lat];
    }
  }

  // Procesar ways
  for (const element of osmData.elements) {
    if (element.type === 'way' && element.tags && (element.tags.name || element.tags['name:es'])) {
      const coords = [];
      for (const nodeId of element.nodes || []) {
        if (nodes[nodeId]) {
          coords.push(nodes[nodeId]);
        }
      }

      if (coords.length >= 4) { // Polígono válido
        features.push({
          type: 'Feature',
          properties: element.tags,
          geometry: {
            type: 'Polygon',
            coordinates: [coords]
          }
        });
      }
    }
  }

  return {
    type: 'FeatureCollection',
    features
  };
}

async function importNeighborhoods() {
  try {
    // Conectar a MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/flutter_auth';
    await mongoose.connect(mongoUri);
    console.log('✓ Conectado a MongoDB\n');

    // Descargar datos
    const osmData = await downloadFromOverpass();
    console.log(`📊 Elementos recibidos: ${osmData.elements?.length || 0}`);

    // Convertir a GeoJSON
    const geoJson = osmToGeoJSON(osmData);
    console.log(`📍 Barrios encontrados: ${geoJson.features.length}\n`);

    let imported = 0;
    let skipped = 0;
    let errors = 0;

    for (const feature of geoJson.features) {
      try {
        const props = feature.properties;
        const name = props.name || props['name:es'];

        if (!name) {
          skipped++;
          continue;
        }

        // Verificar si ya existe
        const existing = await Neighborhood.findOne({
          name: name.trim(),
          cityId: CITY_CONFIG.cityId
        });

        if (existing) {
          console.log(`⏭️  Saltando "${name}": ya existe`);
          skipped++;
          continue;
        }

        // Crear documento
        await Neighborhood.create({
          name: name.trim(),
          cityId: CITY_CONFIG.cityId,
          cityName: CITY_CONFIG.cityName,
          provinceName: CITY_CONFIG.provinceName,
          geometry: feature.geometry,
          osmId: props['@id'] || props.id?.toString(),
          source: 'osm'
        });

        console.log(`✓ Importado: ${name}`);
        imported++;

      } catch (error) {
        console.error(`❌ Error al importar barrio:`, error.message);
        errors++;
      }
    }

    console.log(`\n📊 Resumen de importación:`);
    console.log(`   ✓ Importados: ${imported}`);
    console.log(`   ⏭️  Saltados: ${skipped}`);
    console.log(`   ❌ Errores: ${errors}`);

    // Estadísticas finales
    const total = await Neighborhood.countDocuments({ cityId: CITY_CONFIG.cityId });
    console.log(`\n📈 Total de barrios en ${CITY_CONFIG.cityName}: ${total}`);

  } catch (error) {
    console.error('❌ Error fatal:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n✓ Desconectado de MongoDB');
  }
}

// Ejecutar
importNeighborhoods();
