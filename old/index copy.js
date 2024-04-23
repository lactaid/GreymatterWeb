const express = require('express');
const mysql = require('mysql2');
const Chart = require('chart.js');
const http = require('http');

const app = express();
const path = require('path');
var os = require('os');
const fs = require('fs');

// Para el uso de variables de entorno
require('dotenv').config()


// Para consultas a la base de datos
const socketIo = require('socket.io');
const server = http.createServer(app);
const io = socketIo(server);

const PORT = 80;
let ip = '0.0.0.0';

// 
const connectedClients = new Map();
let intervalId;

io.on('connection', (socket) =>{

  connectedClients.set(socket.id, {
    machineid: 'global',
  });
  // Llamada inicial
  emitDatabaseChange();

  if (io.engine.clientsCount === 1) {
    intervalId = setInterval(emitDatabaseChange, 5000);
  }

  socket.on('message', (data) => {
    let currentInfo = connectedClients.get(socket.id);
    currentInfo.machineid = data;
    connectedClients.set(socket.id, currentInfo)
    emitDatabaseChange();
  });
  
  socket.on('disconnect', () => {
    // Si el usuario se desconecta
    if (io.engine.clientsCount === 0 && intervalId) {
      clearInterval(intervalId);
      intervalId = undefined;
    }
    connectedClients.delete(socket.id);
  });
});

async function emitDatabaseChange() {
  //console.log('Emitting Database Change');
  for (const [clientId, clientInfo] of connectedClients) {
    try {
      // Hacemos queries distintas para cada cliente
      const customizedData = await fetchData(clientInfo.machineid);
      const globalMetrics = await fetchMetrics();
      //console.log(globalMetrics)

      // Se emite la información customizada a cada cliente
      io.to(clientId).emit('database_change', customizedData);
    } catch (error) {
      console.error('Error emitting database change:', error);
    }
  }
}

async function fetchData(value) {
  let production_query = `SELECT production_time, produced as Production FROM oeee_visual.production WHERE Machine_ID = '${value}' 
        AND production_time >= curdate() ORDER BY production_time ASC LIMIT 100;`;
  
  if (value === 'global') {
      production_query = `SELECT DATE_FORMAT(production_time, '%Y-%m-%dT%H:%i:00.000Z') as production_time, SUM(produced) as Production
      FROM oeee_visual.production 
      WHERE production_time >= curdate() 
      GROUP BY DATE_FORMAT(production_time, '%Y-%m-%dT%H:%i:00.000Z')
      ORDER BY production_time ASC 
      LIMIT 100;`;

    }

  const machine_query = "SELECT idMachine as ID, state as Estado FROM oeee_visual.machine;"

  try {
    // De momento voy a hacerlo uno por uno, después lo hago automatico
    const [rows, fields] = await sqlconnection.promise().query(production_query);
    const [mrows, mfields] = await sqlconnection.promise().query(machine_query);

    const xData = rows.map(item => item.production_time);
    const yData = rows.map(item => item.Production);
    const machineid = mrows.map(item => item.ID);
    const machinestate = mrows.map(item => item.Estado)

    //console.log(xData, yData, machineid, machinestate);
    return { xData, yData, machineid, machinestate };
    
    
  } catch (error) {
    console.error('Error fetching data from MySQL:', error);
    throw error;
  }
};

async function fetchMetrics() {
  try {
    // Conseguimos todas los archivos sql
    const archivos = await fs.promises.readdir(query_directory);
    // Definimos un espacio para guardar las metricas
    let metrics = {};
    // Por cada consulta
    for (const archivo of archivos) {
      // Definimos la ruta completa
      const rutaCompleta = path.join(query_directory, archivo);
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
    return metrics;
  } catch (error) {
    console.error('Error:', error);
  }
};

// Define your MySQL connection
const sqlconnection = mysql.createConnection({
  host: 'localhost',
  user: process.env.SQL_USER,
  password: process.env.SQL_PASSWORD,
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

const query_directory = 'private\\database\\metric_queries';

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

server.listen(PORT, () => {
    console.log(`Server is running at http://${ip}:${PORT}`);
});