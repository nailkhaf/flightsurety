const Test = require("../config/testConfig.js");
const BigNumber = require("bignumber.js");
const assert = require("assert");
const expect = require("chai").expect;

contract("FlightSurety", async accounts => {
  let config;

  before("setup contract", async () => {
    config = await Test.Config(accounts);
  });

  describe("App authorization", async () => {
    it("App is not authorized in data", async () => {
      const authorized = await config.flightSuretyData.isAuthorizedApp(
        config.flightSuretyApp.address
      );
      expect(authorized, "App is authorized in data").to.equal(false);
    });

    it("App is authorized in data", async () => {
      await config.flightSuretyData.authorizeApp(
        config.flightSuretyApp.address,
        {from: config.owner}
      );
      const authorized = await config.flightSuretyData.isAuthorizedApp(
        config.flightSuretyApp.address
      );
      expect(authorized, "App is not authorized in data").to.equal(true);
    });
  });

  describe("Registration airline", async () => {
    it("Register first four airlines without multi part", async () => {
      for (account of config.testAddresses.slice(0, 4)) {
        let registered = await config.flightSuretyApp.isAirlineRegistered(
          account,
          {from: account}
        );
        expect(registered, "Airline is already registered").to.equal(false);

        await config.flightSuretyApp.registerAirline(account, {
          from: config.firstAirline
        });

        registered = await config.flightSuretyApp.isAirlineRegistered(account, {
          from: account
        });
        expect(registered, "Airline is not registered").to.equal(true);
      }
    });

    it("Register fifth and sixth airlines with multipart", async () => {
      const fifthAirline = config.testAddresses[4];

      expect(
        await isRegistered(config, fifthAirline),
        "Airline is already registered"
      ).to.equal(false);

      for (account of config.testAddresses.slice(0, 3)) {
        await config.flightSuretyApp.registerAirline(fifthAirline, {
          from: account
        });
      }

      expect(
        await isRegistered(config, fifthAirline),
        "Airline is not registered"
      ).to.equal(true);

      const sixthAirline = config.testAddresses[5];

      expect(
        await isRegistered(config, sixthAirline),
        "Airline is already registered"
      ).to.equal(false);

      for (account of config.testAddresses.slice(0, 3)) {
        await config.flightSuretyApp.registerAirline(sixthAirline, {
          from: account
        });
      }

      expect(
        await isRegistered(config, sixthAirline),
        "Airline is not registered"
      ).to.equal(true);
    });
  });
});

async function isRegistered(config, airline) {
  let registered = await config.flightSuretyApp.isAirlineRegistered(airline, {
    from: airline
  });
  return registered;
}
