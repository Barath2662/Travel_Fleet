const connectDB = require('./config/db');
const { startSchedulers } = require('./services/reminderService');
const app = require('./app');
connectDB();

if (process.env.SKIP_SCHEDULERS !== 'true') {
  startSchedulers();
}

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
