// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/zeppelin/Ownable.sol";

// Libraries
import "../Libraries/SafeMath.sol";

contract LiquidityPool is Ownable {
    using SafeMath for uint;

    uint public totalearnings;

    mapping (address => uint) public accountearnings;
    
    address[] public whitelistofpools;



    constructor (address[] _whitelistofpools) {
        whitelistofpools = _whitelistofpools;
    }    



    /** ========== external mutative functions ========== */
    function updateEarnings(address sender, uint value) external  {
        require(_checkIfInWhiteList(_msg.sender()) == true, "the Pool is not allowed to record the earnings");
        _addAccountEarnings(sender, value);
        _addTotalEarnings(value);
        emit earningsUpdated(totalearnings, accountearnings[sender]);
    }

    function addWhiteListOfPools(address[] pooladdresses) external onlyOwner {
        for(uint i = 0; i<pooladdresses[].length; i++) {
            whitelistofpools[i] = pooladdresses[i];
        }
    }

    

    /** ========== external view functions ========== */
    function numWhitelistPools() external view returns (uint) {
        return whitelistofpools[].length;
    }

    function accountEarningRate(address account) external view returns (uint) {
        return accountearnings[account].div(totalearnings);
    }

    /** ========== internal mutative functions ========== */
    function _addTotalEarnings(uint value) internal {
        totalearnings = totalearnings.add(value);
    }

    function _addAccountEarnings(address sender, uint value) internal {
        accountearnings[sender] = accountearnings[sender].add(value);
    }


    /** ========== internal view functions ========== */
    function _checkIfInWhiteList(address _pooladdress) internal view returns(bool inWhiteList) {
        inWhiteList = false;
        for(uint i = 0; i<whitelistofpools[].length; i++) {
            if(whitelistofpools[i] == _pooladdress) {
                return inWhiteList = true;
                break;
            }
        }
    }


    /** ========== event ========== */
    event earningsUpdated(uint indexed _totalearnings, uint indexed _accountearnings);
}