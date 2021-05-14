// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolver.sol";

// Internal References
import "../Interface/IToken.sol"

contract JoinInState is CacheResolver{



    uint public playerAmount;
    
    struct playerAttendanceDate {
        uint attendIndex;
        uint attendRate;
        uint attendTime;
        uint ownedBadgeTokenID;
    }

    mapping (address => mapping(address => uint256)) public BadgeOwner;

    mapping (address => playerAttendanceDate) public playerAttendance;

    mapping (address => )




    /** ========== public mutative functions ========== */
    


    /** ========== public view functions ========== */
    



    /** ========== external mutative functions ========== */



    /** ========== external view functions ========== */



    /** ========== internal mutative functions ========== */



    /** ========== internal view functions ========== */
    function _percapitashareof() internal {}

    function _getAttendRate(address account) internal {
        
    }

    /** ========== private mutative functions ========== */


    /** ========== modifier ========== */

    /** ========== event ========== */

}