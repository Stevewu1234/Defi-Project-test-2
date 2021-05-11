// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./Tools/CacheResolver.sol";

contract JoinIn is Ownable,CacheResolver {


    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_REWARDTOKEN = "RewardToken"; 
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses[0] = CONTRACT_REWARDTOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
    }

    function rewardToken() internal view returns (IRewardToken) {
        return IRewardToken(requireAndGetAddress(CONTRACT_REWARDTOKEN));
    }

    function systemStatue() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }
    
    /** ========== public mutative functions ========== */
    


    /** ========== public view functions ========== */
    



    /** ========== external mutative functions ========== */


    /** ========== external view functions ========== */


    /** ========== internal mutative functions ========== */


    /** ========== internal view functions ========== */

    /** ========== private mutative functions ========== */


    /** ========== modifier ========== */

    /** ========== event ========== */


}