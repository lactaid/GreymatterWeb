const express = require('express');
const app = express();
const path = require('path');
var os = require('os');

const PORT = 4000;
let ip = '0.0.0.0'; 

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
  const filePath = path.join(__dirname, 'public', 'video', `${videoName}.mp4`);
  // res.send(filePath);
  res.sendFile(filePath);
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


app.listen(PORT, () => {
    console.log(`Server is running at http://${ip}:${PORT}`);
});

