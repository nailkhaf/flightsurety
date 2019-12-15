# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Purposes

* Flight Surety is flight delay insurance for passengers

* Managed as collaboration between multiple airlines

* Passengers purchase insurance prior to flight

* If flight is delayed due to airline fault, passengers are paid 1.5X the amount
the paid for the insurance

* Oracles provide information flight status information

## Project Requirements

* Separation of Concerns
    * FlightSuretyData contract for data persistence
    * FlightSuretyApp for app logic and oracles code
    * Dapp client for triggering contract calls
    * Server app for simulating Oracles

* Airlines
    * Register first airline when contract is deployed
    * Only existing airline can register a new airline until there at least four
    airlines registered
    * Registration of fifth and subsequent airlines requires multy-part
    consensus of 50% registered airlines
    * Airline can be registered, but does not participated until it submits
    funding of 10 ether

* Passengers
    * Passenger may pay up to 1 ether for purchasing flight insurance
    * Flight numbers and timestamp are fixed for the purpose of the project and
    can be defined in the Dapp client
    * If flight is delayed due to airline fault, passenger receives credit of
    1.5X the amount they paid
    * Funds are transfered from to the passenger wallet only when they initiate
    withdraw

* Oracles
    * Oracles are implemented as a server app
    * Upon startup, upon 20+ oracles are registered and their assigned indexes
    are persisted in memory
    * Client Dapp is used to trigger request to update flight status generation
    OracleRequest event that is captured by server
    * Server will loop through all registered oracles,identify those oracles for
    which the request applies, and respond by calling into app logic contract
    with the appropriate status code

* General
    * Contracts must have operational status control
    * Functions must fail fast
    * Scaffolding code is provided but you are free to replace it with your
    own code
    * Have fun learning!

## Project Structure

* Smart contracts in `./ethereum`

* Server applications as Oracles in `./server`

* Dapp webapp in `./web-app`

## How to run

* Launch app

`npm i` - install dependencies

`npm run ganache:dev` - start ganache testnet

`npm run migrate:dev` - compile and deploy contracts to testnet

`npm run dapp` - launch web dapp

`npm run server` - run oracle servers in background. Don't forget stop them!

* Launch dapp in the browser on `http://localhost:8000`

* Create test flights, click on `Register` button

* Choose flight and buy insurance

* Submit to oracles the flight

* Try payout your money if flight was not in time

* Withdraw your ether

