// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Internal References
import "../Interface/IAddressResolver.sol";


contract CacheResolver is OwnableUpgradeable  {
    
    IAddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    function _cacheInit(address _resolver) internal initializer {
        resolver = IAddressResolver(_resolver);
    }

    /** ========== public view functions ========== */

    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses)  {}


    /** ========== external mutative functions ========== */
    function rebuildCache() external {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }


    function setAddressResolver(address _resolver) external onlyOwner {
        require(_resolver != address(0), "the resolver is extremely important, so you must set a correct address");
        resolver = IAddressResolver(_resolver);
    }

    /** ========== external view functions ========== */
    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /** ========== internal view functions ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /** ========== event ========== */

    event CacheUpdated(bytes32 name, address destination);
}