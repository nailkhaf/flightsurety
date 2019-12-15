const FlightSuretyApp = require("../../build/contracts/FlightSuretyApp.json");
const Config = require("./config.json");
const Web3 = require("web3");
const express = require("express");
// const HDWalletProvider = require("@truffle/hdwallet-provider");

let config = Config["localhost"];

const ORACLE_ACCOUNTS_START_FROM = 10;

// const mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat"

// const provider = new HDWalletProvider(mnemonic, config.url, 0, 50);
// const web3 = new Web3(provider)

let web3 = new Web3(
  new Web3.providers.WebsocketProvider(config.url.replace("http", "ws"))
);

const oracleIndex = parseInt(process.env.ORACLE_INDEX) || 0;
console.log(`oracleIndex=${JSON.stringify(process.env.ORACLE_INDEX)}`);
const oracleAccountIndex = ORACLE_ACCOUNTS_START_FROM + oracleIndex;

let flightSuretyApp = new web3.eth.Contract(
  FlightSuretyApp.abi,
  config.appAddress
);

async function registerOracle() {
  console.log(`#registerOracle`);
  const accounts = await web3.eth.getAccounts();
  const oracleAddress = accounts[oracleAccountIndex];
  console.log(`oracleAccountIndex=${oracleAccountIndex}`);
  console.log(`accountsSize=${accounts.length}`);
  console.log(`oracleAddress=${oracleAddress}`);

  const oracleRegistered = await flightSuretyApp.methods
    .isOracleRegistered(oracleAddress)
    .call({from: oracleAddress});

  console.log(`check`);

  if (!oracleRegistered) {
    await flightSuretyApp.methods.registerOracle().send({
      from: oracleAddress,
      value: web3.utils.toWei("1", "ether"),
      gas: 2100000
    });
  }

  const indexes = await flightSuretyApp.methods
    .getMyIndexes()
    .call({from: oracleAddress});

  return {
    indexes,
    oracleAddress
  };
}

function listenRequests(oracle) {
  console.log(`listenRequests, indexes=${JSON.stringify(oracle.indexes)}`);

  flightSuretyApp.events.OracleRequest(
    {
      fromBlock: 0
    },
    async (error, event) => {
      // if (error) console.log(error);

      const index = event.returnValues.index;
      if (oracle.indexes.includes(index)) {
        const airline = event.returnValues.airline;
        const flight = event.returnValues.flight;
        const timestamp = event.returnValues.timestamp;

        const statusCode = await flightSuretyApp.methods
          .getFlightStatusCode(airline, flight, timestamp)
          .call({
            from: oracle.oracleAddress
          });

        if (statusCode == 0) {
          console.log(`#submitOracleResponse oracleIndex=${oracleIndex}, index=${index}`)

          let statusCode = 1
          if (Math.random() > 0.5) {
            statusCode = 2
          }

          await flightSuretyApp.methods
            .submitOracleResponse(index, airline, flight, timestamp, statusCode)
            .send({
              from: oracle.oracleAddress
            });
        }
      }
    }
  );
}

async function startOracle() {
  const oracle = await registerOracle();
  listenRequests(oracle);
}

const app = express();
app.get("/api", (req, res) => {
  res.send({
    message: "An API for use with your Dapp!"
  });
});

module.export = app;

startOracle();
