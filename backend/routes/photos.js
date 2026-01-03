// routes/photos.js - Rutas para manejo de múltiples fotos de perfil y hogar
const express = require('express');
const router = express.Router();
const User = require('../models/User');
const multer = require('multer');
const { uploadImage, deleteImage } = require('../utils/cloudinary');
const { verifyToken } = require('../middleware/auth');

// Configuración de Multer para manejar múltiples archivos en memoria
const storage = multer.memoryStorage();
const upload = multer({ 
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB por archivo
        files: 10 // Máximo 10 archivos en una sola petición
    },
    fileFilter: (req, file, cb) => {
        // Validar que sean imágenes
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Solo se permiten archivos de imagen'), false);
        }
    }
});

// ====== FOTOS DE PERFIL (máximo 10) ======

/**
 * POST /api/photos/profile
 * Agregar fotos de perfil (hasta 10 total)
 * Body: username (string), files (array de imágenes)
 */
router.post('/profile', verifyToken, upload.array('photos', 10), async (req, res) => {
    try {
        console.log('=== ADDING PROFILE PHOTOS ===');
        const { username } = req.body;

        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ message: 'No se proporcionaron imágenes' });
        }

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Verificar que no exceda el límite de 10 fotos
        const currentPhotosCount = user.profilePhotos ? user.profilePhotos.length : 0;
        const newPhotosCount = req.files.length;
        
        if (currentPhotosCount + newPhotosCount > 10) {
            return res.status(400).json({ 
                message: `No puedes tener más de 10 fotos de perfil. Actualmente tienes ${currentPhotosCount} fotos.` 
            });
        }

        // Inicializar array si no existe
        if (!user.profilePhotos) {
            user.profilePhotos = [];
        }

        // Si es la primera foto, marcarla como principal
        const isFirstPhoto = user.profilePhotos.length === 0;

        // Subir todas las imágenes a Cloudinary
        const uploadPromises = req.files.map(async (file, index) => {
            const cloudinaryResult = await uploadImage(
                file.buffer,
                'profile_photos',
                `user_${username}_${Date.now()}_${index}`
            );
            
            return {
                url: cloudinaryResult.secure_url,
                publicId: cloudinaryResult.public_id,
                isPrimary: isFirstPhoto && index === 0
            };
        });

        const uploadedPhotos = await Promise.all(uploadPromises);
        
        // Agregar fotos al array del usuario
        user.profilePhotos.push(...uploadedPhotos);

        // Mantener retrocompatibilidad: actualizar profilePhoto con la foto principal
        const primaryPhoto = user.profilePhotos.find(p => p.isPrimary);
        if (primaryPhoto) {
            user.profilePhoto = primaryPhoto.url;
            user.profilePhotoPublicId = primaryPhoto.publicId;
        }

        await user.save();

        console.log(`Subidas ${uploadedPhotos.length} fotos exitosamente para ${username}`);

        return res.json({
            message: 'Fotos de perfil agregadas exitosamente',
            photos: uploadedPhotos,
            totalPhotos: user.profilePhotos.length
        });
    } catch (error) {
        console.error('Error al agregar fotos de perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

/**
 * DELETE /api/photos/profile/:publicId
 * Eliminar una foto de perfil específica
 */
router.delete('/profile/:publicId', verifyToken, async (req, res) => {
    try {
        const { publicId } = req.params;
        const username = req.user.username || req.username;

        if (!username) {
            return res.status(401).json({ message: 'Usuario no autenticado' });
        }

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Buscar la foto en el array
        const photoIndex = user.profilePhotos.findIndex(p => p.publicId === publicId);
        
        if (photoIndex === -1) {
            return res.status(404).json({ message: 'Foto no encontrada' });
        }

        const photoToDelete = user.profilePhotos[photoIndex];
        const wasPrimary = photoToDelete.isPrimary;

        // Eliminar de Cloudinary
        await deleteImage(publicId);

        // Eliminar del array
        user.profilePhotos.splice(photoIndex, 1);

        // Si se eliminó la foto principal y hay otras fotos, hacer la primera como principal
        if (wasPrimary && user.profilePhotos.length > 0) {
            user.profilePhotos[0].isPrimary = true;
            user.profilePhoto = user.profilePhotos[0].url;
            user.profilePhotoPublicId = user.profilePhotos[0].publicId;
        } else if (user.profilePhotos.length === 0) {
            // Si no quedan fotos, limpiar campos legacy
            user.profilePhoto = undefined;
            user.profilePhotoPublicId = undefined;
        }

        await user.save();

        return res.json({
            message: 'Foto eliminada exitosamente',
            remainingPhotos: user.profilePhotos.length
        });
    } catch (error) {
        console.error('Error al eliminar foto de perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

/**
 * PUT /api/photos/profile/:publicId/primary
 * Establecer una foto como principal
 */
router.put('/profile/:publicId/primary', verifyToken, async (req, res) => {
    try {
        const { publicId } = req.params;
        const username = req.user.username || req.username;
        
        console.log('=== SET PRIMARY PHOTO ===');
        console.log('PublicId:', publicId);
        console.log('Username from token:', username);

        if (!username) {
            return res.status(401).json({ message: 'Usuario no autenticado' });
        }

        const user = await User.findOne({ username });
        if (!user) {
            console.log('ERROR: Usuario no encontrado:', username);
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Validar que el usuario tenga fotos
        if (!user.profilePhotos || user.profilePhotos.length === 0) {
            console.log('ERROR: Usuario no tiene fotos de perfil');
            return res.status(404).json({ message: 'No tienes fotos de perfil' });
        }

        console.log('Fotos del usuario:');
        user.profilePhotos.forEach((photo, idx) => {
            console.log(`  [${idx}] publicId: "${photo.publicId}", isPrimary: ${photo.isPrimary}`);
        });
        console.log('PublicId buscado:', publicId);

        // Quitar isPrimary de todas las fotos
        user.profilePhotos.forEach(photo => {
            photo.isPrimary = false;
        });

        // Establecer la nueva foto principal
        const newPrimaryPhoto = user.profilePhotos.find(p => p.publicId === publicId);
        
        if (!newPrimaryPhoto) {
            console.log('ERROR: Foto no encontrada. PublicId:', publicId);
            console.log('Fotos disponibles:', user.profilePhotos.map(p => p.publicId));
            return res.status(404).json({ message: 'Foto no encontrada' });
        }

        newPrimaryPhoto.isPrimary = true;

        // Actualizar campos legacy
        user.profilePhoto = newPrimaryPhoto.url;
        user.profilePhotoPublicId = newPrimaryPhoto.publicId;

        await user.save();
        
        console.log('Foto principal actualizada exitosamente');

        return res.json({
            message: 'Foto principal actualizada exitosamente',
            primaryPhoto: newPrimaryPhoto
        });
    } catch (error) {
        console.error('Error al establecer foto principal:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

/**
 * GET /api/photos/profile/:username
 * Obtener todas las fotos de perfil de un usuario
 */
router.get('/profile/:username', async (req, res) => {
    try {
        const { username } = req.params;

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Si tiene el nuevo formato, devolverlo
        if (user.profilePhotos && user.profilePhotos.length > 0) {
            return res.json({
                photos: user.profilePhotos,
                totalPhotos: user.profilePhotos.length
            });
        }

        // Retrocompatibilidad: si solo tiene profilePhoto (formato antiguo)
        if (user.profilePhoto) {
            return res.json({
                photos: [{
                    url: user.profilePhoto,
                    publicId: user.profilePhotoPublicId || '',
                    isPrimary: true
                }],
                totalPhotos: 1
            });
        }

        // Si no tiene fotos
        return res.json({
            photos: [],
            totalPhotos: 0
        });
    } catch (error) {
        console.error('Error al obtener fotos de perfil:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

// ====== FOTOS DEL HOGAR (ilimitadas, solo si hasPlace = true) ======

/**
 * POST /api/photos/home
 * Agregar fotos del hogar (solo si hasPlace es true)
 * Body: username (string), files (array de imágenes), descriptions (array de strings opcional)
 */
router.post('/home', verifyToken, upload.array('photos', 50), async (req, res) => {
    try {
        console.log('=== ADDING HOME PHOTOS ===');
        const { username, descriptions } = req.body;

        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ message: 'No se proporcionaron imágenes' });
        }

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Verificar que el usuario tiene lugar para compartir
        if (!user.housingInfo || !user.housingInfo.hasPlace) {
            return res.status(400).json({ 
                message: 'Solo puedes subir fotos del hogar si marcaste que tienes lugar' 
            });
        }

        // Inicializar array si no existe
        if (!user.homePhotos) {
            user.homePhotos = [];
        }

        // Parsear descripciones si vienen como JSON string
        let descriptionsArray = [];
        if (descriptions) {
            try {
                descriptionsArray = typeof descriptions === 'string' 
                    ? JSON.parse(descriptions) 
                    : descriptions;
            } catch (e) {
                console.log('No se pudieron parsear las descripciones, usando array vacío');
            }
        }

        // Subir todas las imágenes a Cloudinary
        const uploadPromises = req.files.map(async (file, index) => {
            const cloudinaryResult = await uploadImage(
                file.buffer,
                'home_photos',
                `home_${username}_${Date.now()}_${index}`
            );
            
            return {
                url: cloudinaryResult.secure_url,
                publicId: cloudinaryResult.public_id,
                description: descriptionsArray[index] || ''
            };
        });

        const uploadedPhotos = await Promise.all(uploadPromises);
        
        // Agregar fotos al array del usuario
        user.homePhotos.push(...uploadedPhotos);
        await user.save();

        console.log(`Subidas ${uploadedPhotos.length} fotos del hogar para ${username}`);

        return res.json({
            message: 'Fotos del hogar agregadas exitosamente',
            photos: uploadedPhotos,
            totalPhotos: user.homePhotos.length
        });
    } catch (error) {
        console.error('Error al agregar fotos del hogar:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

/**
 * DELETE /api/photos/home/:publicId
 * Eliminar una foto del hogar específica
 */
router.delete('/home/:publicId', verifyToken, async (req, res) => {
    try {
        const { publicId } = req.params;
        const username = req.user.username || req.username;

        if (!username) {
            return res.status(401).json({ message: 'Usuario no autenticado' });
        }

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Buscar la foto en el array
        const photoIndex = user.homePhotos.findIndex(p => p.publicId === publicId);
        
        if (photoIndex === -1) {
            return res.status(404).json({ message: 'Foto no encontrada' });
        }

        // Eliminar de Cloudinary
        await deleteImage(publicId);

        // Eliminar del array
        user.homePhotos.splice(photoIndex, 1);
        await user.save();

        return res.json({
            message: 'Foto del hogar eliminada exitosamente',
            remainingPhotos: user.homePhotos.length
        });
    } catch (error) {
        console.error('Error al eliminar foto del hogar:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

/**
 * PUT /api/photos/home/:publicId/description
 * Actualizar descripción de una foto del hogar
 */
router.put('/home/:publicId/description', verifyToken, async (req, res) => {
    try {
        const { publicId } = req.params;
        const { description } = req.body;
        const username = req.user.username || req.username;

        if (!username) {
            return res.status(401).json({ message: 'Usuario no autenticado' });
        }

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        const photo = user.homePhotos.find(p => p.publicId === publicId);
        
        if (!photo) {
            return res.status(404).json({ message: 'Foto no encontrada' });
        }

        photo.description = description || '';
        await user.save();

        return res.json({
            message: 'Descripción actualizada exitosamente',
            photo: photo
        });
    } catch (error) {
        console.error('Error al actualizar descripción:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

/**
 * GET /api/photos/home/:username
 * Obtener todas las fotos del hogar de un usuario
 */
router.get('/home/:username', async (req, res) => {
    try {
        const { username } = req.params;

        const user = await User.findOne({ username });
        if (!user) {
            return res.status(404).json({ message: 'Usuario no encontrado' });
        }

        // Verificar que el usuario tiene lugar
        if (!user.housingInfo || !user.housingInfo.hasPlace) {
            return res.json({
                photos: [],
                totalPhotos: 0,
                message: 'Este usuario no tiene lugar para compartir'
            });
        }

        return res.json({
            photos: user.homePhotos || [],
            totalPhotos: user.homePhotos ? user.homePhotos.length : 0
        });
    } catch (error) {
        console.error('Error al obtener fotos del hogar:', error);
        return res.status(500).json({ message: 'Error interno del servidor', error: error.message });
    }
});

module.exports = router;
