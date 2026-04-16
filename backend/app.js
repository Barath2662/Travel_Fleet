require('dotenv').config();
require('express-async-errors');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const { errorHandler, notFound } = require('./middleware/errorMiddleware');

const authRoutes = require('./routes/authRoutes');
const tripRoutes = require('./routes/tripRoutes');
const billingRoutes = require('./routes/billingRoutes');
const vehicleRoutes = require('./routes/vehicleRoutes');
const driverRoutes = require('./routes/driverRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

const app = express();

app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'travel-fleet-backend' });
});

app.use('/api/auth', authRoutes);
app.use('/', authRoutes);
app.use('/api', tripRoutes);
app.use('/api', billingRoutes);
app.use('/api', vehicleRoutes);
app.use('/api', driverRoutes);
app.use('/api', paymentRoutes);
app.use('/api', notificationRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
