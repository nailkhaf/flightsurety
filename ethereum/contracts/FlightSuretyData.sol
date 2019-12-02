pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./AddressSets.sol";

contract FlightSuretyData is Ownable, Pausable {
    using SafeMath for uint256;
    using AddressSets for AddressSets.AddressSet;

    enum FlightStatus {
        UNKNOWN,
        ON_TIME,
        LATE_AIRLINE,
        LATE_WEATHER,
        LATE_TECHNICAL,
        LATE_OTHER
    }

    mapping(address => Airline) private airlines;

    mapping(bytes32 => Flight) private flights;

    mapping(address => bool) private authorizedApps;

    event AirlineExisted(address indexed airline);

    event AirlineApproved(address indexed airline, address approver);

    event AirlineRegistered(address indexed airline);

    event AirlineFounded(address indexed airline);

    event AirlineDeposit(address indexed airline, uint256 value);

    /**
     * @dev        Count of registered airlines
     */
    uint256 private countRegisteredAirlines = 0;

    /**
     * @title
     */
    struct Airline {
        bool exists;
        bool registered;
        bool funded;
        AddressSets.AddressSet approvals;
        uint256 balance;
    }

    /**
     * @title
     */
    struct Flight {
        address airline;
        bool registered;
        uint8 statusCode;
        uint256 updatedTimestamp;
    }

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
    }

    function newAirline(address airline) external requireAuthorizedApp {
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
    {
        require(!airlines[airline].funded, "Airline has already funded");

        airlines[airline].funded = true;

        emit AirlineFounded(airline);
    }

    function approveAirline(address airline, address approver)
        external
        requireAuthorizedApp
        requireAirlineExist(airline)
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
    {
        require(msg.value > 0, "Deposit value must more than 0");

        airlines[airline].balance = airlines[airline].balance.add(msg.value);

        emit AirlineDeposit(airline, msg.value);
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

    function isAirlineFounded(address airline)
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

    function getFlight(bytes32 flightKey)
        external
        view
        requireAuthorizedApp
        requireAirlineExist(airline)
        returns (
            address airline,
            bool registered,
            uint8 statusCode,
            uint256 updatedTimestamp
        )
    {
        airline = flights[flightKey].airline;
        registered = flights[flightKey].registered;
        statusCode = flights[flightKey].statusCode;
        updatedTimestamp = flights[flightKey].updatedTimestamp;
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
        string calldata flight,
        uint256 timestamp
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(airline, timestamp, flight));
    }
}
