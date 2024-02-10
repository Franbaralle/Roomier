const express = require('express');
const router = express.Router();
const User = require('../models/user');

router.get('/', async (req, res) => {
    try {
        const homeProfiles = await User.aggregate([{ $sample: { size: 10 } }]); // Obtener 10 perfiles al azar
        res.status(200).json(homeProfiles);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Error del servidor' });
    }
});

module.exports = router;