// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";

// Libraries
// import "../../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Libraries/SafeMath.sol";

contract LiquidityPool is Ownable {
    using SafeMath for uint;

    uint public totalearnings;

    mapping (address => uint) public accountearnings;
    
    address[] public whitelistofpools;

    uint public whitelistLength;

    constructor (address[] memory _whitelistofpools, uint _whitelistLength) {
        whitelistofpools = _whitelistofpools;
        whitelistLength = _whitelistLength;
    }    



    /** ========== external mutative functions ========== */
    function updateEarnings(address sender, uint value) external {
        require(_checkIfInWhiteList(_msgSender()) == true, "the Pool is not allowed to record the earnings");
        _addAccountEarnings(sender, value);
        _addTotalEarnings(value);
        emit earningsUpdated(totalearnings, accountearnings[sender]);
    }

    function addWhiteListOfPools(address[] memory pooladdresses) external onlyOwner {
        for(uint i = 0; i< whitelistLength; i++) {
            whitelistofpools[i] = pooladdresses[i];
        }
    }

    

    /** ========== external view functions ========== */
    function numWhitelistPools() external view returns (uint) {
        return whitelistLength;
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
        for(uint i = 0; i<whitelistLength; i++) {
            if(whitelistofpools[i] == _pooladdress) {
                return inWhiteList = true;
            }
        }
    }


    /** ========== event ========== */
    event earningsUpdated(uint indexed _totalearnings, uint indexed _accountearnings);
}