/* global contract web3 */

var Test = require("../config/testConfig.js");
// var BigNumber = require('bignumber.js');
const expect = require("chai").expect;

// Watch contract events
const STATUS_CODE_UNKNOWN = 0;
const STATUS_CODE_ON_TIME = 1;
const STATUS_CODE_LATE_AIRLINE = 2;
const STATUS_CODE_LATE_WEATHER = 3;
const STATUS_CODE_LATE_TECHNICAL = 4;
const STATUS_CODE_LATE_OTHER = 5;

contract("Oracles", async accounts => {
  const TEST_ORACLES_COUNT = 20;
  var config;

  before("setup contract", async () => {
    config = await Test.Config(accounts);

    await config.flightSuretyData.authorizeApp(config.flightSuretyApp.address, {
      from: config.owner
    });
  });

  it("can register oracles", async () => {
    // ARRANGE
    let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();

    // ACT
    for (let a = 1; a <= TEST_ORACLES_COUNT; a++) {
      await config.flightSuretyApp.registerOracle({
        from: accounts[a],
        value: fee
      });

      let result = await config.flightSuretyApp.getMyIndexes.call({
        from: accounts[a]
      });

      console.log(
        `${a} Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`
      );
    }
  });

  it("can request flight status", async () => {
    // ARRANGE
    let flight = "ND1309"; // Course number
    let timestamp = Math.floor(Date.now() / 1000);

    // Submit a request for oracles to get status information for a flight
    await config.flightSuretyApp.fundAirline({
      from: config.firstAirline,
      value: web3.utils.toWei("10", "ether")
    });
    await config.flightSuretyApp.registerFlight(flight, timestamp, {
      from: config.firstAirline
    });
    await config.flightSuretyApp.fetchFlightStatus(
      config.firstAirline,
      flight,
      timestamp
    );
    // ACT

    let events = await config.flightSuretyApp.getPastEvents("OracleRequest", {
      fromBlock: 0,
      toBlock: "latest"
    });

    const requestedIndex = events[0].returnValues[0];

    console.log(`index=${requestedIndex}`);

    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    for (let a = 1; a <= TEST_ORACLES_COUNT; a++) {
      // Get oracle information
      let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({
        from: accounts[a]
      });

      for (let idx = 0; idx < oracleIndexes.length; idx++) {
        const oracleIndex = oracleIndexes[idx];
        if (oracleIndex != requestedIndex) continue;

        const statusCode = await config.flightSuretyApp.getFlightStatusCode(
          config.firstAirline,
          flight,
          timestamp
        );

        if (statusCode != STATUS_CODE_UNKNOWN) continue;

        // Submit a response...it will only be accepted if there is an Index match
        await config.flightSuretyApp.submitOracleResponse(
          oracleIndex,
          config.firstAirline,
          flight,
          timestamp,
          STATUS_CODE_ON_TIME,
          {from: accounts[a]}
        );
      }
    }

    const statusCode = (await config.flightSuretyApp.getFlightStatusCode(
      config.firstAirline,
      flight,
      timestamp
    )).toNumber();

    expect(
      statusCode,
      `Incorrect status code:${mapStatusCodeToMessage(statusCode)}`
    ).to.be.equal(STATUS_CODE_ON_TIME);
  });
});

function mapStatusCodeToMessage(statusCode) {
  let message;
  switch (statusCode) {
    case STATUS_CODE_UNKNOWN:
      message = "STATUS_CODE_UNKNOWN";
      break;
    case STATUS_CODE_ON_TIME:
      message = "STATUS_CODE_ON_TIME";
      break;
    case STATUS_CODE_LATE_AIRLINE:
      message = "STATUS_CODE_LATE_AIRLINE";
      break;
    case STATUS_CODE_LATE_WEATHER:
      message = "STATUS_CODE_LATE_WEATHER";
      break;
    case STATUS_CODE_LATE_TECHNICAL:
      message = "STATUS_CODE_LATE_TECHNICAL";
      break;
    case STATUS_CODE_LATE_OTHER:
      message = "STATUS_CODE_LATE_OTHER";
      break;
    default:
      message = "Incorrect status code";
      break;
  }
  return message;
}
