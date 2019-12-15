import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import FlightSuretyData from "../../build/contracts/FlightSuretyData.json";
import Config from "./config.json";
import Web3 from "web3";

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];
    this.config = config;
    // this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
    this.web3 = new Web3(
      new Web3.providers.WebsocketProvider(config.url.replace("http", "ws"))
    );
    this.flightSuretyApp = new this.web3.eth.Contract(
      FlightSuretyApp.abi,
      config.appAddress
    );
    this.flightSuretyData = new this.web3.eth.Contract(
      FlightSuretyData.abi,
      config.dataAddress
    );
    this.initialize(callback);
    this.owner = null;
    this.airlines = [];
    this.passengers = [];
    this.flights = getFlights();
  }

  initialize(callback) {
    this.web3.eth.getAccounts((error, accts) => {
      this.owner = accts[0];

      let counter = 1;

      while (this.airlines.length < 5) {
        this.airlines.push(accts[counter++]);
      }

      while (this.passengers.length < 5) {
        this.passengers.push(accts[counter++]);
      }

      callback();
    });
  }

  isPaused(callback) {
    let self = this;
    self.flightSuretyApp.methods.paused().call({from: self.owner}, callback);
  }

  getFlights() {
    return this.flights;
  }

  async authorizeApp() {
    console.log(`#authorizeApp`);
    const authorized = await this.flightSuretyData.methods
      .isAuthorizedApp(this.config.appAddress)
      .call({from: this.owner});
    console.log(`#authorizeApp authorized=${JSON.stringify(authorized)}`);
    if (!authorized) {
      await this.flightSuretyData.methods
        .authorizeApp(this.config.appAddress)
        .send({from: this.owner});
    }

    const airlineRegistered = await this.flightSuretyApp.methods
      .isAirlineRegistered(this.airlines[0])
      .call();

    if (!airlineRegistered) {
      await this.flightSuretyApp.methods
        .registerAirline(this.airlines[0])
        .send({from: this.owner, gas: 210000});
    }
  }

  fetchFlightStatus(flight, callback) {
    let self = this;
    let payload = {
      airline: flight.airline,
      flight: flight.name,
      timestamp: genOrGetTimestamp()
    };
    self.flightSuretyApp.methods
      .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
      .send({from: self.owner}, error => {
        callback(error, payload);
      });
  }

  async listenFlightStatus(callback) {
    this.flightSuretyApp.events.FlightStatusInfo(
      {fromBlock: 0},
      async (err, res) => {
        callback(err, res);
      }
    );
  }

  async isAirlineRegistered() {
    return await this.flightSuretyApp.methods
      .isAirlineRegistered(this.airlines[0])
      .call({from: this.airlines[0]});
  }

  async _isAirlineFunded(airline) {
    return await this.flightSuretyApp.methods
      .isAirlineFunded(airline)
      .call({from: airline});
  }

  async _fundAirlineIfNeed(airline) {
    console.log("_fundAirlineIfNeed");

    let funded = await this._isAirlineFunded(airline);
    console.log(`airline funded:${funded}`);
    if (funded) {
      return;
    }

    await this.flightSuretyApp.methods.fundAirline().send({
      from: airline,
      value: this.web3.utils.toWei("10", "ether")
    });

    funded = await this._isAirlineFunded(airline);
    console.log(`airline funded again:${funded}`);

    if (!funded) {
      throw Error("Can't fund airline");
    }
  }

  async _registerFlight(flight) {
    console.log(`_registerFlight flight=${flight.name}`);
    const timestamp = genOrGetTimestamp();
    let registered = await this.flightSuretyApp.methods
      .isFlightRegistered(flight.airline, flight.name, timestamp)
      .call();

    console.log(`flight registered: ${registered}`);
    if (registered) {
      return;
    }

    await this.flightSuretyApp.methods
      .registerFlight(flight.name, timestamp)
      .send({from: flight.airline});

    registered = await this.flightSuretyApp.methods
      .isFlightRegistered(flight.airline, flight.name, timestamp)
      .call();

    console.log(`flight registered again: ${registered}`);
    if (!registered) {
      throw Error("Flight is not registered");
    }

    saveFlight(flight);
    this.flights.push(flight);
  }

  async registerTestFlights() {
    console.log("registerTestFlights");
    await this._fundAirlineIfNeed(this.airlines[0]);

    const flights = createTestFlights(this.airlines[0]);
    for (let flight of flights) {
      await this._registerFlight(flight);
    }

    console.log(`test flights registered`);
  }

  async buyInsurance(flight) {
    console.log(`buyInsurance flight=${flight.name}`);

    const passenger = this.passengers[0];

    let registered = await this.flightSuretyApp.methods
      .isInsuranceRegistered(
        passenger,
        flight.airline,
        flight.name,
        genOrGetTimestamp()
      )
      .call();

    if (registered) {
      throw Error("Insurance is already registered");
    }

    await this.flightSuretyApp.methods
      .buyInsurance(flight.airline, flight.name, genOrGetTimestamp())
      .send({
        from: passenger,
        value: this.web3.utils.toWei("1", "ether"),
        gas: 210000
      });

    registered = await this.flightSuretyApp.methods
      .isInsuranceRegistered(
        passenger,
        flight.airline,
        flight.name,
        genOrGetTimestamp()
      )
      .call();

    if (!registered) {
      throw Error("Registration insureance is failed");
    }
  }

  async payoutInsurance(flight) {
    const passenger = this.passengers[0];

    let registered = await this.flightSuretyApp.methods
      .isInsuranceRegistered(
        passenger,
        flight.airline,
        flight.name,
        genOrGetTimestamp()
      )
      .call();

    if (!registered) {
      throw Error("Insurance is not registered");
    }

    await this.flightSuretyApp.methods
      .payout(
        flight.airline,
        flight.name,
        genOrGetTimestamp()
      )
      .send({from: passenger});
  }
}

function createTestFlights(airline) {
  return [
    "SU-6056",
    "SU-6057",
    "SU-6058",
    "SU-6059",
    "SU-8888",
    "5N527",
    "5N528",
    "5N529",
    "5N530",
    "DP 414",
    "DP 415",
    "DP 416",
    "DP 417"
  ].map(item => {
    return {
      name: item,
      airline
    };
  });
}

function genOrGetTimestamp() {
  const timestamp = localStorage.getItem("flight-timestamp");
  if (timestamp != undefined) {
    return timestamp;
  } else {
    const now = Date.now().toString();
    localStorage.setItem("flight-timestamp", now);
    return now;
  }
}

function saveFlight(flight) {
  const flights = localStorage.getItem("flights");
  if (flights != undefined) {
    const parsedFlights = JSON.parse(flights);
    parsedFlights.push(flight);
    localStorage.setItem("flights", JSON.stringify(parsedFlights));
  } else {
    localStorage.setItem("flights", JSON.stringify([flight]));
  }
}

function getFlights() {
  const flights = localStorage.getItem("flights");
  return flights != undefined ? JSON.parse(flights) : [];
}
