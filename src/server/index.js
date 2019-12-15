const http = require('http')
const app = require('./server')

const server = http.createServer(app)
let currentApp = app
const oracleIndex = process.env.ORACLE_INDEX || 0;
server.listen(3000 + oracleIndex)

if (module.hot) {
 module.hot.accept('./server', () => {
  server.removeListener('request', currentApp)
  server.on('request', app)
  currentApp = app
 })
}
