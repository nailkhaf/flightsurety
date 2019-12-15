pragma solidity ^0.5.0;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains
// such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/
// 2018/november/smart-contract-insecurity-bad-arithmetic/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./FlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp is Ownable, Pausable {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all
    // uint256 types (similar to "prototype" in Javascript)

    FlightSuretyData data;

    event AirlineRegistered(address indexed airline);

    event AirlineFunded(address indexed airline);

    event FlightRegistered(
        address indexed airline,
        string flight,
        uint256 timestamp
    );

    event InsuranceCreated(address indexed owner, bytes32 fligthKey);

    event InsurancePayout(address indexed owner, bytes32 fligthKey);

    constructor(address payable dataContract) public {
        data = FlightSuretyData(dataContract);
    }

    /**
     * @dev        Register or approve airline
     */
    function registerAirline(address airline) external whenNotPaused {
        require(data.isAirlineExist(msg.sender), "Sender must be Airline");
        require(
            data.isAirlineRegistered(msg.sender),
            "Sender must be registered Airline"
        );

        bool exists = data.isAirlineExist(airline);

        if (!exists) {
            createNewAirline(airline);
        }

        approveAirline(airline);
    }

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed
     * flights resulting in insurance payouts, the contract should be
     * self-sustaining
     */
    function fundAirline() external payable whenNotPaused {
        require(data.isAirlineExist(msg.sender), "Sender is not Airline");
        require(
            data.isAirlineRegistered(msg.sender),
            "Sender is not registered Airline"
        );
        require(!data.isAirlineFunded(msg.sender), "Sender is already funded");
        require(msg.value == 10 ether, "Funding value must be 10 ether");

        data.depositAirlineBalance.value(msg.value)(msg.sender);

        data.fundAirline(msg.sender);

        emit AirlineFunded(msg.sender);
    }

    /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight(string calldata flight, uint256 timestamp)
        external
        whenNotPaused
    {
        require(data.isAirlineExist(msg.sender), "Airline is not exist");
        require(
            data.isAirlineRegistered(msg.sender),
            "Airline is not registered"
        );
        require(data.isAirlineFunded(msg.sender), "Airline is not funded");
        bytes32 flightKey = data.getFlightKey(msg.sender, flight, timestamp);
        require(
            !data.isFlightRegistered(flightKey),
            "Flight already registered"
        );

        data.newFlight(msg.sender, flight, timestamp);

        emit FlightRegistered(msg.sender, flight, timestamp);
    }

    /**
     * @dev Buy insurance for a flight
     */
    function buyInsurance(
        address airline,
        string calldata flight,
        uint256 timestamp
    ) external payable whenNotPaused {
        require(data.isAirlineExist(airline), "Airline is not exist");
        require(data.isAirlineRegistered(airline), "Airline is not registered");
        require(data.isAirlineFunded(airline), "Airline is not funded");
        bytes32 flightKey = data.getFlightKey(airline, flight, timestamp);
        require(data.isFlightRegistered(flightKey), "Flight is not registered");
        require(
            data.getFlightStatusCode(flightKey) == 0,
            "Fligth is already finished"
        );
        require(msg.value <= 1 ether, "Insurance costs up to 1 ether");

        data.newInsurance.value(msg.value)(msg.sender, flightKey);

        emit InsuranceCreated(msg.sender, flightKey);
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     */
    function payout(address airline, string calldata flight, uint256 timestamp)
        external
        whenNotPaused
    {
        require(data.isAirlineExist(airline), "Airline is not exist");
        require(data.isAirlineRegistered(airline), "Airline is not registered");
        require(data.isAirlineFunded(airline), "Airline is not funded");
        bytes32 flightKey = data.getFlightKey(airline, flight, timestamp);
        require(data.isFlightRegistered(flightKey), "Flight is not registered");
        require(data.isInsuranceRegistered(msg.sender, flightKey), "Insurance is not registered");
        require(
            data.getFlightStatusCode(flightKey) != 0,
            "Fligth is not finished"
        );
        require(
            data.getFlightStatusCode(flightKey) != 1,
            "Fligth finished success"
        );

        data.payoutInsurance(msg.sender, flightKey);

        emit InsurancePayout(msg.sender, flightKey);
    }

    /**
     * @dev        Only existing airline can register a new airline until there
     * at least four airlines registered
     */
    function createNewAirline(address airline) private {
        require(
            !data.isAirlineExist(airline),
            "Airline exists, can't create new"
        );

        data.newAirline(airline);
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

        uint256 countRegisteredAirlines = data.getCountRegisteredAirlines();

        uint256 requiredCountApprovals;
        if (countRegisteredAirlines % 2 == 0) {
            requiredCountApprovals = countRegisteredAirlines.div(2);
        } else {
            requiredCountApprovals = countRegisteredAirlines.div(2).add(1);
        }

        assert(data.getAirlineCountApprovals(airline) < requiredCountApprovals);

        data.approveAirline(airline, msg.sender);

        if (
            data.getCountRegisteredAirlines() < 5 ||
            data.getAirlineCountApprovals(airline) == requiredCountApprovals
        ) {
            data.registerAirline(airline);
            emit AirlineRegistered(airline);
        }
    }

    function isAirlineRegistered(address airline) external view returns (bool) {
        if (data.isAirlineExist(airline)) {
            return data.isAirlineRegistered(airline);
        } else {
            return false;
        }
    }

    function isAirlineFunded(address airline) external view returns (bool) {
        if (data.isAirlineExist(airline)) {
            return data.isAirlineFunded(airline);
        } else {
            return false;
        }
    }

    function isFlightRegistered(
        address airline,
        string calldata fligth,
        uint256 timestamp
    ) external view returns (bool) {
        bytes32 flightKey = data.getFlightKey(airline, fligth, timestamp);
        return data.isFlightRegistered(flightKey);
    }

    function isInsuranceRegistered(
        address owner,
        address airline,
        string calldata flightName,
        uint256 timestamp
    ) external view returns (bool) {
        bytes32 flightKey = data.getFlightKey(airline, flightName, timestamp);
        return data.isInsuranceRegistered(owner, flightKey);
    }

    /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus(
        address airline,
        string memory flight,
        uint256 timestamp,
        uint8 statusCode
    ) private {
        bytes32 flightKey = data.getFlightKey(airline, flight, timestamp);
        require(data.isFlightRegistered(flightKey), "Flight doesn't exist");
        require(
            data.getFlightStatusCode(flightKey) == 0,
            "Flight has already status"
        );

        data.updateFlightStatus(flightKey, uint256(statusCode));
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(
        address airline,
        string calldata flight,
        uint256 timestamp
    ) external whenNotPaused {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        oracleResponses[key] = ResponseInfo({
            requester: msg.sender,
            isOpen: true
        });

        emit OracleRequest(index, airline, flight, timestamp);
    }

    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester; // Account that requested status
        bool isOpen; // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses; // Mapping key is the status code reported
        // This lets us group responses and identify
        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    event OracleReport(
        address airline,
        string flight,
        uint256 timestamp,
        uint8 status
    );

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(
        uint8 index,
        address airline,
        string flight,
        uint256 timestamp
    );

    // Register an oracle with the contract
    function registerOracle() external payable whenNotPaused {
        require(
            !oracles[msg.sender].isRegistered,
            "Oracle is already registered"
        );

        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        Oracle memory oracle = Oracle({isRegistered: true, indexes: indexes});

        oracles[msg.sender] = oracle;
    }

    function getMyIndexes() external view returns (uint8[3] memory) {
        require(
            oracles[msg.sender].isRegistered,
            "Not registered as an oracle"
        );

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(
        uint8 index,
        address airline,
        string calldata flight,
        uint256 timestamp,
        uint8 statusCode
    ) external whenNotPaused {
        require(
            (oracles[msg.sender].indexes[0] == index) ||
                (oracles[msg.sender].indexes[1] == index) ||
                (oracles[msg.sender].indexes[2] == index),
            "Index does not match oracle request"
        );

        bytes32 key = keccak256(
            abi.encodePacked(index, airline, flight, timestamp)
        );
        require(
            oracleResponses[key].isOpen,
            "Flight or timestamp do not match oracle request"
        );

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);

        if (
            oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES
        ) {
            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);
        }
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account)
        internal
        returns (uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - nonce++), account)
                )
            ) %
                maxValue
        );

        if (nonce > 250) {
            nonce = 0; // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

    function getFlightStatusCode(
        address airline,
        string calldata flight,
        uint256 timestamp
    ) external view returns (uint256) {
        bytes32 flightKey = data.getFlightKey(airline, flight, timestamp);
        return data.getFlightStatusCode(flightKey);
    }

    function isOracleRegistered(address oracle) external view returns (bool) {
        return oracles[oracle].isRegistered;
    }

    // // endregion

}
