/* global contract */

const Test = require("../config/testConfig.js");
const expect = require("chai").expect;

contract("FlightSurety", async accounts => {
  let config;
  let flight;

  before("setup contract", async () => {
    config = await Test.Config(accounts);
    flight = {
      airline: config.firstAirline,
      flightName: "Flight name",
      timestamp: "123456789"
    };
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
      for (let account of config.testAddresses.slice(0, 4)) {
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

  describe("Airline funding", async () => {
    it("Not registered Airline can't fund", async () => {
      const notRegisteredAirline = config.testAddresses[7];
      let err = undefined;
      try {
        await config.flightSuretyApp.fundAirline({
          from: notRegisteredAirline,
          value: web3.utils.toWei("10", "ether")
        });
      } catch (e) {
        err = e;
      }
      expect(err, "Not funded Airline was registered").not.equal(undefined);
    });

    it("Registered Airline can fund", async () => {
      await config.flightSuretyApp.fundAirline({
        from: config.firstAirline,
        value: web3.utils.toWei("10", "ether")
      });

      const funded = await config.flightSuretyApp.isAirlineFunded(
        config.firstAirline
      );

      expect(funded, "Airline not funded").to.equal(true);
    });
  });

  describe("Flight registration", async () => {
    it("Airline can register new flight", async () => {
      const airline = flight.airline;
      const flightName = flight.flightName;
      const timestamp = flight.timestamp;

      await config.flightSuretyApp.registerFlight(flightName, timestamp, {
        from: airline
      });

      const registered = await config.flightSuretyApp.isFlightRegistered(
        airline,
        flightName,
        timestamp
      );

      expect(registered, "Flight is not registered").to.equal(true);
    });
  });

  describe("Purchase insurance", async () => {
    it("Buy insurance", async () => {
      const buyer = config.testAddresses[7];
      const airline = flight.airline;
      const flightName = flight.flightName;
      const timestamp = flight.timestamp;

      await config.flightSuretyApp.buyInsurance(
        airline,
        flightName,
        timestamp,
        {from: buyer, value: web3.utils.toWei("0.5", "ether")}
      );

      const registered = await config.flightSuretyApp.isInsuranceRegistered(
        buyer,
        airline,
        flightName,
        timestamp,
        {from: buyer}
      );

      expect(registered, "Insurance is not registered").to.be.equal(true);
    });
  });
});

async function isRegistered(config, airline) {
  let registered = await config.flightSuretyApp.isAirlineRegistered(airline, {
    from: airline
  });
  return registered;
}
