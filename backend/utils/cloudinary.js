// Cargar variables de entorno primero
require('dotenv').config();

const cloudinary = require('cloudinary').v2;
const logger = require('./logger');

// Configuración de Cloudinary
// Soporta dos formas:
// 1. CLOUDINARY_URL (recomendado): cloudinary://api_key:api_secret@cloud_name
// 2. Variables separadas: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET
if (process.env.CLOUDINARY_URL) {
    // Opción 1: Cloudinary parseará automáticamente CLOUDINARY_URL
    // Solo necesitamos que la variable de entorno exista
    cloudinary.config();
} else {
    // Opción 2: Variables separadas
    cloudinary.config({
        cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
        api_key: process.env.CLOUDINARY_API_KEY,
        api_secret: process.env.CLOUDINARY_API_SECRET
    });
}

/**
 * Sube una imagen a Cloudinary desde un buffer
 * @param {Buffer} imageBuffer - Buffer de la imagen
 * @param {String} folder - Carpeta en Cloudinary (ej: 'profile_photos')
 * @param {String} publicId - ID público opcional (username del usuario)
 * @returns {Promise<Object>} - Objeto con secure_url y public_id
 */
const uploadImage = async (imageBuffer, folder = 'profile_photos', publicId = null) => {
    try {
        return new Promise((resolve, reject) => {
            const uploadOptions = {
                folder: folder,
                resource_type: 'image',
                quality: 'auto',
                fetch_format: 'auto',
                transformation: [
                    { width: 500, height: 500, crop: 'fill', gravity: 'face' },
                    { quality: 'auto:good' }
                ]
            };

            // Si se proporciona un publicId, agregarlo a las opciones
            if (publicId) {
                uploadOptions.public_id = publicId;
                uploadOptions.overwrite = true; // Permitir sobrescribir si ya existe
            }

            const uploadStream = cloudinary.uploader.upload_stream(
                uploadOptions,
                (error, result) => {
                    if (error) {
                        logger.error('Error al subir imagen a Cloudinary:', error);
                        reject(error);
                    } else {
                        logger.info('Imagen subida exitosamente a Cloudinary:', {
                            public_id: result.public_id,
                            secure_url: result.secure_url
                        });
                        resolve({
                            secure_url: result.secure_url,
                            public_id: result.public_id
                        });
                    }
                }
            );

            // Convertir el buffer a stream y subirlo
            const streamifier = require('streamifier');
            streamifier.createReadStream(imageBuffer).pipe(uploadStream);
        });
    } catch (error) {
        logger.error('Error en uploadImage:', error);
        throw error;
    }
};

/**
 * Elimina una imagen de Cloudinary por su public_id
 * @param {String} publicId - Public ID de la imagen en Cloudinary
 * @returns {Promise<Object>} - Resultado de la eliminación
 */
const deleteImage = async (publicId) => {
    try {
        const result = await cloudinary.uploader.destroy(publicId);
        logger.info('Imagen eliminada de Cloudinary:', { public_id: publicId, result });
        return result;
    } catch (error) {
        logger.error('Error al eliminar imagen de Cloudinary:', error);
        throw error;
    }
};

/**
 * Extrae el public_id de una URL de Cloudinary
 * @param {String} cloudinaryUrl - URL completa de Cloudinary
 * @returns {String} - Public ID extraído
 */
const extractPublicId = (cloudinaryUrl) => {
    try {
        // Formato típico: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{folder}/{public_id}.{format}
        const parts = cloudinaryUrl.split('/');
        const uploadIndex = parts.indexOf('upload');
        
        if (uploadIndex === -1) {
            throw new Error('URL de Cloudinary inválida');
        }
        
        // Obtener la parte después de /upload/v{version}/
        const pathAfterUpload = parts.slice(uploadIndex + 2).join('/');
        
        // Eliminar la extensión del archivo
        const publicIdWithFolder = pathAfterUpload.replace(/\.[^/.]+$/, '');
        
        return publicIdWithFolder;
    } catch (error) {
        logger.error('Error al extraer public_id:', error);
        return null;
    }
};

module.exports = {
    uploadImage,
    deleteImage,
    extractPublicId,
    cloudinary
};
