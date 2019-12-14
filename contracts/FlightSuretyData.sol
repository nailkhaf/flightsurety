pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./AddressSets.sol";

contract FlightSuretyData is Ownable, Pausable {
    using SafeMath for uint256;
    using AddressSets for AddressSets.AddressSet;

    event AppAuthorized(address indexed app);

    struct Airline {
        bool exists;
        bool registered;
        bool funded;
        AddressSets.AddressSet approvals;
        uint256 balance;
    }

    mapping(address => bool) private authorizedApps;

    mapping(address => Airline) private airlines;

    /**
     * @dev        Count of registered airlines
     */
    uint256 private countRegisteredAirlines = 1;

    event AirlineExisted(address indexed airline);

    event AirlineApproved(address indexed airline, address approver);

    event AirlineRegistered(address indexed airline);

    event AirlineFounded(address indexed airline);

    event AirlineDeposit(address indexed airline, uint256 value);

    mapping(bytes32 => Flight) private flights;

    /**
     * @title
     */
    struct Flight {
        address airline;
        bool registered;
        FlightStatus statusCode;
    }

    event FlightRegistered(
        address indexed airline,
        string flight,
        uint256 timestamp
    );

    enum FlightStatus {
        UNKNOWN,
        ON_TIME,
        LATE_AIRLINE,
        LATE_WEATHER,
        LATE_TECHNICAL,
        LATE_OTHER
    }

    /**
     * @dev        key - hash of owner and flight key
     */
    mapping(bytes32 => Insurance) insurances;

    struct Insurance {
        bool registered;
        bytes32 flightKey;
        address owner;
        uint256 value;
    }

    event InsuranceCreated(address indexed owner, bytes32 flightKey);

    constructor(address firtsAirline) public {
        _newAirline(firtsAirline);
        airlines[firtsAirline].registered = true;
    }

    modifier requireAuthorizedApp() {
        require(authorizedApps[msg.sender], "App is not authorized");
        _;
    }

    modifier requireAirlineExist(address airline) {
        require(airlines[airline].exists, "Airline isn't exist");
        _;
    }

    /**
     * @dev Fallback function for funding smart contract.
     */
    function() external payable {
        revert("Data contract doesn't support fallback function");
    }

    function authorizeApp(address app) external onlyOwner {
        require(!authorizedApps[app], "App already authorized");
        authorizedApps[app] = true;

        emit AppAuthorized(app);
    }

    function newAirline(address airline)
        external
        requireAuthorizedApp
        whenNotPaused
    {
        require(!airlines[airline].exists, "Airline has already existed");

        _newAirline(airline);
    }

    function _newAirline(address airline) private {
        airlines[airline] = Airline({
            exists: true,
            funded: false,
            registered: false,
            balance: 0,
            approvals: AddressSets.AddressSet({size: 0})
        });

        emit AirlineExisted(airline);
    }

    function registerAirline(address airline)
        external
        requireAuthorizedApp
        whenNotPaused
        requireAirlineExist(airline)
    {
        require(
            !airlines[airline].registered,
            "Airline has already registered"
        );

        airlines[airline].registered = true;
        countRegisteredAirlines = countRegisteredAirlines.add(1);

        emit AirlineRegistered(airline);
    }

    function fundAirline(address airline)
        external
        requireAuthorizedApp
        requireAirlineExist(airline)
        whenNotPaused
    {
        require(!airlines[airline].funded, "Airline has already funded");

        airlines[airline].funded = true;

        emit AirlineFounded(airline);
    }

    function approveAirline(address airline, address approver)
        external
        requireAuthorizedApp
        requireAirlineExist(airline)
        whenNotPaused
    {
        require(
            !airlines[airline].approvals.containsAddress(approver),
            "Approver has already approved airline"
        );

        airlines[airline].approvals.addAddress(approver);

        emit AirlineApproved(airline, approver);
    }

    function depositAirlineBalance(address airline)
        external
        payable
        requireAuthorizedApp
        requireAirlineExist(airline)
        whenNotPaused
    {
        require(msg.value > 0, "Deposit value must more than 0");

        airlines[airline].balance = airlines[airline].balance.add(msg.value);

        emit AirlineDeposit(airline, msg.value);
    }

    function newFlight(
        address airline,
        string calldata flight,
        uint256 timestamp
    ) external requireAuthorizedApp whenNotPaused {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        require(!flights[flightKey].registered, "Flight is already registered");

        flights[flightKey] = Flight({
            airline: airline,
            registered: true,
            statusCode: FlightStatus.UNKNOWN
        });

        emit FlightRegistered(airline, flight, timestamp);
    }

    function newInsurance(address _owner, bytes32 _flightKey)
        external
        payable
        requireAuthorizedApp
        whenNotPaused
    {
        require(flights[_flightKey].registered, "Flight is not registered");
        bytes32 insuranceKey = getInsuranceKey(_owner, _flightKey);
        require(
            !insurances[insuranceKey].registered,
            "Insurance is already registered"
        );

        insurances[insuranceKey] = Insurance({
            registered: true,
            flightKey: _flightKey,
            owner: _owner,
            value: msg.value
        });

        emit InsuranceCreated(_owner, _flightKey);
    }

    function updateFlightStatus(bytes32 flightKey, uint256 statusCode)
        external
        requireAuthorizedApp
        whenNotPaused
    {
        require(flights[flightKey].registered, "Flight is not registered");
        flights[flightKey].statusCode = FlightStatus(statusCode);
    }

    function isInsuranceRegistered(address owner, bytes32 flightKey)
        external
        view
        requireAuthorizedApp
        returns (bool)
    {
        require(flights[flightKey].registered, "Flight is not registered");
        bytes32 insuranceKey = getInsuranceKey(owner, flightKey);
        return insurances[insuranceKey].registered;
    }

    function isAirlineExist(address airline)
        external
        view
        requireAuthorizedApp
        returns (bool)
    {
        return airlines[airline].exists;
    }

    function isAirlineRegistered(address airline)
        external
        view
        requireAuthorizedApp
        requireAirlineExist(airline)
        returns (bool)
    {
        return airlines[airline].registered;
    }

    function isAirlineFunded(address airline)
        external
        view
        requireAuthorizedApp
        requireAirlineExist(airline)
        returns (bool)
    {
        return airlines[airline].funded;
    }

    function getAirlineCountApprovals(address airline)
        external
        view
        requireAuthorizedApp
        requireAirlineExist(airline)
        returns (uint256)
    {
        return airlines[airline].approvals.countAdresses();
    }

    function getAirlineBalance(address airline)
        external
        view
        requireAuthorizedApp
        requireAirlineExist(airline)
        returns (uint256)
    {
        return airlines[airline].balance;
    }

    function isAirlineApproved(address airline, address approver)
        external
        view
        requireAuthorizedApp
        requireAirlineExist(airline)
        returns (bool)
    {
        return airlines[airline].approvals.containsAddress(approver);
    }

    function isFlightRegistered(bytes32 flightKey)
        external
        view
        requireAuthorizedApp
        returns (bool)
    {
        return flights[flightKey].registered;
    }

    function getFlightStatusCode(bytes32 flightKey)
        external
        view
        requireAuthorizedApp
        returns (uint256)
    {
        require(flights[flightKey].registered, "Flight is not registered");

        return uint256(flights[flightKey].statusCode);
    }

    function getCountRegisteredAirlines()
        external
        view
        requireAuthorizedApp
        returns (uint256)
    {
        return countRegisteredAirlines;
    }

    function isAuthorizedApp(address app) external view returns (bool) {
        return authorizedApps[app];
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, timestamp, flight));
    }

    function getInsuranceKey(address owner, bytes32 flightKey)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(owner, flightKey));
    }
}
