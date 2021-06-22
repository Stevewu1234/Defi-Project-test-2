// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolverUpgradeable.sol";

// Internal References
import "../Interface/IToken.sol";
import "../Interface/ISystemStatus.sol";
import "../Interface/IPortal.sol";
import "../Interface/IRewardState.sol";


contract RewardEscrowUpgradeable is OwnableUpgradeable, CacheResolverUpgradeable {

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_TOKEN = "Token"; 
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_PORTAL = "Portal";
    bytes32 private constant CONTRACT_REWARDSTATE = "RewardState";

    function resolverAddressesRequired() public view override returns (bytes32[] memory) {
        bytes32[] memory addresses = new bytes32[](4);
        addresses[0] = CONTRACT_TOKEN;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        addresses[2] = CONTRACT_PORTAL;
        addresses[3] = CONTRACT_REWARDSTATE;
        return addresses;
    }

    function token() internal view returns (IToken) {
        return IToken(requireAndGetAddress(CONTRACT_TOKEN));
    }

    function systemStatue() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function portal() internal view returns (IPortal) {
        return IPortal(requireAndGetAddress(CONTRACT_PORTAL));
    }

    function rewardState() internal view returns (IRewardState) {
        return IRewardState(requireAndGetAddress(CONTRACT_REWARDSTATE));
    }

    /** variables */

    /** Escrow Related Variables */ 

    // detail of an escrow event
    struct accountEscrowed {
        uint escrowedEndTime;
        uint escrowedAmount;
    }
    // an account's escrowed token recording
    mapping (address => mapping(uint => accountEscrowed)) public accountEscrowedEvent;

    // an account's escrow event entries
    mapping (address => uint256[]) public accountEscrowedEntries;

    // an account's total Escrowed token amount
    mapping(address => uint256) public accountTotalEscrowedBalance;

    // total Escrowedtoken in this Escrow Contract
    uint public totalEscrowedBalance;

    // users are not allowed to escrow too much which may encounter unbounded iteration over release
    uint public max_escrowNumber;

    // num of all escrow events in this Escrow Contract and it can be used to generate the next escrow event of an account
    uint public nextEntry;

    /** Vest Related Variables */ 

    // detail of an vest event
    struct accountReleased {
        uint releasedAcquiredTime;
        uint totalReleasedAmount;
    }

    // an account's total Released token amount
    mapping(address => accountReleased) public accountTotalReleasedBalance;

    // duration
    uint public max_escrowduration;

    uint public min_escrowduration;

    //todo the max_escrowduration and min_escrowduration can be defined in RewardState.

    function escrow_init(address _resolver, uint _max_escrowNumber, uint _min_escrowduration, uint _max_escrowduration) external initializer {
        _cacheInit(_resolver);
        __Ownable_init();
        nextEntry = 1;
        max_escrowNumber = _max_escrowNumber;
        min_escrowduration = _min_escrowduration;
        max_escrowduration = _max_escrowduration;
    }


    /** ========== public view functions ========== */
    function accountEscrowedEndTime(address account, uint index) public view returns (uint) {
        return accountEscrowedEvent[account][index].escrowedEndTime;
    }

    function accountEscorwedAmount(address account, uint index) public view returns (uint) {
        return accountEscrowedEvent[account][index].escrowedAmount;
    }

    function accountReleasedAcquiredTime(address account) public view returns (uint) {
        return accountTotalReleasedBalance[account].releasedAcquiredTime;
    }

    function accountTotalReleasedAmount(address account) public view returns (uint) {
        return accountTotalReleasedBalance[account].totalReleasedAmount;
    }

    /** ========== external mutative functions ========== */

    function release(address receiver, bool keepLocked) external {
        uint total;
        uint amount;
        for (uint i = 0; i < _accountEscrowednum(receiver); i++) {
            accountEscrowed storage entry = accountEscrowedEvent[receiver][accountEscrowedEntries[receiver][i]];

            /* Skip entry if escrowAmount == 0 already released */
            if (entry.escrowedAmount != 0) {
                amount = _claimableAmount(entry);

                /* update entry to remove escrowAmount */
                if (amount > 0) {
                    entry.escrowedAmount = 0;
                }

                /* add quantity to total */
                total = total + amount;
            }
        }
            if(total != 0) {
            _release(receiver, total, keepLocked);
        }
    }

    /*
     * @description: the function call will be limited by another contract of this system for restricting users add escrow entries at their will.
     * @param account the account to append a new escrow entry
     * @param amount escrowed amount 
     * @param duration user can customize the duration but need to accord with min duration and max duration
     */    
    function appendEscrowEntry(address account, uint amount, uint duration) external onlyInternalContract {
        require(account != address(0), "null address is not allowed");

        _appendEscrowEntry(account, amount, duration);

    }

    /** ========== OnlyOwner external mutative functions ========== */

    function updateDuration(uint min_escrowduration_, uint max_escrowduration_) external onlyOwner {
        min_escrowduration = min_escrowduration_;
        max_escrowduration = max_escrowduration_;
    }

    /** ========== external view functions ========== */
    
    function escrowedTokenBalanceOf(address account) external view returns (uint amount) {
        return accountTotalEscrowedBalance[account];
    }

    function totalClaimableAmount(address account) external view returns (uint) {
        uint total;
        uint amount;
        for (uint i = 0; i < _accountEscrowednum(account); i++) {
            accountEscrowed memory entry = accountEscrowedEvent[account][accountEscrowedEntries[account][i]];

            /* Skip entry if escrowAmount == 0 already released */
            if (entry.escrowedAmount != 0) {
                amount = _claimableAmount(entry);

                /* add quantity to total */
                total = total + amount;
            }
        }

        return total;
    }

    /** ========== internal mutative functions ========== */

    function _release(address receiver, uint _amount, bool keepLocked) internal {
        require(_amount <= token().balanceOf(address(this)), "there are not enough token to release");

        uint escrowedandlockedAmount = portal().getAccountEscrowedLockedAmount(receiver);
        if(escrowedandlockedAmount > 0) {

            // if user choose to keep locked token locked, 
            // transfer the Locked token Escrowed from balances
            if(keepLocked == true) {
                if(_amount <= escrowedandlockedAmount) {
                    portal().transferEscrowedToBalancesLocked(receiver, _amount);
                }

                if(_amount > escrowedandlockedAmount) {
                    uint _resttoken = _amount - escrowedandlockedAmount;
                    portal().transferEscrowedToBalancesLocked(receiver, escrowedandlockedAmount);

                    portal().updateAccountEscrowedAndAvailableAmount(receiver, _resttoken, false, true);
                    token().transfer(receiver, _resttoken);
                }

            }

            // if user choose to withdraw all token even though there are locked part
            // withdraw escrowedandlockedAmount from portal
            if(keepLocked == false) {
                if(_amount > escrowedandlockedAmount) {
                    portal().withdraw(receiver, escrowedandlockedAmount, false);
                    uint _resttoken = _amount - escrowedandlockedAmount;
                    token().transfer(receiver, _resttoken);
                }

                if(_amount <= escrowedandlockedAmount) {
                    portal().withdraw(receiver, escrowedandlockedAmount, false);
                }
            }

        }
        
        // if there aren't token locked in portal, transfer directly
        if(escrowedandlockedAmount == 0) {
            token().transfer(receiver, _amount);
        }

        // update state in RewardEscrow
        _reduceAccountEscrowedBalance(receiver, _amount);
        _updateAccountReleasedEntry(receiver, _amount);
        emit released(receiver, _amount);
    }


    //todo user can choose to vest their token which is not staked into the contract or vest those have been staked into contract. 
    //     if the vesting token have been staked into contract that maybe I need to provide a new function that vest and stake the token immediately.

    function _appendEscrowEntry(address account, uint _amount, uint _duration) internal {
        require(_duration >= min_escrowduration && _duration <= max_escrowduration, "you must set the duration between allowed duration");
        require(_accountEscrowednum(account) <= max_escrowNumber, "you have escrowed too much, we suggest you wait for your first escrowed token released");
        uint duration = _duration * 1 days;

        // update user's available lockable escrowed token
        portal().updateAccountEscrowedAndAvailableAmount(account, _amount, true, false);

        _addAccountEscrowedBalance(account, _amount);

        uint EndTime = block.timestamp + duration;
        uint entryID = nextEntry;

        accountEscrowedEvent[account][entryID] = accountEscrowed({escrowedEndTime: EndTime, escrowedAmount:_amount});
        accountEscrowedEntries[account].push(entryID);

        nextEntry = nextEntry + 1;

        emit appendedEscrowEntry(account, _amount, duration);
        
    }

    //todo add a internal function to calculate the locked reward of token, the longer they lock, the more they get. 
    //     and the function call is not from this contract, it will call a reward contract to modify some variables to calculate the reward.
    //     but this reward calculation will be confused becase all of the confirmed reward have been lock in this contract. If there is a new reward
    //     from this lock duration that will need to create a new escrow event. That will generate new confusion.


    function _addAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance + _amount;
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account] + _amount;
    }

    function _reduceAccountEscrowedBalance(address account, uint _amount) internal {
        totalEscrowedBalance = totalEscrowedBalance - _amount;
        accountTotalEscrowedBalance[account] = accountTotalEscrowedBalance[account] - _amount;
    }

    function _updateAccountReleasedEntry(address account, uint amount) internal {
        accountReleased storage entry = accountTotalReleasedBalance[account];
        uint currentAmount = entry.totalReleasedAmount;
        entry.releasedAcquiredTime = block.timestamp;
        entry.totalReleasedAmount = currentAmount + amount;
    }

    /** ========== internal view functions ========== */

    function _claimableAmount(accountEscrowed memory _entry) internal view returns (uint) {
        uint256 amount;
        if (_entry.escrowedAmount != 0) {
            /* Escrow amounts claimable if block.timestamp equal to or after entry endTime */
            amount = block.timestamp >= _entry.escrowedEndTime ? _entry.escrowedAmount : 0;
        }
        return amount;
    }


    function _accountEscrowednum(address account) internal view returns (uint num) {
        return num = accountEscrowedEntries[account].length;
    }

    /** ========== modifier ========== */


    modifier onlyInternalContract {
        require(address(rewardState()) == _msgSender(), "only allow internal contract to access");
        _;
    }
    //todo add a modifier to limit the function call of appendEscrowEntry must from a pointed contract
    //todo add a modifier to limit the function call of vest must from authorized user or the owner
 
    /** ========== event ========== */
    event released(address indexed receiver, uint indexed amount);
    event appendedEscrowEntry(address indexed account, uint indexed amount, uint indexed duration);

}