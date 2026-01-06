// Definición de todas las categorías y tags de preferencias
// Organizado jerárquicamente para fácil mantenimiento

class PreferencesData {
  static const Map<String, Map<String, List<String>>> categories = {
    'convivencia': {
      'hogar': [
        'plantas_jardineria',
        'decoracion_interiores',
        'diy_bricolaje',
        'minimalismo',
        'organizacion_limpieza',
        'feng_shui',
      ],
      'social': [
        'anfitrion_cenas',
        'salidas_nocturnas',
        'planes_tranquilos',
        'club_lectura',
        'juegos_mesa',
        'karaoke',
      ],
      'mascotas': [
        'dog_lover',
        'cat_lover',
        'rescate_animal',
        'animales_exoticos',
        'alergias',
      ],
    },
    'gastronomia': {
      'habitos': [
        'vegetariana',
        'vegana',
        'celiacos',
        'meal_prep',
        'cocina_saludable',
        'foodie',
      ],
      'bebidas': [
        'cafe_especialidad',
        'te_mate',
        'cerveza_artesanal',
        'cocteleria',
        'catas_vino',
      ],
      'habilidades': [
        'reposteria',
        'parrillero_asado',
        'cocina_internacional',
        'panaderia_artesanal',
      ],
    },
    'deporte': {
      'intensidad': [
        'gimnasio',
        'crossfit',
        'calistenia',
        'running',
        'ciclismo_urbano',
      ],
      'menteCuerpo': [
        'yoga',
        'meditacion',
        'pilates',
        'salud_mental',
        'espiritualidad',
      ],
      'deportesPelota': [
        'futbol',
        'basquet',
        'voley',
        'padel',
        'tenis',
        'rugby',
      ],
      'aguaNaturaleza': [
        'trekking',
        'surf',
        'natacion',
        'buceo',
        'escalada',
        'camping',
      ],
    },
    'entretenimiento': {
      'pantalla': [
        'cine_independiente',
        'documentales',
        'true_crime',
        'anime',
        'ciencia_ficcion',
        'reality_shows',
      ],
      'musica': [
        'conciertos_recitales',
        'festivales',
        'tocar_instrumento',
        'produccion_musical',
        'vinilos',
        'jazz_blues',
        'techno_house',
        'rock',
        'urbano',
      ],
      'gaming': [
        'videojuegos_competitivos',
        'juegos_rol',
        'streamers_twitch',
        'esports',
        'retrogaming',
      ],
    },
    'creatividad': {
      'artesPlasticas': [
        'dibujo_pintura',
        'alfareria_ceramica',
        'fotografia_analogica',
        'diseno_grafico',
        'tatuajes',
      ],
      'tecnologia': [
        'programacion',
        'inteligencia_artificial',
        'crypto_web3',
        'gadgets',
        'robotica',
      ],
      'moda': [
        'upcycling',
        'vintage_thrifting',
        'diseno_moda',
        'maquillaje_artistico',
      ],
    },
    'interesesSociales': {
      'causas': [
        'activismo_ambiental',
        'voluntariado',
        'feminismo',
        'derechos_humanos',
        'politica',
        'sostenibilidad',
      ],
      'conocimiento': [
        'idiomas',
        'historia',
        'filosofia',
        'psicologia',
        'astrologia',
        'astronomia',
        'finanzas_personales',
      ],
    },
  };

