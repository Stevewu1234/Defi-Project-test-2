// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Tools/CacheResolver.sol";

// Internal References
import "./Interface/IToken.sol";
import "./Interface/ISystemStatus.sol";
import "./Interface/IRewardState.sol";
import "./Interface/IRewardEscrowUpgradeable.sol";

contract Portal is OwnableUpgradeable,CacheResolver {
    

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_STAKETOKEN = "StakeToken";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";
    bytes32 private constant CONTRACT_REWARDESCROW = "RewardEscrow";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory addresses = new bytes32[](4);
        addresses[0] = CONTRACT_STAKETOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_REWARDSTATE;
        addresses[3] = CONTRACT_REWARDESCROW;
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
        
    function rewardEscrow() internal view returns (IRewardEscrowUpgradeable) {
        return IRewardEscrowUpgradeable(requireAndGetAddress(CONTRACT_REWARDESCROW));
    }
 

    /** ========== variables ========== */
    uint internal totalLockedAmount;
    
    mapping (address => uint) internal accountBalancesLockedAmount;

    mapping (address => uint) internal accountEscrowedLockedAmount;

    mapping (address => uint) internal accountEscrowedAndAvailableAmount;

    function portal_init(address _resolver) initializer {
        __Ownable_init();
        _cacheInit(_resolver);
        EscrowedAndAvailableAmount[account] = 0;
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
        balancesLockedAmount = getAccountBalancesLockedAmount(account);
        escrowedLockedAmount = getAccountEscrowedLockedAmount(account);
        accountTotalLockedAmount = balancesLockedAmount + escrowedLockedAmount;

        return accountTotalLockedAmount;
    }


    /** ========== public mutative functions ========== */

    /**
     * @description: stake value to get an attendace rate and a NFT.
     * @dev update user's attendace rate which will be save in the state contract.
     * @param value the amount to stake
     */
    function enter(address player, uint value, bool enterall) public enterActive {
        // get user's available token to enter the ecosystem including the escrowed amount
        (accountTotalAvailableAmount, balanceOfuser, balanceOfEscrowed) = _remaininigAvailaleAmount(player);

        require(value < accountTotalAvailableAmount, "you don't have enough token to enter");

        // register user's token and lock registered amount
        _registerPortalLock(balanceOfuser, balanceOfEscrowed, value, enterall);

        emit entered(player, value, enterall);
    }

    /**
     * @description: withdraw value which users enter with.
     * @dev update user's attendace rate and 
     * @param {*}
     */
    function withdrow(address player, uint value, bool withdrawall) public {

        // get user's locked token to withdraw
        (balancesLockedAmount, escrowedLockedAmount) = _getAccountLockedAmount(player);

        // remove locked token register
        _removeRegisterPortalLock(balancesLockedAmount, escrowedLockedAmount, value, withdrawall);

        emit withdrawn(player, value, withdrawall);
    }

    function getReward(address player, uint _rewardSaveDuration) public getRewardActive {
        rewardState().getReward(player, _rewardSaveDuration);
    }

    function exit(address player, uint value, bool withdrawall, uint _rewardSaveDuration) external {
        withdrow(player, value, withdrawall);
        getReward(player, _rewardSaveDuration);
    }


    /** ========== external mutative function ========== */
    function transferEscrowedToBalancesLocked(address account, uint amount) external onlyRewardEscrow {
        _updateAccountEscrowedLockedAmount(account, amount, false, true);
        _updateAccountBalancesLockedAmount(account, amount, true, false);

        emit transferredEscrowedToBalancesLocked(account, amount);
    }


    /** ========== external view function ========== */

    function getTransferableAmount(address account, uint value) external view returns (uint transferable) {

        // transferable token will be only calculated from balances of user, excluding escrowed token,
        // becasue escrowed token is not allowed to transfer between wallet.
        uint acountlockedamount = accountBalancesLockedAmount[accunt];

        if( value <= acountlockedamount) {
            transferable = 0;
        } else {
            transferable = value - acountlockedamount;
        }
    }

    /** ========== internal mutative functions ========== */

    function _registerPortalLock(
        uint balanceOfuser,
        uint balanceOfEscrowed,
        uint value,
        bool enterall
    ) internal {
        
        if(enterall == true) {
            _updateAccountBalancesLockedAmount(_msgSender(), balanceOfuser, true, false);
            _updateAccountEscrowedLockedAmount(_mesSender(), balanceOfEscrowed, true, false);
        }
        
        // if user doesn't enter all token, system will preferentially enter all escorwed available token
        if(enterall == false) {
            if(value > balanceOfEscrowed) {
                uint _resttoken = value - balanceOfEscrowed;
                _updateAccountEscrowedLockedAmount(_mesSender(), balanceOfEscrowed, true, false);
                _updateAccountBalancesLockedAmount(_msgSender(), _resttoken, true, false);
            }

            if(value < balanceOfEscrowed) {
                _updateAccountEscrowedLockedAmount(_mesSender(), value, true, false);
            }
        }

    }

    function _removeRegisterPortalLock(
        uint balancesLockedAmount, 
        uint escrowedLockedAmount, 
        uint value, 
        bool withdrawall
        ) internal {

            if(withdrawall == true) {
                _updateAccountBalancesLockedAmount(_msgSender(), balancesLockedAmount, false, true);
                _updateAccountEscrowedLockedAmount(_msgSender(), escrowedLockedAmount, false, true);
            }

            if(withdrawall == false) {
                if(value > escrowedLockedAmount) {
                    uint _resttoken = value - escrowedLockedAmount;
                    _updateAccountEscrowedLockedAmount(_msgSender(), escrowedLockedAmount, false, true);
                    _updateAccountBalancesLockedAmount(_msgSender(), balancesLockedAmount, false, true);
                }

                if(value < escrowedLockedAmount) {
                    _updateAccountEscrowedLockedAmount(_msgSender(), value, false, true);
                }
            }
    }

    // update account escrowed token available quota
    function _updateAccountEscrowedAndAvailableAmount(address account, uint amount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");
        

        if(add == true) {
            accountEscrowedAndAvailableAmount[account] = EscrowedAndAvailableAmount[account] + amount;
        }

        if(sub == true) {
            require(accountEscrowedAndAvailableAmount[account] >= amount, "you don't have enough escrowed token");
            accountEscrowedAndAvailableAmount[account] = EscrowedAndAvailableAmount[account] - amount;
        }
    }

    // update account escrowed and locked token
    function _updateAccountEscrowedLockedAmount(address account, updatingLockedAmount, bool add, bool sub) internal {
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
    function _updateAccountBalancesLockedAmount(address account, uint updatingLockAmount, bool add, bool sub) internal {
        require(add != sub, "not allowed to be the same");

        if(add == true) {
            accountBalancesLockedAmount[account] += updatingLockAmount;

            totalLockedAmount += updatingLockAmount;
        }

        if(sub == true) {
            accountBalancesLockedAmount[account] -= updatingLockAmount;

            totalLockedAmount -= updatingLockAmount;
        }
    }

    /** ========== internal view functions ========== */

    function _remaininigAvailaleAmount(address account) internal view returns (
        uint accountTotalAvailableAmount,
        uint balanceOfuser,
        uint balanceOfEscrowed
    ) {
        balanceOfuser = stakeToken().balanceOf(account);
        balanceOfEscrowed = balanceOfEscrowedAndAvailableAmount(account);
        totalBalanceOfuser = balanceOfuser + balanceOfEscrowed;
        return (totalBalanceOfuser, totalBalanceOf, balanceOfEscrowed);
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
        require(address(rewardEscrow()) == _msgSender(), "only rewardEscrow contract can access");
        _;
    }

    modifier enterActive() {
        require(systemStatus().requireFunctionActive(bytes32("enter"), bytes32("System")), "the function of enter is inactive");
        _;
    }

    modifier getRewardActive() {
        require(systemStatus().requireFunctionActive(bytes32("getreward"), bytes32("System")), "the function of getreward is inactive");
        _;
    }

    /** ========== event ========== */
    event transferredEscrowedToBalancesLocked(address indexed account, uint indexed amount);
    event entered(address indexed player, uint indexed value, bool indexed enterall);
    event withdrawn(address indexed player, uint indexed value, bool indexed withdrawall);
}