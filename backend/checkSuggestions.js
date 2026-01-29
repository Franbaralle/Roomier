/**
 * Script de administración para revisar y aprobar barrios sugeridos
 * 
 * Uso:
 *   node checkSuggestions.js                    # Ver todas las sugerencias
 *   node checkSuggestions.js --city Posadas     # Filtrar por ciudad
 *   node checkSuggestions.js --min 3            # Solo con 3+ sugerencias
 *   node checkSuggestions.js --approve ID       # Aprobar una sugerencia
 */

require('dotenv').config();
const mongoose = require('mongoose');
const SuggestedNeighborhood = require('./models/suggestedNeighborhood');

// Colores para la terminal
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m'
};

async function main() {
  try {
    // Conectar a MongoDB
    await mongoose.connect(process.env.MONGO_URI || process.env.MONGODB_URI);
    console.log(`${colors.green}✓ Conectado a MongoDB${colors.reset}\n`);

    // Parsear argumentos
    const args = process.argv.slice(2);
    const cityFilter = args.includes('--city') ? args[args.indexOf('--city') + 1] : null;
    const minCount = args.includes('--min') ? parseInt(args[args.indexOf('--min') + 1]) : 1;
    const approveId = args.includes('--approve') ? args[args.indexOf('--approve') + 1] : null;

    // Si es aprobación, manejar aparte
    if (approveId) {
      await approveSuggestion(approveId);
      return;
    }

    // Construir query
    const query = { status: 'pending' };
    if (cityFilter) {
      query.cityName = { $regex: new RegExp(cityFilter, 'i') };
    }
    if (minCount > 1) {
      query.suggestionCount = { $gte: minCount };
    }

    // Obtener sugerencias
    const suggestions = await SuggestedNeighborhood
      .find(query)
      .sort({ suggestionCount: -1, cityName: 1, name: 1 })
      .lean();

    if (suggestions.length === 0) {
      console.log(`${colors.yellow}⚠ No se encontraron sugerencias con los filtros especificados${colors.reset}`);
      return;
    }

    // Agrupar por ciudad
    const byCity = suggestions.reduce((acc, sugg) => {
      const key = `${sugg.cityName}, ${sugg.provinceName}`;
      if (!acc[key]) {
        acc[key] = {
          cityId: sugg.cityId,
          suggestions: []
        };
      }
      acc[key].suggestions.push(sugg);
      return acc;
    }, {});

    // Mostrar resultados
    console.log(`${colors.bright}${colors.cyan}=== BARRIOS SUGERIDOS ===${colors.reset}`);
    console.log(`Total de ciudades: ${Object.keys(byCity).length}`);
    console.log(`Total de sugerencias: ${suggestions.length}\n`);

    for (const [cityName, data] of Object.entries(byCity)) {
      console.log(`${colors.bright}${colors.blue}📍 ${cityName}${colors.reset} (ID: ${data.cityId})`);
      console.log(`   ${data.suggestions.length} barrio(s) sugerido(s):\n`);

      for (const sugg of data.suggestions) {
        const countBadge = sugg.suggestionCount >= 5 ? colors.green :
                          sugg.suggestionCount >= 3 ? colors.yellow :
                          colors.reset;
        
        console.log(`   ${countBadge}[${sugg.suggestionCount}×]${colors.reset} ${sugg.name}`);
        console.log(`      ID: ${colors.cyan}${sugg._id}${colors.reset}`);
        console.log(`      Sugerido por ${sugg.suggestedBy.length} usuario(s)`);
        console.log(`      Primera sugerencia: ${new Date(sugg.createdAt).toLocaleDateString('es-AR')}`);
        
        if (sugg.suggestedBy.length > 0) {
          const emails = sugg.suggestedBy.map(s => s.email).filter(e => e).join(', ');
          if (emails) {
            console.log(`      Emails: ${emails}`);
          }
        }
        console.log('');
      }
      console.log('');
    }

    // Estadísticas
    console.log(`${colors.bright}${colors.cyan}=== ESTADÍSTICAS ===${colors.reset}`);
    const totalCount = suggestions.reduce((sum, s) => sum + s.suggestionCount, 0);
    const avgCount = (totalCount / suggestions.length).toFixed(1);
    const maxCount = Math.max(...suggestions.map(s => s.suggestionCount));
    
    console.log(`Total de sugerencias acumuladas: ${totalCount}`);
    console.log(`Promedio por barrio: ${avgCount}`);
    console.log(`Máximo: ${maxCount}×`);
    console.log('');

    // Ayuda
    console.log(`${colors.bright}${colors.yellow}💡 COMANDOS ÚTILES:${colors.reset}`);
    console.log(`   node checkSuggestions.js --city "Posadas"     ${colors.cyan}# Filtrar por ciudad${colors.reset}`);
    console.log(`   node checkSuggestions.js --min 3              ${colors.cyan}# Solo con 3+ sugerencias${colors.reset}`);
    console.log(`   node checkSuggestions.js --approve <ID>       ${colors.cyan}# Aprobar una sugerencia${colors.reset}`);
    console.log('');

  } catch (error) {
    console.error(`${colors.red}❌ Error:${colors.reset}`, error.message);
  } finally {
    await mongoose.connection.close();
  }
}

async function approveSuggestion(id) {
  try {
    const suggestion = await SuggestedNeighborhood.findById(id);
    
    if (!suggestion) {
      console.log(`${colors.red}❌ No se encontró la sugerencia con ID: ${id}${colors.reset}`);
      return;
    }

    console.log(`${colors.bright}Sugerencia encontrada:${colors.reset}`);
    console.log(`  Barrio: ${colors.cyan}${suggestion.name}${colors.reset}`);
    console.log(`  Ciudad: ${suggestion.cityName}, ${suggestion.provinceName}`);
    console.log(`  Sugerencias: ${suggestion.suggestionCount}×`);
    console.log('');

    // Actualizar estado
    suggestion.status = 'approved';
    suggestion.adminNotes = `Aprobado el ${new Date().toLocaleDateString('es-AR')}`;
    await suggestion.save();

    console.log(`${colors.green}✓ Sugerencia marcada como aprobada${colors.reset}`);
    console.log(`${colors.yellow}⚠ Recuerda agregar este barrio manualmente a la colección 'neighborhoods'${colors.reset}`);
    console.log('');
    console.log(`${colors.bright}Ejemplo de inserción:${colors.reset}`);
    console.log(`${colors.cyan}db.neighborhoods.insertOne({`);
    console.log(`  name: "${suggestion.name}",`);
    console.log(`  cityId: "${suggestion.cityId}",`);
    console.log(`  cityName: "${suggestion.cityName}",`);
    console.log(`  provinceName: "${suggestion.provinceName}"`);
    console.log(`})${colors.reset}`);

  } catch (error) {
    console.error(`${colors.red}❌ Error al aprobar:${colors.reset}`, error.message);
  }
}

// Ejecutar
main();
