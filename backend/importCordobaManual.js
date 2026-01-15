const mongoose = require('mongoose');
const Neighborhood = require('./models/neighborhood');
require('dotenv').config();

/**
 * Script de datos de prueba - Barrios principales de Córdoba
 * Estos datos se pueden ampliar después con datos reales de OSM
 */

const CORDOBA_NEIGHBORHOODS = [
  "Alberdi",
  "Alta Córdoba",
  "Argüello",
  "Barrio Jardín",
  "Centro",
  "Cerro de las Rosas",
  "General Paz",
  "Güemes",
  "Juniors",
  "Nueva Córdoba",
  "Observatorio",
  "San Vicente",
  "Urca",
  "Villa Belgrano",
  "Alto Alberdi",
  "Cofico",
  "General Bustos",
  "Los Plátanos",
  "Poeta Lugones",
  "Pueyrredón",
  "San Martín",
  "Villa Allende Parque",
  "Villa Cabrera",
  "Yapeyú",
  "Alem",
  "Bajo Palermo",
  "Granja de Funes",
  "Güemes Norte",
  "Ituzaingó",
  "Parque Atlántica",
  "Quintas de Arguello",
  "San Fernando",
  "Villa Adela",
  "Villa Azalais",
  "Villa El Libertador",
  "Villa Páez",
  "Alto Verde",
  "Barrio Rogelio Martínez",
  "Colinas de Vélez Sarsfield",
  "General Arenales",
  "José Ignacio Díaz",
  "Las Palmas",
  "Parque Capital",
  "Parque Don Bosco",
  "Parque Liceo",
  "Residencial América",
  "San Roque",
  "Villa Cornu",
  "Villa el Faro",
  "Villa Eucarística",
  "Villa Revol",
  "Villa Urquiza"
];

const CITY_CONFIG = {
  cityName: 'Córdoba',
  provinceName: 'Córdoba',
  cityId: '1401401003'
};

async function importNeighborhoods() {
  try {
    const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/flutter_auth';
    await mongoose.connect(mongoUri);
    console.log('✓ Conectado a MongoDB\n');

    let imported = 0;
    let skipped = 0;

    for (const name of CORDOBA_NEIGHBORHOODS) {
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

        // Crear con geometría placeholder (punto en el centro de Córdoba)
        await Neighborhood.create({
          name: name,
          cityId: CITY_CONFIG.cityId,
          cityName: CITY_CONFIG.cityName,
          provinceName: CITY_CONFIG.provinceName,
          geometry: {
            type: 'Point',
            coordinates: [-64.1810, -31.4135] // Centro aproximado de Córdoba
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
    console.log(`\n📈 Total de barrios en Córdoba: ${total}`);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('\n✓ Desconectado de MongoDB');
  }
}

importNeighborhoods();
