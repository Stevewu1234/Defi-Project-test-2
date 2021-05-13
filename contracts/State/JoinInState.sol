// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Tools/CacheResolver.sol";

contract JoinInState is CacheResolver{

    uint public players;
    
    struct playerAttendanceDate {
        uint attendIndex;
        uint attendRate;
        uint attendTime;
        uint ownedBadgeTokenID;
    }

    mapping (address => mapping(address => uint256)) public BadgeOwner;

    mapping (address => playerAttendanceDate) public playerAttendance;


    constructor () {

    }
    /** ========== public mutative functions ========== */
    


    /** ========== public view functions ========== */
    



    /** ========== external mutative functions ========== */


    /** ========== external view functions ========== */


    /** ========== internal mutative functions ========== */



    /** ========== internal view functions ========== */
    function _percapitashareof() internal {}

    /** ========== private mutative functions ========== */


    /** ========== modifier ========== */

    /** ========== event ========== */

}