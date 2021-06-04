// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";

// Internal References
import "../NFTs/DragonCard_avatar";

contract avatarReward is Ownable {

    mapping(address => mapping(uint => uint)) internal tradingReward;
    mapping(address => mapping(uint => uint)) public extraReward;
    
    INft public avatarAddress;

    constructor (
        address _avataraddress,
        address _resolver
        ) CacheResolverWithoutUpgrade(_resolver) {
        avataraddress = INft(_avataraddress);
    }

    /** ========== external mutative function ========== */


    /** ========== external mutative function onlyOwner ========== */
    function resetAvatarAddress(address _newAvatarAddress) external onlyOwner {
        
    }

    /** ========== external view function ========== */


    /** ========== internal mutative function ========== */
    /** ========== internal view function ========== */



    /** ========== modifier ========== */
    /** ========== event ========== */
}