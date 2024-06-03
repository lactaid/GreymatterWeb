const express = require('express');
const mysql = require('mysql2');
const Chart = require('chart.js');
const https = require('http'); //Change to https if using https

const app = express();
const path = require('path');
var os = require('os');
const fs = require('fs');

// Para el uso de variables de entorno
require('dotenv').config()

// Para el uso de formularios
app.use(express.urlencoded({ extended: true }));
app.use(express.json());


// Load the SSL/TLS certificate and private key
// const options = {
//   key: fs.readFileSync(path.join(__dirname, 'key.pem')),
//   cert: fs.readFileSync(path.join(__dirname, 'cert.pem'))
// };

// Para consultas a la base de datos
const socketIo = require('socket.io');
const server = https.createServer(app);
const io = socketIo(server);

const PORT = 443;
let ip = '0.0.0.0';

// 
const connectedClients = new Map();
let intervalId;

io.on('connection', (socket) =>{

  connectedClients.set(socket.id, {
    machineid: 'global',
  });
  
  // Llamada inicial
  //globalDatabaseData();
  emitDatabaseChange();

  if (io.engine.clientsCount === 1) {
    intervalId = setInterval(emitDatabaseChange, 10000);
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

  //socket.on('request_global_data', async (data) => {
    //try {
      //let currentInfo = connectedClients.get(socket.id);
      //currentInfo.machineid = data;
      //connectedClients.set(socket.id, currentInfo)
      //globalDatabaseData();
//
    //} catch (error) {
      //console.error('Error al obtener los datos globales:', error);
    //}
  //});
});

async function emitDatabaseChange() {
  //console.log('Emitting Database Change');
  for (const [clientId, clientInfo] of connectedClients) {
    try {
      // Hacemos queries distintas para cada cliente
      const customizedData = await fetchData(clientInfo.machineid);
      

      // Se emite la información customizada a cada cliente
      io.to(clientId).emit('database_change', customizedData);

      if (clientInfo.machineid == 'global'){
        const globalMetrics = await fetchMetrics();
        //console.log(globalMetrics)
        io.to(clientId).emit('global_metrics', globalMetrics);
      }
      
    } catch (error) {
      console.error('Error emitting database change:', error);
    }
  }
}

async function globalDatabaseData() {
  //console.log('Emitting Database Change');
  for (const [clientId, clientInfo] of connectedClients) {
    try {
      // Hacemos queries distintas para cada cliente
      const customizedData = await fetchData('global');
      const globalMetrics = await fetchMetrics();
      //console.log(globalMetrics)

      // Se emite la información customizada a cada cliente
      io.to(clientId).emit('database_change', customizedData);
      io.to(clientId).emit('global_metrics', globalMetrics);

      
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
      //console.log('global')
    }

  const machine_query = await fs.promises.readFile('private\\database\\machine_query.sql', 'utf8');

  try {
    // De momento voy a hacerlo uno por uno, después lo hago automatico
    const [rows, fields] = await sqlconnection.promise().query(production_query);
    
    const [mrows, mfields] = await sqlconnection.promise().query(machine_query);
    // console.log(mrows)

    const xData = await rows.map(item => item.production_time);
    const yData = await rows.map(item => item.Production);
    const machineStats = await mrows.map(item => ({
      machineid: item.ID,
      machinestate: item.Estado,
      machineproduction: item.TotalProduction,
      machineIT: item.Inactive_Time,
      machineLE: item.TS
    }));
  
    // console.log('Data fetched from MySQL:', xData, yData, machineStats);
    return { xData, yData, machineStats};
    
    
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
      //console.log(sqlScript)
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
  /*user: process.env.SQL_USER, // Variables de entorno, definir en archivo .env, si no existe se debe crear en tu compu
  password: process.env.SQL_PASSWORD,*/
  user: 'root',
  password: 'eckowizard',
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


// VIEWS

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, '/public')));

app.get('/', async (req,res) => {

    res.render('home')
})

app.get('/production', async (req, res) => {
      res.render('production');
});


app.get('/notifications', async (req, res) => {
  try {
      // Consultar las instancias de error activas
      const errorInstanceQuery = 'SELECT ID_ErrorInstance, ID_Error, Machine_ID FROM error_instance WHERE Finished_time IS NULL';
      const [errors] = await sqlconnection.promise().query(errorInstanceQuery);

      // Consultar la tabla repair para obtener el ID del técnico asociado a cada error
      const technicianQuery = 'SELECT technician FROM repair WHERE ErrorInstance = ?';
      const technicians = [];

      for (const error of errors) {
          const [result] = await sqlconnection.promise().query(technicianQuery, [error.ID_ErrorInstance]);
          if (result.length > 0) {
              technicians.push(result[0].technician);
          } else {
              technicians.push(null);
          }
      }

      // Consultar los IDs de máquinas
      const machineIdsQuery = 'SELECT idMachine AS Machine_ID FROM machine';
      const [machineIds] = await sqlconnection.promise().query(machineIdsQuery);

      // Consultar los IDs de errores
      const errorIdsQuery = 'SELECT idError AS Error_ID FROM error';
      const [errorIds] = await sqlconnection.promise().query(errorIdsQuery);

      // Renderizar la vista con los datos obtenidos
      res.render('notifications', { errors, machineIds, errorIds, technicians });
  } catch (error) {
      console.error("Error al obtener notificaciones:", error);
      res.status(500).send("Error interno del servidor");
  }
});


// Ruta que maneja la solicitud POST a '/notifications'
app.post('/notifications', async (req, res) => {
  try {
      // Extract data from the request body
      const { machineID, errorID } = req.body;

      // Insert a new tuple into the 'error_instance' table
      const insertQuery = `INSERT INTO error_instance (ID_Error, Machine_ID, Error_time) VALUES (?, ?, NOW())`;
      await sqlconnection.promise().query(insertQuery, [errorID, machineID]);

      // Update the corresponding machine's state to 'Blocked'
      const updateQuery = `UPDATE machine SET state = 'Blocked' WHERE idMachine = ?`;
      await sqlconnection.promise().query(updateQuery, [machineID]);

      res.redirect('/notifications');
  } catch (error) {
      // Handle errors
      console.error('Error processing notification:', error);
      res.status(500).send('Error processing notification');
  }
});

app.get('/assign/:errorInstanceId', async (req, res) => {
  const errorInstanceId = req.params.errorInstanceId;

  // Query to fetch technicians
  const technicianSql = 'SELECT * FROM technician';
  const [technicians] = await sqlconnection.promise().query(technicianSql);

  // Query to fetch the corresponding error instance
  const errorInstanceSql = 'SELECT * FROM error_instance WHERE ID_ErrorInstance = ?';
  const [errorInstanceRows] = await sqlconnection.promise().query(errorInstanceSql, [errorInstanceId]);
  const errorInstance = errorInstanceRows[0]; 

  //res.send(technicians);
  //res.send(`Asignando instancia de error con ID: ${errorInstanceId}`);
  res.render('assign', { errorInstanceId, errorInstance, technicians });
});

// Ruta que maneja la solicitud POST a '/assign/:errorInstanceId'
app.post('/assign/:errorInstanceId', async (req, res) => {
  const errorInstanceId = req.params.errorInstanceId;
  const technicianId = req.body.technicianId;

  // Crear una nueva instancia en la tabla 'repair'
  const sqlInsertRepair = 'INSERT INTO repair (ErrorInstance, technician, Asigned_time) VALUES (?, ?, NOW())';
  const values = [errorInstanceId, technicianId];

  try {
      await sqlconnection.promise().query(sqlInsertRepair, values);
      // Redirigir a la página de notificaciones
      res.redirect('/notifications');
  } catch (error) {
      // Manejar errores
      console.error("Error al insertar en la tabla 'repair':", error);
      res.status(500).send("Error interno del servidor");
  }
});


app.get('/repair', async (req, res) => {
  try {
    // Consultar las instancias de error activas
    const errorInstanceQuery = 'SELECT ID_ErrorInstance, ID_Error, Machine_ID FROM error_instance WHERE Finished_time IS NULL';
    const [errors] = await sqlconnection.promise().query(errorInstanceQuery);

    // Consultar la tabla repair para obtener el ID del técnico asociado a cada error
    const technicianQuery = `
      SELECT r.technician, t.name, t.lastname 
      FROM repair r 
      LEFT JOIN technician t ON r.technician = t.idtechnician 
      WHERE ErrorInstance = ?`;
    
    const technicians = [];

    for (const error of errors) {
      const [result] = await sqlconnection.promise().query(technicianQuery, [error.ID_ErrorInstance]);
      if (result.length > 0) {
        technicians.push(result[0]);
      } else {
        technicians.push(null);
      }
    }

    // Consultar los IDs de máquinas
    const machineIdsQuery = 'SELECT idMachine AS Machine_ID FROM machine';
    const [machineIds] = await sqlconnection.promise().query(machineIdsQuery);

    // Consultar los IDs de errores
    const errorIdsQuery = 'SELECT idError AS Error_ID FROM error';
    const [errorIds] = await sqlconnection.promise().query(errorIdsQuery);

    // Renderizar la vista con los datos obtenidos
    res.render('repair', { errors, machineIds, errorIds, technicians });
  } catch (error) {
    console.error("Error al obtener notificaciones:", error);
    res.status(500).send("Error interno del servidor");
  }
});


app.get('/register-repair/:errorInstanceId', async (req, res) => {
  try {
      const errorInstanceId = req.params.errorInstanceId;
      
      res.render('register', { errorInstanceId });
    } catch (error) {
      console.error("Error occurred while registering repair:", error);
      res.status(500).send("Internal Server Error");
  }
});

app.post('/register-repair/:errorInstanceId', async (req, res) => {
  try {
      const errorInstanceId = req.params.errorInstanceId;
      const comment = req.body.details;

  const UpdateRepair = 'UPDATE oeee_visual.repair SET Comment = ? WHERE ErrorInstance = ?';
  await sqlconnection.promise().query(UpdateRepair, [comment, errorInstanceId]);
      
  // Update the Finished_time column with the current timestamp
  const updateErrorInstanceQuery = 'UPDATE error_instance SET Finished_time = NOW() WHERE ID_ErrorInstance = ?';
  await sqlconnection.promise().query(updateErrorInstanceQuery, [errorInstanceId]);

  // Update the state column of the corresponding machine to 'Operative'
  const updateMachineQuery = 'UPDATE machine SET state = "Operative" WHERE idMachine = (SELECT Machine_ID FROM error_instance WHERE ID_ErrorInstance = ?)';
  await sqlconnection.promise().query(updateMachineQuery, [errorInstanceId]);


  //res.send(`Successfully registered repair for error instance ID: ${errorInstanceId}`);
  res.redirect('/repair');
  } catch (error) {
      console.error("Error occurred while registering repair:", error);
      res.status(500).send("Internal Server Error");
  }
});

app.get('/repair_history', async (req, res) => {
  try {
      const rows = []
      res.render('history', {results: rows});
    } catch (error) {
      console.error("Error occurred while registering repair:", error);
      res.status(500).send("Internal Server Error");
  }
});

app.post('/repair_history', async (req, res) => {
  try {
    const campo1 = req.body.campo1;
    const campo2 = req.body.campo2;
    const campo3 = req.body.campo3;

    const history_query = `SELECT ErrorInstance, Finished_time, Faultmode, name, lastname, comment
      FROM oeee_visual.error_instance
      INNER JOIN oeee_visual.repair ON ErrorInstance = ID_ErrorInstance
      INNER JOIN oeee_visual.error ON idError = ID_Error
      INNER JOIN oeee_visual.technician ON idtechnician = technician
      WHERE Asigned_time BETWEEN ? AND ?
      AND Comment is not NULL;`;

    const [rows] = await sqlconnection.promise().query(history_query, [campo2, campo3]);

    res.render('history', { results: rows });
  } catch (error) {
    console.error("Error occurred:", error);
    res.status(500).send("Internal Server Error");
  }
})

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