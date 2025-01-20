const express = require('express');
const app = express();
const port = 8080;

app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/', (req, res) => {
  res.json({ message: 'Hello from demo API!' });
});

app.listen(port, () => {
  console.log(`API listening on port ${port}`);
});
