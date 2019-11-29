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

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)
