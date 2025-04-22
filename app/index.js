const http = require('http');
const PORT = process.env.PORT || 3000;

const requestListener = (req, res) => {
  res.writeHead(200);
  res.end('Hello, world!');
};

const server = http.createServer(requestListener);
server.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

