const express = require('express');
const cors = require('cors');
const db = require('./database');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = 5000;

// ====================== Tests Routes ======================

// إضافة فحص جديد
app.post('/tests', (req, res) => {
  const { name, price, normal_range } = req.body;
  
  db.run(
    'INSERT INTO tests (name, price, normal_range) VALUES (?, ?, ?)',
    [name, price, normal_range],
    function(err) {
      if (err) {
        return res.status(400).json({ error: err.message });
      }
      res.json({ id: this.lastID, message: 'تم إضافة الفحص بنجاح' });
    }
  );
});

// جلب كل الفحوصات
app.get('/tests', (req, res) => {
  db.all('SELECT * FROM tests ORDER BY name', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// تعديل فحص
app.put('/tests/:id', (req, res) => {
  const { name, price, normal_range } = req.body;
  db.run(
    'UPDATE tests SET name=?, price=?, normal_range=? WHERE id=?',
    [name, price, normal_range, req.params.id],
    (err) => {
      if (err) return res.status(400).json({ error: err.message });
      res.json({ message: 'تم تعديل الفحص بنجاح' });
    }
  );
});

// حذف فحص
app.delete('/tests/:id', (req, res) => {
  db.run('DELETE FROM tests WHERE id=?', [req.params.id], (err) => {
    if (err) return res.status(400).json({ error: err.message });
    res.json({ message: 'تم حذف الفحص' });
  });
});

app.listen(PORT, () => {
  console.log(` Server running on http://localhost:${PORT}`);
});