const mongoose = require('mongoose');
const Neighborhood = require('./models/neighborhood');
const axios = require('axios');
require('dotenv').config();

/**
 * Script para importar barrios desde datos GeoJSON de Overpass Turbo (OSM)
 * 
 * PASOS PARA USAR:
 * 1. Ir a https://overpass-turbo.eu/
 * 2. Pegar la query de Overpass (ver abajo)
 * 3. Ejecutar y descargar como GeoJSON
 * 4. Guardar el archivo como 'neighborhoods_data.json' en la carpeta backend/
 * 5. Ejecutar: node importNeighborhoods.js
 * 
 * QUERY PARA OVERPASS TURBO:
 * 
 * [out:json][timeout:60];
 * {{geocodeArea:Córdoba, Argentina}}->.searchArea;
 * (
 *   way["boundary"="neighbourhood"](area.searchArea);
 *   relation["boundary"="neighbourhood"](area.searchArea);
 *   way["place"="neighbourhood"](area.searchArea);
 *   relation["place"="neighbourhood"](area.searchArea);
 * );
 * out body;
 * >;
 * out skel qt;
 * 
 * NOTA: Para otras ciudades, cambia "Córdoba, Argentina" por la ciudad deseada
 */

// Configuración: Define la ciudad y provincia para la importación
const CITY_CONFIG = {
  cityName: 'Córdoba',
  provinceName: 'Córdoba',
  cityId: '1401401003' // ID de Georef para Córdoba Capital
};

async function importFromGeoJSON(filePath) {
  try {
    // Conectar a MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/flutter_auth';
    await mongoose.connect(mongoUri);
    console.log('✓ Conectado a MongoDB');

    // Leer el archivo GeoJSON
    const fs = require('fs');
    const geoJsonData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    
    console.log(`\n📂 Archivo cargado: ${geoJsonData.features?.length || 0} features encontradas`);

    let imported = 0;
    let skipped = 0;
    let errors = 0;

    for (const feature of geoJsonData.features || []) {
      try {
        // Extraer propiedades de OSM
        const props = feature.properties || {};
        const name = props.name || props['name:es'] || props['addr:suburb'];
        
        if (!name) {
          skipped++;
          continue;
        }

        // Verificar que tenga geometría válida
        if (!feature.geometry || !feature.geometry.coordinates) {
          console.log(`⚠️  Saltando "${name}": sin geometría`);
          skipped++;
          continue;
        }

        // Preparar documento
        const neighborhoodData = {
          name: name.trim(),
          cityId: CITY_CONFIG.cityId,
          cityName: CITY_CONFIG.cityName,
          provinceName: CITY_CONFIG.provinceName,
          geometry: {
            type: feature.geometry.type,
            coordinates: feature.geometry.coordinates
          },
          osmId: props['@id'] || props.id?.toString(),
          source: 'osm'
        };

        // Verificar si ya existe
        const existing = await Neighborhood.findOne({
          name: neighborhoodData.name,
          cityId: neighborhoodData.cityId
        });

        if (existing) {
          console.log(`⏭️  Saltando "${name}": ya existe`);
          skipped++;
          continue;
        }

        // Insertar en la base de datos
        await Neighborhood.create(neighborhoodData);
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

    // Mostrar estadísticas
    const total = await Neighborhood.countDocuments({ cityId: CITY_CONFIG.cityId });
    console.log(`\n📈 Total de barrios en ${CITY_CONFIG.cityName}: ${total}`);

  } catch (error) {
    console.error('❌ Error fatal:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n✓ Desconectado de MongoDB');
  }
}

/**
 * Función alternativa: Importar directamente desde API de Overpass
 * (Más lento pero no requiere descargar archivo)
 */
async function importFromOverpassAPI(cityName, countryName = 'Argentina') {
  try {
    console.log(`🌐 Consultando Overpass API para ${cityName}, ${countryName}...`);
    
    // Query de Overpass
    const query = `
      [out:json][timeout:60];
      {{geocodeArea:${cityName}, ${countryName}}}->.searchArea;
      (
        way["boundary"="neighbourhood"](area.searchArea);
        relation["boundary"="neighbourhood"](area.searchArea);
        way["place"="neighbourhood"](area.searchArea);
        relation["place"="neighbourhood"](area.searchArea);
      );
      out body;
      >;
      out skel qt;
    `;

    const response = await axios.post(
      'https://overpass-api.de/api/interpreter',
      query,
      {
        headers: { 'Content-Type': 'text/plain' },
        timeout: 120000 // 2 minutos
      }
    );

    console.log(`✓ Datos recibidos de Overpass API`);

    // Convertir respuesta de OSM a GeoJSON simplificado
    const features = response.data.elements
      .filter(el => el.tags && el.tags.name)
      .map(el => ({
        type: 'Feature',
        properties: el.tags,
        geometry: el.geometry || { type: 'Point', coordinates: [el.lon, el.lat] }
      }));

    const geoJson = {
      type: 'FeatureCollection',
      features
    };

    // Guardar temporalmente y procesar
    const fs = require('fs');
    const tempFile = 'temp_neighborhoods.json';
    fs.writeFileSync(tempFile, JSON.stringify(geoJson, null, 2));
    
    await importFromGeoJSON(tempFile);
    
    // Limpiar archivo temporal
    fs.unlinkSync(tempFile);

  } catch (error) {
    console.error('❌ Error al consultar Overpass API:', error.message);
  }
}

// Ejecutar el script
const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
  console.log(`
📖 USO DEL SCRIPT:

1. Importar desde archivo GeoJSON local:
   node importNeighborhoods.js [ruta/al/archivo.json]
   
   Si no se especifica ruta, busca 'neighborhoods_data.json' en la carpeta actual

2. Importar directamente desde Overpass API:
   node importNeighborhoods.js --api [ciudad]
   
   Ejemplo: node importNeighborhoods.js --api "Córdoba"

CONFIGURACIÓN:
- Edita la constante CITY_CONFIG al inicio del archivo
- Define cityId usando el ID de Georef de la ciudad

OBTENER ID DE GEOREF:
Consulta: https://apis.datos.gob.ar/georef/api/localidades?nombre=[ciudad]&max=1
  `);
  process.exit(0);
}

if (args.includes('--api')) {
  const cityIndex = args.indexOf('--api') + 1;
  const city = args[cityIndex] || CITY_CONFIG.cityName;
  importFromOverpassAPI(city);
} else {
  const filePath = args[0] || './neighborhoods_data.json';
  importFromGeoJSON(filePath);
}
