// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Tools/CacheResolverUpgradeable.sol";

// Internal References
import "./Interface/IToken.sol";
import "./Interface/ISystemStatus.sol";
import "./Interface/IRewardState.sol";
import "./Interface/IRewardEscrowUpgradeable.sol";

contract Portal is OwnableUpgradeable,CacheResolverUpgradeable {
    

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_TOKEN = "Token";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";
    bytes32 private constant CONTRACT_REWARDESCROWUPGRADEABLE = "RewardEscrowUpgradeable";

    function resolverAddressesRequired() public view override returns (bytes32[] memory) {
        bytes32[] memory addresses = new bytes32[](4);
        addresses[0] = CONTRACT_TOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
        addresses[3] = CONTRACT_REWARDESCROWUPGRADEABLE;
        return addresses;
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }
        
    function rewardEscrowUpgradeable() internal view returns (IRewardEscrowUpgradeable) {
        return IRewardEscrowUpgradeable(requireAndGetAddress(CONTRACT_REWARDESCROWUPGRADEABLE));
    }
 

    /* ========== variables ========== */
    uint internal totalLockedAmount;
    
    mapping (address => uint) internal accountBalancesLockedAmount;

    mapping (address => uint) internal accountEscrowedLockedAmount;

    mapping (address => uint) internal accountEscrowedAndAvailableAmount;

    function portal_init(address _resolver) external initializer {
        __Ownable_init();
        _cacheInit(_resolver);
        accountEscrowedAndAvailableAmount[_msgSender()] = 0;
    }

    /** ========== public view functions ========== */
    function getTotalLockedAmount() public view returns (uint) {
        return totalLockedAmount;
    }

    function getAccountBalancesLockedAmount(address account) public view returns (uint) {
        return accountBalancesLockedAmount[account];
    }

    function getAccountEscrowedLockedAmount(address account) public view returns (uint) {
        return accountEscrowedLockedAmount[account];
    }

    function getbalanceOfEscrowedAndAvailableAmount(address account) public view returns (uint) {
        return accountEscrowedAndAvailableAmount[account];
    }

    function getAccountTotalLockedAmount(address account) public view returns (uint accountTotalLockedAmount) {
        uint balancesLockedAmount = getAccountBalancesLockedAmount(account);
        uint escrowedLockedAmount = getAccountEscrowedLockedAmount(account);
        accountTotalLockedAmount = balancesLockedAmount + escrowedLockedAmount;

        return accountTotalLockedAmount;
    }


    /** ========== public mutative functions ========== */

    /*
     * @description: stake value to get an attendace rate and a NFT.
     * @dev update user's attendace rate which will be save in the state contract.
     * @param value the amount to stake
     */
    function enter(address player, uint value, bool enterall) public {
        // get user's available token to enter the ecosystem including the escrowed amount
        (uint accountTotalAvailableAmount, uint balanceOfuser, uint balanceOfEscrowed) = _remaininigAvailaleAmount(player);

        require(value <= accountTotalAvailableAmount, "you don't have enough token to enter");

        // register user's token and lock registered amount
        _registerPortalLock(player, balanceOfuser, balanceOfEscrowed, value, enterall);

        emit entered(player, value, enterall);
    }

    /*
     * @description: withdraw value which users enter with.
     * @dev update user's attendace rate and 
     * @param {*}
     */
    function unlockBalances(address player, uint value) public {

        // get user's locked token to withdraw
        uint balancesLockedAmount = getAccountBalancesLockedAmount(player);

        // remove locked token register
        _removeRegisterPortalLock(player, balancesLockedAmount, value);

        emit unlockedBalances(player, value);
    }

    function getReward(address player, uint _rewardSaveDuration) public {
        rewardState().getReward(player, _rewardSaveDuration);
    }

    function exit(address player, uint value, uint _rewardSaveDuration) public {
        unlockedBalances(player, value);
        getReward(player, _rewardSaveDuration);
    }


    /** ========== external mutative function ========== */
    function transferEscrowedToBalancesLocked(address account, uint amount) external onlyRewardEscrow {
        _updateAccountEscrowedLockedAmount(account, amount, false, true);
        _updateAccountBalancesLockedAmount(account, amount, true, false);

        emit transferredEscrowedToBalancesLocked(account, amount);
    }

    // update account escrowed token available quota
    function updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) external onlyRewardEscrow {
        require(add != sub, "not allowed to be the same");
        

        if(add == true) {
            accountEscrowedAndAvailableAmount[account] = accountEscrowedAndAvailableAmount[account] + amount;
        }

        if(sub == true) {
            require(accountEscrowedAndAvailableAmount[account] >= amount, "you don't have enough escrowed token");
            accountEscrowedAndAvailableAmount[account] = accountEscrowedAndAvailableAmount[account] - amount;
        }
    }

    function updateAccountEscrowedLockedAmount(address account, uint amount, bool add, bool sub) external onlyRewardEscrow {
        _updateAccountEscrowedLockedAmount(account, amount, add, sub);
    }

    /** ========== external view function ========== */

    function getTransferableAmount(address account) external view returns (uint transferable) {

        // transferable token will be only calculated from balances of user, excluding escrowed token,
        // becasue escrowed token is not allowed to transfer between wallet.
        uint acountlockedamount = accountBalancesLockedAmount[account];
        uint balanceOf = token().balanceOf(account);

        if( balanceOf <= acountlockedamount) {
            transferable = 0;
        } else {
            transferable = balanceOf - acountlockedamount;
        }
    }

    /** ========== internal mutative functions ========== */

    function _registerPortalLock(
        address player,
        uint balanceOfuser,
        uint balanceOfEscrowed,
        uint value,
        bool enterall
    ) internal {
        
        if(enterall == true) {
            _updateAccountBalancesLockedAmount(player, balanceOfuser, true, false);
            _updateAccountEscrowedLockedAmount(player, balanceOfEscrowed, true, false);
            
        }
        
        // if user doesn't enter all token, system will preferentially enter all escorwed available token
        if(enterall == false) {
            if(value >= balanceOfEscrowed) {
                uint _resttoken = value - balanceOfEscrowed;
                _updateAccountEscrowedLockedAmount(player, balanceOfEscrowed, true, false);
                _updateAccountBalancesLockedAmount(player, _resttoken, true, false);
            }

            if(value < balanceOfEscrowed) {
                _updateAccountEscrowedLockedAmount(player, value, true, false);
            }
        }

    }

    function _removeRegisterPortalLock(
        address player,
        uint balancesLockedAmount,
        uint value
        ) internal {
            require(value <= balancesLockedAmount, "you do not have more locked amount to unlock");
            _updateAccountBalancesLockedAmount(player, value, false, true);
    }

    // update account escrowed and locked token
    function _updateAccountEscrowedLockedAmount(address account, uint updatingLockedAmount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");

        if(add == true) {
            require(accountEscrowedAndAvailableAmount[account] >= updatingLockedAmount, "There are not enough available amount to lock");
            accountEscrowedLockedAmount[account] += updatingLockedAmount;
            accountEscrowedAndAvailableAmount[account] -= updatingLockedAmount;

            totalLockedAmount += updatingLockedAmount;
        }

        if(sub == true) {
            require(accountEscrowedLockedAmount[account] >= updatingLockedAmount, "There are not enough locked amount to sub");
            accountEscrowedLockedAmount[account] -= updatingLockedAmount;
            accountEscrowedAndAvailableAmount[account] += updatingLockedAmount;

            totalLockedAmount -= updatingLockedAmount;
        }
    } 

    // update account balances locked token
    function _updateAccountBalancesLockedAmount(address account, uint updatingLockedAmount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");

        if(add == true) {
            accountBalancesLockedAmount[account] += updatingLockedAmount;

            totalLockedAmount += updatingLockedAmount;
        }

        if(sub == true) {
            accountBalancesLockedAmount[account] -= updatingLockedAmount;

            totalLockedAmount -= updatingLockedAmount;
        }
    }

    /** ========== internal view functions ========== */

    function _remaininigAvailaleAmount(address account) internal view returns (
        uint accountTotalAvailableAmount,
        uint balanceOfuser,
        uint balanceOfEscrowed
    ) {
        balanceOfuser = token().balanceOf(account);
        balanceOfEscrowed = accountEscrowedAndAvailableAmount[account];
        accountTotalAvailableAmount = balanceOfuser + balanceOfEscrowed;
        return (accountTotalAvailableAmount, balanceOfuser, balanceOfEscrowed);
    }

    function _getAccountLockedAmount(address account) internal view returns (
        uint balancesLockedAmount,
        uint escrowedLockedAmount
    ) {
        balancesLockedAmount = getAccountBalancesLockedAmount(account);
        escrowedLockedAmount = getAccountEscrowedLockedAmount(account);

        return (balancesLockedAmount, escrowedLockedAmount);
    }

    /** ========== modifier ========== */
    modifier onlyRewardEscrow() {
        require(address(rewardEscrowUpgradeable()) == _msgSender(), "only rewardEscrow contract can access");
        _;
    }

    /** ========== event ========== */
    event transferredEscrowedToBalancesLocked(address indexed account, uint indexed amount);
    event entered(address indexed player, uint indexed value, bool indexed enterall);
    event unlockedBalances(address indexed player, uint indexed value);
}
