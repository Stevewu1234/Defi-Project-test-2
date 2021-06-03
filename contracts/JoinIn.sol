// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Tools/zeppelin/Ownable.sol";
import "./Tools/CacheResolver.sol";

// Libraries
import "./Libraries/SafeMath.sol";

// Internal References
import "./Interface/IToken.sol";
import "./Interface/ISystemStatus.sol";
import "./Interface/IRewardState.sol";
import "./Interface/IJoinInState.sol";
import "./Interface/IRewardEscrow.sol";

contract JoinIn is Ownable,CacheResolver {
    using SafeMath for uint;
    

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_STAKETOKEN = "StakeToken";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";
    bytes32 private constant CONTRACT_JOININSTATE = "JoinInState";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrow";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses[0] = CONTRACT_STAKETOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
        addresses[3] = CONTRACT_JOININSTATE;
        addresses[4] = CONTRACT_REWARDESCROW;
    }

    function stakeToken() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_STAKETOKEN));
    }
    function systemStatue() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }

    function joinInState() internal view returns (IJoinInState) {
        return IJoinInState(requireAndGetAddress(CONTRACT_JOININSTATE));
    }
        
    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARDESCROW));
    }
    
    /** ========== public mutative functions ========== */
    function JoinIn(uint value) public {
        _remainingAvailable(_msg.Sender());
        joinInState().getStakeToken();        
    }


    /** ========== public view functions ========== */
    



    /** ========== external mutative functions ========== */


    /** ========== external view functions ========== */


    /** ========== internal mutative functions ========== */



    /** ========== internal view functions ========== */

    function _remaininigAvailaleToken(address account) internal view returns (
        uint avaiableToken,
        uint alreadyJoinInAmount

    ) {
        
    }

    function _maxAvaiableAmount(address account) internal view returns (uint) {
        uint amount = address(stakeToken()).balanceOf(account);

        if(address(rewardEscrow()) != address(0)) {
            amount = amount.add(escrowedTokenBalanceOf(account));
        }

        return amount;
    }

    function _avaiableAmount(address account) internal view returns (uint) {
        
    }

    /** ========== private mutative functions ========== */


    /** ========== modifier ========== */

    /** ========== event ========== */


}