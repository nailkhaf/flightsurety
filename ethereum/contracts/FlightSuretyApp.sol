pragma solidity ^0.5.0;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains
// such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/
// 2018/november/smart-contract-insecurity-bad-arithmetic/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all
    // uint256 types (similar to "prototype" in Javascript)

    FlightSuretyData data;

    constructor(address payable dataContract) public {
        data = FlightSuretyData(dataContract);
    }

    /**
     * @dev        Register or approve airline
     */
    function registerAirline(address airline) external {
        require(data.isAirlineExist(msg.sender), "Sender must be Airline");
        require(
            data.isAirlineRegistered(msg.sender),
            "Sender must be registered Airline"
        );
        require(
            !data.isAirlineRegistered(airline),
            "Airline already registered"
        );

        bool exists = data.isAirlineExist(airline);

        if (!exists) {
            createNewAirline(airline);
        } else {
            approveAirline(airline);
        }

        // emit RegistrationAirlineRequest(
        //     airline,
        //     airlines[airline].registered
        // );

    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed
     * flights resulting in insurance payouts, the contract should be
     * self-sustaining
     */
    function fund() public payable {
        require(
            data.isAirlineRegistered(msg.sender),
            "Sender is not registered Airline"
        );
        require(!data.isAirlineFounded(msg.sender), "Sender is already funded");
        require(msg.value == 10 ether, "Funding value must be 10 ether");


        data.depositAirlineBalance.value(msg.value)(msg.sender);

        data.fundAirline(msg.sender);

        // emit AirlineFunded(msg.sender);

    }

    /**
     * @dev        Only existing airline can register a new airline until there
     * at least four airlines registered
     */
    function createNewAirline(address airline) private {
        require(
            data.isAirlineRegistered(airline),
            "Sender must be registered Airline, can't create new"
        );
        require(
            !data.isAirlineExist(airline),
            "Airline exists, can't create new"
        );

        data.newAirline(airline);

        if (data.getCountRegisteredAirlines() < 5) {
            data.registerAirline(airline);
        }
    }

    /**
     * @dev        Registration of fifth and subsequent airlines requires
     multy-part consensus of 50% registered airlines
     */
    function approveAirline(address airline) private {
        require(
            data.isAirlineExist(msg.sender),
            "Sender must be Airline, can't approve"
        );
        require(
            data.isAirlineRegistered(msg.sender),
            "Sender must be registered Airline, can't approve"
        );
        require(
            data.isAirlineExist(airline),
            "Airline is not exists, can't approve"
        );
        require(
            !data.isAirlineRegistered(airline),
            "Airline already registered, can't approve"
        );
        require(
            !data.isAirlineApproved(airline, msg.sender),
            "Sender has already approved this airline"
        );

        uint256 requiredCountApprovals;
        uint256 countRegisteredAirlines = data.getCountRegisteredAirlines();

        if (countRegisteredAirlines % 2 == 0) {
            requiredCountApprovals = countRegisteredAirlines.div(2);
        } else {
            requiredCountApprovals = countRegisteredAirlines.div(2).add(1);
        }

        assert(data.getAirlineCountApprovals(airline) < requiredCountApprovals);

        data.approveAirline(airline, msg.sender);

        if (data.getAirlineCountApprovals(airline) == requiredCountApprovals) {
            data.registerAirline(airline);
        }
    }

    // /**
    //  * @dev Buy insurance for a flight
    //  */
    // function buy() external payable {
    //     require(
    //          msg.value <= 1 ether,
    //          "Insurance costs up to 1 ether"
    //     );

    // }

    // /**
    //  *  @dev Credits payouts to insurees
    //  */
    // function creditInsurees() external view {

    // }

    // /**
    //  *  @dev Transfers eligible payout funds to insuree
    //  */
    // function pay() external view {

    // }

    // /**
    // * @dev Register a future flight for insuring.
    // *
    // */
    // function registerFlight() external pure {}

    // /**
    // * @dev Called after oracle has updated flight status
    // *
    // */
    // function processFlightStatus(
    //     address airline,
    //     string memory flight,
    //     uint256 timestamp,
    //     uint8 statusCode
    // ) internal pure {}

    // // Generate a request for oracles to fetch flight information
    // function fetchFlightStatus(
    //     address airline,
    //     string flight,
    //     uint256 timestamp
    // ) external {
    //     uint8 index = getRandomIndex(msg.sender);

    //     // Generate a unique key for storing the request
    //     bytes32 key = keccak256(
    //         abi.encodePacked(index, airline, flight, timestamp)
    //     );
    //     oracleResponses[key] = ResponseInfo({
    //         requester: msg.sender,
    //         isOpen: true
    //     });

    //     emit OracleRequest(index, airline, flight, timestamp);
    // }

    // // region ORACLE MANAGEMENT

    // // Incremented to add pseudo-randomness at various points
    // uint8 private nonce = 0;

    // // Fee to be paid when registering oracle
    // uint256 public constant REGISTRATION_FEE = 1 ether;

    // // Number of oracles that must respond for valid status
    // uint256 private constant MIN_RESPONSES = 3;

    // struct Oracle {
    //     bool isRegistered;
    //     uint8[3] indexes;
    // }

    // // Track all registered oracles
    // mapping(address => Oracle) private oracles;

    // // Model for responses from oracles
    // struct ResponseInfo {
    //     address requester; // Account that requested status
    //     bool isOpen; // If open, oracle responses are accepted
    //     mapping(uint8 => address[]) responses; // Mapping key is the status code reported
    //     // This lets us group responses and identify
    //     // the response that majority of the oracles
    // }

    // // Track all oracle responses
    // // Key = hash(index, flight, timestamp)
    // mapping(bytes32 => ResponseInfo) private oracleResponses;

    // // Event fired each time an oracle submits a response
    // event FlightStatusInfo(
    //     address airline,
    //     string flight,
    //     uint256 timestamp,
    //     uint8 status
    // );

    // event OracleReport(
    //     address airline,
    //     string flight,
    //     uint256 timestamp,
    //     uint8 status
    // );

    // // Event fired when flight status request is submitted
    // // Oracles track this and if they have a matching index
    // // they fetch data and submit a response
    // event OracleRequest(
    //     uint8 index,
    //     address airline,
    //     string flight,
    //     uint256 timestamp
    // );

    // // Register an oracle with the contract
    // function registerOracle() external payable {
    //     // Require registration fee
    //     require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

    //     uint8[3] memory indexes = generateIndexes(msg.sender);

    //     oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    // }

    // function getMyIndexes() external view returns (uint8[3]) {
    //     require(
    //         oracles[msg.sender].isRegistered,
    //         "Not registered as an oracle"
    //     );

    //     return oracles[msg.sender].indexes;
    // }

    // // Called by oracle when a response is available to an outstanding request
    // // For the response to be accepted, there must be a pending request that is open
    // // and matches one of the three Indexes randomly assigned to the oracle at the
    // // time of registration (i.e. uninvited oracles are not welcome)
    // function submitOracleResponse(
    //     uint8 index,
    //     address airline,
    //     string flight,
    //     uint256 timestamp,
    //     uint8 statusCode
    // ) external {
    //     require(
    //         (oracles[msg.sender].indexes[0] == index) ||
    //             (oracles[msg.sender].indexes[1] == index) ||
    //             (oracles[msg.sender].indexes[2] == index),
    //         "Index does not match oracle request"
    //     );

    //     bytes32 key = keccak256(
    //         abi.encodePacked(index, airline, flight, timestamp)
    //     );
    //     require(
    //         oracleResponses[key].isOpen,
    //         "Flight or timestamp do not match oracle request"
    //     );

    //     oracleResponses[key].responses[statusCode].push(msg.sender);

    //     // Information isn't considered verified until at least MIN_RESPONSES
    //     // oracles respond with the *** same *** information
    //     emit OracleReport(airline, flight, timestamp, statusCode);
    //     if (
    //         oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
    //     ) {
    //         emit FlightStatusInfo(airline, flight, timestamp, statusCode);

    //         // Handle flight status as appropriate
    //         processFlightStatus(airline, flight, timestamp, statusCode);
    //     }
    // }

    // function getFlightKey(address airline, string flight, uint256 timestamp)
    //     internal
    //     pure
    //     returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(airline, timestamp, flight));
    // }

    // // Returns array of three non-duplicating integers from 0-9
    // function generateIndexes(address account) internal returns (uint8[3]) {
    //     uint8[3] memory indexes;
    //     indexes[0] = getRandomIndex(account);

    //     indexes[1] = indexes[0];
    //     while (indexes[1] == indexes[0]) {
    //         indexes[1] = getRandomIndex(account);
    //     }

    //     indexes[2] = indexes[1];
    //     while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
    //         indexes[2] = getRandomIndex(account);
    //     }

    //     return indexes;
    // }

    // // Returns array of three non-duplicating integers from 0-9
    // function getRandomIndex(address account) internal returns (uint8) {
    //     uint8 maxValue = 10;

    //     // Pseudo random number...the incrementing nonce adds variation
    //     uint8 random = uint8(
    //         uint256(
    //             keccak256(
    //                 abi.encodePacked(blockhash(block.number - nonce++), account)
    //             )
    //         ) %
    //             maxValue
    //     );

    //     if (nonce > 250) {
    //         nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
    //     }

    //     return random;
    // }

    // // endregion

}
