// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Inheritance
import "../../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Internal References
import "./CacheResolver.sol";

contract AddressResolver is OwnableUpgradeable {
    
    mapping(bytes32 => address) public addressbook;
    
    constructor (){
        __Ownable_init();
    }

    /** ========== OnlyOwner functions ========== */

    /*
     * @description: update the whole addressbook by array.
     * @param names all the contract name you want to update
     * @param destinations the addresses which all contract names are pointing to.
     */    
    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            addressbook[name] = destination;
            emit AddressImported(name, destination);
        }
    }
    
    /*
     * @description: add one record into addressbook.
     * @param name the contract name you want to add into the mapping of addressbook.
     * @param destination the address which the contract name is pointing to.
     */    
    function importAddress(bytes32 name, address destination) external onlyOwner {
        addressbook[name] = destination;
    }

    /** ========== external functions ========== */
    /*
     * @description: all of the contracts using CacheResolver's code are needed to update their cacheaddress after addressbook's update.
     * @param destinations all contracts' addresses which are using CacheResovler's code.
     */    
    function rebuildCaches(CacheResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }


    /** ========== view functions ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
            if (addressbook[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return addressbook[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = addressbook[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }


    /** ========== internal view functions ========== */

    /*
     * @description: the function is just used for checking message.
     * @param contractname check its' bytes32 by the contract name
     */    


    /** ========== event ========== */
    event AddressImported(bytes32 indexed name, address indexed destination);
    
}