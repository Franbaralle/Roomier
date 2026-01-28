const mongoose = require('mongoose');
const Neighborhood = require('./models/neighborhood');
require('dotenv').config();

/**
 * Script manual - Barrios principales de Villa Carlos Paz
 * Basado en información de la ciudad
 */

const VILLA_CARLOS_PAZ_NEIGHBORHOODS = [
  // Barrios centrales
  "Centro",
  "Costa Azul",
  "San Roque",
  "Santa Isabel",
  "Villa del Lago",
  
  // Barrios residenciales
  "Argentino",
  "Country del Lago",
  "El Fantasio",
  "El Rocío",
  "La Quinta",
  "Las Gemelas",
  "Playas de Oro",
  "Residencial del Lago",
  "Retiro del Sol",
  "Santa Rita",
  "Sol y Río",
  "Valle del Golf",
  "Villa del Prado",
  
  // Barrios periféricos
  "Alto del Lago",
  "Colinas del Lago",
  "Country San Esteban",
  "El Durazno",
  "Los Algarrobos",
  "Los Cerros",
  "Monte Grande",
  "Portal del Lago",
  "San Alfonso",
  "San Lorenzo",
  "Santa María",
  "Yacanto"
];

const CITY_CONFIG = {
  cityName: 'Villa Carlos Paz',
  provinceName: 'Córdoba',
  cityId: '14091250' // ID de Georef
};

async function importNeighborhoods() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/flutter_auth';
    await mongoose.connect(mongoUri);
    console.log('✓ Conectado a MongoDB\n');

    let imported = 0;
    let skipped = 0;

    for (const name of VILLA_CARLOS_PAZ_NEIGHBORHOODS) {
      try {
        // Verificar si ya existe
        const existing = await Neighborhood.findOne({
          name: name,
          cityId: CITY_CONFIG.cityId
        });

        if (existing) {
          console.log(`⏭️  Saltando "${name}": ya existe`);
          skipped++;
          continue;
        }

        // Crear con geometría placeholder (punto en el centro de Villa Carlos Paz)
        await Neighborhood.create({
          name: name,
          cityId: CITY_CONFIG.cityId,
          cityName: CITY_CONFIG.cityName,
          provinceName: CITY_CONFIG.provinceName,
          geometry: {
            type: 'Point',
            coordinates: [-64.4940, -31.4179] // Centro de Villa Carlos Paz
          },
          source: 'manual'
        });

        console.log(`✓ Importado: ${name}`);
        imported++;

      } catch (error) {
        console.error(`❌ Error al importar "${name}":`, error.message);
      }
    }

    console.log(`\n📊 Resumen:`);
    console.log(`   ✓ Importados: ${imported}`);
    console.log(`   ⏭️  Saltados: ${skipped}`);

    const total = await Neighborhood.countDocuments({ cityId: CITY_CONFIG.cityId });
    console.log(`\n📈 Total de barrios en Villa Carlos Paz: ${total}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n✓ Desconectado de MongoDB');
  }
}

importNeighborhoods();