  // Mapeo de IDs a nombres legibles en español
  static const Map<String, String> tagLabels = {
    // Convivencia - Hogar
    'plantas_jardineria': '🌿 Plantas/Jardinería',
    'decoracion_interiores': '🏠 Decoración',
    'diy_bricolaje': '🔨 DIY/Bricolaje',
    'minimalismo': '✨ Minimalismo',
    'organizacion_limpieza': '🧹 Organización',
    'feng_shui': '☯️ Feng Shui',
    
    // Convivencia - Social
    'anfitrion_cenas': '🍽️ Anfitrión de cenas',
    'salidas_nocturnas': '🌙 Salidas nocturnas',
    'planes_tranquilos': '📚 Planes tranquilos',
    'club_lectura': '📖 Club de lectura',
    'juegos_mesa': '🎲 Juegos de mesa',
    'karaoke': '🎤 Karaoke',
    
    // Convivencia - Mascotas
    'dog_lover': '🐕 Dog lover',
    'cat_lover': '🐈 Cat lover',
    'rescate_animal': '❤️ Rescate animal',
    'animales_exoticos': '🦎 Animales exóticos',
    'alergias': '⚠️ Alergias',
    
    // Gastronomía - Hábitos
    'vegetariana': '🥗 Vegetariana',
    'vegana': '🌱 Vegana',
    'celiacos': '🌾 Celíacos',
    'meal_prep': '📦 Meal prep',
    'cocina_saludable': '🥑 Cocina saludable',
    'foodie': '🍴 Foodie',
    
    // Gastronomía - Bebidas
    'cafe_especialidad': '☕ Café de especialidad',
    'te_mate': '🍵 Té/Mate',
    'cerveza_artesanal': '🍺 Cerveza artesanal',
    'cocteleria': '🍹 Coctelería',
    'catas_vino': '🍷 Catas de vino',
    
    // Gastronomía - Habilidades
    'reposteria': '🧁 Repostería',
    'parrillero_asado': '🥩 Parrillero/Asado',
    'cocina_internacional': '🌍 Cocina internacional',
    'panaderia_artesanal': '🥖 Panadería artesanal',
    
    // Deporte - Intensidad
    'gimnasio': '💪 Gimnasio',
    'crossfit': '🏋️ CrossFit',
    'calistenia': '🤸 Calistenia',
    'running': '🏃 Running',
    'ciclismo_urbano': '🚴 Ciclismo urbano',
    
    // Deporte - Mente y Cuerpo
    'yoga': '🧘 Yoga',
    'meditacion': '🕉️ Meditación',
    'pilates': '🤸‍♀️ Pilates',
    'salud_mental': '💆 Salud mental',
    'espiritualidad': '✨ Espiritualidad',
    
    // Deporte - Deportes de Pelota
    'futbol': '⚽ Fútbol',
    'basquet': '🏀 Básquet',
    'voley': '🏐 Vóley',
    'padel': '🎾 Pádel',
    'tenis': '🎾 Tenis',
    'rugby': '🏉 Rugby',
    
    // Deporte - Agua/Naturaleza
    'trekking': '🥾 Trekking',
    'surf': '🏄 Surf',
    'natacion': '🏊 Natación',
    'buceo': '🤿 Buceo',
    'escalada': '🧗 Escalada',
    'camping': '⛺ Camping',
    
    // Entretenimiento - Pantalla
    'cine_independiente': '🎬 Cine independiente',
    'documentales': '📺 Documentales',
    'true_crime': '🔍 True Crime',
    'anime': '🎌 Anime',
    'ciencia_ficcion': '🚀 Ciencia Ficción',
    'reality_shows': '📺 Reality Shows',
    
    // Entretenimiento - Música
    'conciertos_recitales': '🎸 Conciertos',
    'festivales': '🎪 Festivales',
    'tocar_instrumento': '🎹 Tocar instrumento',
    'produccion_musical': '🎧 Producción musical',
    'vinilos': '💿 Vinilos',
    'jazz_blues': '🎺 Jazz/Blues',
    'techno_house': '🎵 Techno/House',
    'rock': '🎸 Rock',
    'urbano': '🎤 Urbano',
    
    // Entretenimiento - Gaming
    'videojuegos_competitivos': '🎮 Videojuegos',
    'juegos_rol': '🎲 Juegos de rol',
    'streamers_twitch': '📹 Streamers/Twitch',
    'esports': '🏆 E-sports',
    'retrogaming': '👾 Retrogaming',
    
    // Creatividad - Artes Plásticas
    'dibujo_pintura': '🎨 Dibujo/Pintura',
    'alfareria_ceramica': '🏺 Alfarería/Cerámica',
    'fotografia_analogica': '📷 Fotografía analógica',
    'diseno_grafico': '💻 Diseño gráfico',
    'tatuajes': '🖊️ Tatuajes',
    
    // Creatividad - Tecnología
    'programacion': '💻 Programación',
    'inteligencia_artificial': '🤖 IA',
    'crypto_web3': '₿ Crypto/Web3',
    'gadgets': '📱 Gadgets',
    'robotica': '🤖 Robótica',
    
    // Creatividad - Moda
    'upcycling': '♻️ Upcycling',
    'vintage_thrifting': '👗 Vintage/Thrifting',
    'diseno_moda': '👔 Diseño de moda',
    'maquillaje_artistico': '💄 Maquillaje artístico',
    
    // Intereses Sociales - Causas
    'activismo_ambiental': '🌍 Activismo ambiental',
    'voluntariado': '🤝 Voluntariado',
    'feminismo': '💪 Feminismo',
    'derechos_humanos': '✊ Derechos humanos',
    'politica': '🗳️ Política',
    'sostenibilidad': '♻️ Sostenibilidad',
    
    // Intereses Sociales - Conocimiento
    'idiomas': '🌐 Idiomas',
    'historia': '📜 Historia',
    'filosofia': '🤔 Filosofía',
    'psicologia': '🧠 Psicología',
    'astrologia': '⭐ Astrología',
    'astronomia': '🔭 Astronomía',
    'finanzas_personales': '💰 Finanzas personales',
  };

  // Nombres de categorías principales
  static const Map<String, String> categoryLabels = {
    'convivencia': '🏠 Convivencia y Estilo de Vida',
    'gastronomia': '🍳 Gastronomía y Nutrición',
    'deporte': '🏃 Deporte y Bienestar',
    'entretenimiento': '🎭 Entretenimiento y Ocio',
    'creatividad': '🧠 Creatividad y Tecnología',
    'interesesSociales': '🌍 Intereses Sociales y Conocimiento',
  };

  // Nombres de subcategorías
  static const Map<String, String> subcategoryLabels = {
    'hogar': 'Hogar',
    'social': 'Social',
    'mascotas': 'Mascotas',
    'habitos': 'Hábitos',
    'bebidas': 'Bebidas',
    'habilidades': 'Habilidades',
    'intensidad': 'Intensidad',
    'menteCuerpo': 'Mente y Cuerpo',
    'deportesPelota': 'Deportes de Pelota',
    'aguaNaturaleza': 'Agua/Naturaleza',
    'pantalla': 'Pantalla',
    'musica': 'Música',
    'gaming': 'Gaming',
    'artesPlasticas': 'Artes Plásticas',
    'tecnologia': 'Tecnología',
    'moda': 'Moda',
    'causas': 'Causas',
    'conocimiento': 'Conocimiento',
  };
}
