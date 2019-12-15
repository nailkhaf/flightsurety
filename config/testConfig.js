/* global artifacts */

const FlightSuretyApp = artifacts.require("FlightSuretyApp")
const FlightSuretyData = artifacts.require("FlightSuretyData")
const BigNumber = require('bignumber.js')

const Config = async function(accounts) {

    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [
        ...accounts.slice(2),
    ]

    let owner = accounts[0]
    let firstAirline = accounts[1]

    let flightSuretyData = await FlightSuretyData.new(firstAirline)
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address, {gas: 100000000})

    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
}
