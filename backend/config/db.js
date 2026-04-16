const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGO_URI || (process.env.DATABASE_URL || '').trim();

    if (!mongoUri || !mongoUri.startsWith('mongodb')) {
      throw new Error('MONGO_URI is missing or invalid. Set a valid MongoDB URI in backend/.env');
    }

    await mongoose.connect(mongoUri);
    console.log('MongoDB connected');
  } catch (error) {
    console.error('MongoDB connection failed:', error.message);
    process.exit(1);
  }
};

module.exports = connectDB;
