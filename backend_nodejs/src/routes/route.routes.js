const express = require('express');
const router = express.Router();
const { createAndAssignRoute } = require('../controllers/route.controller');

router.post('/assign-route', createAndAssignRoute);

module.exports = router;