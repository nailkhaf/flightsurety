pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./AddressSets.sol";

contract FlightSuretyData {
    using SafeMath for uint256;
    using AddressSets for AddressSets.AddressSet;

    mapping(address => Airline) private airlines;

    /**
     * @dev        Count of registered airlines
     */
    uint256 private countRegisteredAirlines = 0;

    /**
     * @title Airline representation state
     */
    struct Airline {
        bool exists;
        bool registered;
        bool funded;
        AddressSets.AddressSet approvals;
        uint256 balance;
    }

    event RegistrationAirlineRequest(
        address indexed airlineAddress,
        bool registered
    );

    event AirlineFunded(address index airlineAddress);

    constructor() public {
        createNewAirline(msg.sender);
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() external payable {
        fund();
    }

    /**
     * @dev        Register or approve airline
     * @param      airlineAddress  The airline address
     */
    function registerAirline(address airlineAddress) external {
        require(
            airlines[msg.sender].registered,
            "Sender must be registered Airline"
        );
        require(
            !airlines[airlineAddress].registered,
            "Airline already registered"
        );

        bool exists = airlines[airlineAddress].exists;

        if (exists) {
            approveAirline(airlineAddress);
        } else {
            createNewAirline(airlineAddress);
        }

        if (airlines[airlineAddress].registered) {
            countRegisteredAirlines = countRegisteredAirlines.add(1);
        }

        emit RegistrationAirlineRequest(
            airlineAddress,
            airlines[airlineAddress].registered
        );
    }

    /**
    * @dev Buy insurance for a flight
    *
    */
    function buy() external payable {}

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees() external view {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay() external view {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     */
    function fund() public payable {
        require(
            airlines[msg.sender].registered,
            "Sender is not registered Airline"
        );
        require(
            !airlines[msg.sender].funded,
            "Sender is already funded"
        );
        require(
            msg.value == 10 ether,
            "Funding value must be 10 ether"
        );

        airlines[msg.sender].funded = true;
        airlines[msg.sender].balance = msg.value;

        emit AirlineFunded(msg.sender);
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev        Until fifth registered airline by default new airline
     * registered
     * @param      airlineAddress  The airline address
     */
    function createNewAirline(address airlineAddress) private {
        require(
            !airlines[airlineAddress].exists,
            "Airline exists, can't create new"
        );

        bool defaultRegistered;
        if (countRegisteredAirlines < 5) {
            defaultRegistered = true;
        } else {
            defaultRegistered = false;
        }

        Airline memory newAirline = Airline({
            exists: true,
            funded: false,
            approvals: AddressSets.AddressSet({
                size: 0
            }),
            registered: defaultRegistered
        });

        airlines[airlineAddress] = newAirline;
    }

    /**
     * @dev        Registration of fifth and subsequent airlines requires
     multy-part consensus of 50% registered airlines
     * @param      airlineAddress  The airline address
     */
    function approveAirline(address airlineAddress) private {
        require(
            airlines[msg.sender].registered,
            "Sender is not Airline, can't approve"
        );
        require(
            airlines[airlineAddress].exists,
            "Airline is not exists, can't approve"
        );
        require(
            !airlines[airlineAddress].registered,
            "Airline already registered, can't approve"
        );
        require(
            !airlines[airlineAddress].approvals.containsAddress(airlineAddress),
            "Sender has already approved this airline"
        );

        uint256 actualCountApprovals = airlines[airlineAddress]
            .approvals
            .countAdresses();

        uint256 requiredCountApprovals;
        if (countRegisteredAirlines % 2 == 0) {
            requiredCountApprovals = countRegisteredAirlines.div(2);
        } else {
            requiredCountApprovals = countRegisteredAirlines.div(2).add(1);
        }

        assert(actualCountApprovals < requiredCountApprovals);

        airlines[airlineAddress].approvals.addAddress(airlineAddress);

        if (
            airlines[airlineAddress].approvals.countAdresses() == requiredCountApprovals
        ) {
            airlines[airlineAddress].registered = true;
        }
    }
}
