// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Tools/CacheResolver.sol";


// Internal References
import "./Interface/IToken.sol";
import "./Interface/ISystemStatus.sol";
import "./Interface/IRewardState.sol";
import "./Interface/IPortalState.sol";
import "./Interface/IRewardEscrowUpgradeable.sol";
import "./Interface/ICard.sol";

contract JoinIn is OwnableUpgradeable,CacheResolver {
    

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_STAKETOKEN = "StakeToken";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";
    bytes32 private constant CONTRACT_PORTALSTATE = "PortalState";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrow";
    bytes32 private constant CONTRACT_CARD = "Card";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory addresses = new bytes32[](6);
        addresses[0] = CONTRACT_STAKETOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
        addresses[3] = CONTRACT_JOININSTATE;
        addresses[4] = CONTRACT_REWARDESCROW;
        addresses[5] = CONTRACT_CARD;
        return addresses;
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

    function portalState() internal view returns (IPortalState) {
        return IPortalState(requireAndGetAddress(CONTRACT_PORTALSTATE));
    }
        
    function rewardEscrow() internal view returns (IRewardEscrow) {
        return IRewardEscrow(requireAndGetAddress(CONTRACT_REWARDESCROW));
    }

    function card() internal view returns (ICard) {
        return ICard(requireAndGetAddress(CONTRACT_CARD));
    }
    
    /** ========== public mutative functions ========== */
    


    /** ========== external mutative functions ========== */

    /**
     * @description: stake value to get an attendace rate and a NFT.
     * @dev update user's attendace rate which will be save in the state contract.
     * @param value the amount to stake
     */
    function enter(uint value, bool enterall) external {
        // user's available token to enter the ecosystem including the escrowed amount
        (accountTotalAvailableAmount, balanceOfuser, balanceOfEscrowed) = _remaininigAvailaleToken(_msgSender());

        require(value < accountTotalAvailableAmount, "you don't have enough token to enter");

        // register user's token and lock registered amount
        // portalState().increaseLockedAmount(_msgSender(), value);
        _registerPortalLock(balanceOfuser, balanceOfEscrowed, value, enterall);

        // acquire attendance rate
        uint userRate = _getAttendRate(_msgSender(), value);

        // issue card
        uint userCardId = _distributeNFT(_msgSender());

        // record attendance data
        portalState().appendAttnedanceData(_msgSender(), userRate, userCardId);

    }


    /**
     * @description: withdraw value which users enter with.
     * @dev update user's attendace rate and 
     * @param {*}
     */
    function withdrow(uint value) external {

    }

    function getReward() external {
        
    }

    function secede() external {

    }


    /** ========== external view functions ========== */


    /** ========== internal mutative functions ========== */
    function _getCardID(address _receiver) internal returns (uint mintingTokenId) {
        require(PortalState().getCardAddres() == address(card()));
        
        if(portalState().getCardId() == 0) {
            mintingTokenId = card().mint(_receiver);
            PortalState().distributeCardOnwer(_receiver, address(card()), mintingTokenId);
            return mintingTokenId;
        }

        return mintingTokenId = portalState().getCardId();
    }

    function _registerPortalLock(
        uint balanceOfuser,
        uint balanceOfEscrowed,
        uint value,
        bool enterall
    ) internal {
        
        if(enterall == true) {
            portalState().updateAccountBalancesLockedAmount(_msgSender(), balanceOfuser, false, true);
            portalState().updateAccountEscrowedAndAvailableAmount(_mesSender(), balanceOfEscrowed, false, true);
        }
        
        // if user doesn't enter all token, system will preferentially enter all escorwed available token
        if(enterall == false) {
            if(value > balanceOfEscrowed) {
                uint _resttoken = value - balanceOfEscrowed;
                portalState().updateAccountEscrowedAndAvailableAmount(_mesSender(), balanceOfEscrowed, false, true);
                portalState().updateAccountBalancesLockedAmount(_msgSender(), _resttoken, false, true);
            }

            if(value < balanceOfEscrowed) {
                portalState().updateAccountEscrowedAndAvailableAmount(_mesSender(), value, false, true);
            }
        }

    }


    /** ========== internal view functions ========== */

    function _remaininigAvailaleToken(address account) internal view returns (
        uint accountTotalAvailableAmount,
        uint balanceOfuser,
        uint balanceOfEscrowed
    ) {
        balanceOfuser = stakeToken().balanceOf(account);
        balanceOfEscrowed = portalState().balanceOfEscrowedAndAvailableAmount(account);
        totalBalanceOfuser = balanceOfuser + balanceOfEscrowed;
        return (totalBalanceOfuser, totalBalanceOf, balanceOfEscrowed);
    }

    function _getAttendRate(address _owner, uint value) returns (uint) {
        uint rate;
        // todo: need to make the result accurate as long as there is a division operation
        // risk: integer overflow
        rate = value / portalState().TotalAttendedAmount();
        return rate;
    }



    /** ========== private mutative functions ========== */


    /** ========== modifier ========== */

    /** ========== event ========== */


}