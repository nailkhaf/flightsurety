pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * The AddressSet library
 */
library AddressSets {
    using SafeMath for uint256;

    struct AddressSet {
        mapping(address => bool) addresses;
        uint256 size;
    }

    function addAddress(AddressSet storage addressSet, address addr) internal {
        require(
            !addressSet.addresses[addr],
            "Address already exist AddressSet"
        );
        addressSet.addresses[addr] = true;
        addressSet.size = addressSet.size.add(1);
    }

    function deleteAddress(AddressSet storage addressSet, address addr)
        internal
    {
        require(addressSet.addresses[addr], "Address not exist in AddressSet");
        delete addressSet.addresses[addr];
        addressSet.size = addressSet.size.sub(1);
    }

    function containsAddress(AddressSet storage addressSet, address addr)
        internal
        view
        returns (bool)
    {
        return addressSet.addresses[addr];
    }

    function countAdresses(AddressSet storage addressSet)
        internal
        view
        returns (uint256)
    {
        return addressSet.size;
    }
}
