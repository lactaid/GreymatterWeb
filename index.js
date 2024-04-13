const express = require('express');
const mysql = require('mysql2');
const Chart = require('chart.js');

const app = express();
const path = require('path');
var os = require('os');
const fs = require('fs');

const PORT = 80;
let ip = '0.0.0.0'; 

// Define your MySQL connection
const sqlconnection = mysql.createConnection({
  host: 'localhost',
  user: 'ReadUser',
  password: 'Seeng',
  database: 'oeee_visual'
});
// Connect to MySQL
sqlconnection.connect((err) => {
  if (err) {
      console.error('Error connecting to MySQL:', err);
      return;
  }
  console.log('Connected to MySQL');
});

const directorio = 'public\\database\\metric_queries';

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, '/public')));

app.get('/', async (req,res) => {

    res.render('home')
})

app.get('/stream', async (req,res) => {

    res.render('stream')
})

app.get('/stream/:videoName', (req, res) => {
  const videoName = req.params.videoName;
  // Assuming you have logic to determine the file path based on videoName
  const videoPath = path.join(__dirname, 'public', 'video', `${videoName}.mp4`);
  // res.send(videoPath);

  const stat = fs.statSync(videoPath);
  const fileSize = stat.size;
  const range = req.headers.range;

  if (range) {
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunkSize = end - start + 1;
    const file = fs.createReadStream(videoPath, { start, end });
    const head = {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunkSize,
      'Content-Type': 'video/mp4',
    };

    res.writeHead(206, head);
    file.pipe(res);
  } else {
    const head = {
      'Content-Length': fileSize,
      'Content-Type': 'video/mp4',
    };

    res.writeHead(200, head);
    fs.createReadStream(videoPath).pipe(res);
  }
      
// https://medium.com/@developerom/playing-video-from-server-using-node-js-d52e1687e378
});


app.get('/about', (req, res) => {
  const filePath = path.join(__dirname, 'public', 'files', 'dummy.pdf');
  fs.readFile(filePath, (err, data) => {
    if (err) {
      console.error(err);
      return res.status(500).send('Error retrieving PDF file');
    }
    res.contentType('application/about');
    res.send(data);
  });
});

app.get('/production', async (req, res) => {
      res.render('production');
});

app.get('/production/data/:value', async (req, res) => {
  const value = req.params.value;
  const query = `SELECT production_time, produced FROM oeee_visual.production WHERE Machine_ID = '${value}' AND production_time >= curdate() ORDER BY production_time ASC LIMIT 100;`;

  sqlconnection.query(query, (error, results) => {
      if (error) {
          console.error('Error fetching data from MySQL:', error);
          res.status(500).json({ error: 'Error fetching data from MySQL' });
          return;
      }

      // Procesa los datos y envía la respuesta como JSON
      var xData = results.map(item => item.production_time);
      var yData = results.map(item => item.produced);

      res.json({ xData, yData });
  });
});

app.get('/production/machines', async (req, res) => {
  sqlconnection.query("SELECT idMachine as ID, state as Estado FROM oeee_visual.machine;", (error, results) => {
      if (error) {
          console.error('Error fetching data from MySQL:', error);
          res.status(500).json({ error: 'Error fetching data from MySQL' });
          return;
      }

      // Procesa los datos y envía la respuesta como JSON
      var machineid = results.map(item => item.ID);
      var machinestate = results.map(item => item.Estado);

      res.json({ machineid, machinestate });
  });
});


app.get('/production/metrics', async (req, res) => {
  try {
    // Conseguimos todas los archivos sql
    const archivos = await fs.promises.readdir(directorio);
    // Definimos un espacio para guardar las metricas
    var metrics = {};
    // Por cada consulta
    for (const archivo of archivos) {
      // Definimos la ruta completa
      const rutaCompleta = path.join(directorio, archivo);
      // Leemos la consulta
      const sqlScript = await fs.promises.readFile(rutaCompleta, 'utf8');
      // La ejecutamos
      const [results, fields] = await sqlconnection.promise().query(sqlScript);
      // La añadimos a las metricas
      let obj = results[0];
      for (let key in obj) {
        metrics[key] = obj[key];
      }
    }
    // console.log(metrics)
    res.json(metrics);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});
var ips = os.networkInterfaces();
Object
  .keys(ips)
  .forEach(function(_interface) {
     ips[_interface]
      .forEach(function(_dev) {
        if (_dev.family === 'IPv4' && !_dev.internal) ip = _dev.address 
      }) 
  });



  // From https://gist.github.com/nfort/a29404417452a06ed6e31b3032c7e42b


app.listen(PORT, () => {
    console.log(`Server is running at http://${ip}:${PORT}`);
});