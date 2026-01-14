/**
 * Sistema de Moderación de Contenido
 * Cumplimiento: Ley 24.240 Art. 19 (Defensa del Consumidor)
 * 
 * Filtra palabras ofensivas, discurso de odio y contenido inapropiado
 * en mensajes de chat antes de ser enviados.
 */

// Lista de palabras ofensivas en español (Argentina)
// NOTA: Lista básica - puede expandirse según necesidades
const OFFENSIVE_WORDS = [
    // Insultos comunes
    'boludo', 'pelotudo', 'tarado', 'idiota', 'imbecil', 'estupido',
    'mongo', 'down', 'retrasado', 'deficiente',
    
    // Lenguaje sexual explícito
    'puta', 'puto', 'zorra', 'trola', 'gato',
    'concha', 'pija', 'verga', 'chota', 'pito',
    
    // Discriminación
    'negro de mierda', 'sudaca', 'paragua', 'bolita',
    'gordo de mierda', 'enano', 'petiso',
    
    // Violencia de género
    'golpear', 'violar', 'violacion', 'pegar',
    
    // Drogas y actividades ilegales
    'merca', 'faso', 'porro', 'cocaina',
    'trafico', 'vender droga',
    
    // Amenazas
    'matar', 'asesinar', 'cagarte a palos', 'romper la cara',
    'te voy a encontrar', 'vas a ver',
];

// Patrones regex para detectar variaciones (con números, símbolos, etc.)
const OFFENSIVE_PATTERNS = [
    /p[u0]t[a@o0]/gi,           // puta, puto, p0ta, etc.
    /b[o0]lud[o0]/gi,           // boludo, b0lud0, etc.
    /p[e3]l[o0]tud[o0]/gi,      // pelotudo, p3lotud0, etc.
    /c[o0]nch[a@]/gi,           // concha, c0ncha, etc.
    /m[i1]erd[a@]/gi,           // mierda, m1erda, etc.
    /r[e3]trasad[o0]/gi,        // retrasado, r3trasad0, etc.
    /v[i1][o0]l[a@]r/gi,        // violar, v10lar, etc.
    /c[o0]c[a@][i1]n[a@]/gi,    // cocaina, c0ca1na, etc.
];

/**
 * Verifica si un mensaje contiene contenido ofensivo
 * @param {string} message - Mensaje a verificar
 * @returns {Object} - { isClean: boolean, reason?: string, detectedWords?: Array }
 */
function checkMessage(message) {
    if (!message || typeof message !== 'string') {
        return { isClean: true };
    }

    const messageLower = message.toLowerCase().trim();
    const detectedWords = [];

    // 1. Verificar palabras exactas
    for (const word of OFFENSIVE_WORDS) {
        const regex = new RegExp(`\\b${word}\\b`, 'gi');
        if (regex.test(messageLower)) {
            detectedWords.push(word);
        }
    }

    // 2. Verificar patrones con variaciones
    for (const pattern of OFFENSIVE_PATTERNS) {
        const matches = messageLower.match(pattern);
        if (matches) {
            detectedWords.push(...matches);
        }
    }

    // 3. Verificar URLs sospechosas (phishing, scams)
    const urlPattern = /(https?:\/\/[^\s]+)/gi;
    const urls = message.match(urlPattern);
    if (urls && urls.length > 3) {
        // Más de 3 URLs podría ser spam
        return {
            isClean: false,
            reason: 'Demasiados enlaces (posible spam)',
            detectedWords: ['spam_urls']
        };
    }

    // 4. Verificar spam de caracteres repetidos
    const repeatedCharsPattern = /(.)\1{10,}/g;
    if (repeatedCharsPattern.test(message)) {
        return {
            isClean: false,
            reason: 'Spam de caracteres repetidos',
            detectedWords: ['spam_chars']
        };
    }

    // 5. Verificar números de teléfono (privacidad)
    const phonePattern = /(\+54|0)?[\s-]?\d{2,4}[\s-]?\d{6,8}/g;
    const phones = message.match(phonePattern);
    if (phones && phones.length > 0) {
        // Advertencia - no bloqueamos pero registramos
        console.warn(`[MODERATOR] Número de teléfono detectado en mensaje`);
    }

    if (detectedWords.length > 0) {
        return {
            isClean: false,
            reason: 'Contenido ofensivo o inapropiado detectado',
            detectedWords: [...new Set(detectedWords)] // Remover duplicados
        };
    }

    return { isClean: true };
}

/**
 * Censurar palabras ofensivas en un mensaje (alternativa a bloquear)
 * @param {string} message - Mensaje original
 * @returns {string} - Mensaje censurado
 */
function censorMessage(message) {
    if (!message || typeof message !== 'string') {
        return message;
    }

    let censored = message;

    // Censurar palabras exactas
    for (const word of OFFENSIVE_WORDS) {
        const regex = new RegExp(`\\b${word}\\b`, 'gi');
        censored = censored.replace(regex, (match) => {
            return '*'.repeat(match.length);
        });
    }

    // Censurar patrones
    for (const pattern of OFFENSIVE_PATTERNS) {
        censored = censored.replace(pattern, (match) => {
            return '*'.repeat(match.length);
        });
    }

    return censored;
}

/**
 * Obtener nivel de severidad del contenido
 * @param {Array} detectedWords - Palabras detectadas
 * @returns {string} - 'low', 'medium', 'high', 'critical'
 */
function getSeverityLevel(detectedWords) {
    if (!detectedWords || detectedWords.length === 0) {
        return 'none';
    }

    // Palabras críticas (violencia, drogas duras, amenazas graves)
    const criticalWords = ['violar', 'matar', 'asesinar', 'cocaina', 'trafico', 'violacion'];
    const hasCritical = detectedWords.some(word => 
        criticalWords.some(cw => word.toLowerCase().includes(cw))
    );
    if (hasCritical) return 'critical';

    // Palabras de alta severidad (insultos graves, discriminación)
    const highWords = ['retrasado', 'negro de mierda', 'sudaca', 'paragua', 'deficiente', 'mongo', 'down'];
    const hasHigh = detectedWords.some(word => 
        highWords.some(hw => word.toLowerCase().includes(hw))
    );
    if (hasHigh) return 'high';

    // Palabras de media severidad (insultos comunes, lenguaje sexual explícito)
    const mediumWords = ['puto', 'puta', 'concha', 'pija', 'verga', 'chota', 'pelotudo', 'boludo', 'zorra', 'trola'];
    const hasMedium = detectedWords.some(word => 
        mediumWords.some(mw => word.toLowerCase().includes(mw))
    );
    if (hasMedium) return 'medium';

    // Severidad baja (otros casos)
    return 'low';
}

module.exports = {
    checkMessage,
    censorMessage,
    getSeverityLevel,
    OFFENSIVE_WORDS, // Exportar para testing/actualización
};
