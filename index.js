const express = require('express');
const app = express();
const path = require('path');
var os = require('os');
const fs = require('fs');

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

