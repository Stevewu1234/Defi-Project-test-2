// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

abstract contract SendValueWithFallbackWithdraw is ContextUpgradeable, ReentrancyGuardUpgradeable{
    using AddressUpgradeable for address payable;
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private pendingWithdrawals;

    function pendingWithdrawal(address account) public view returns (uint256) {
        return pendingWithdrawals[account];
    }


    function withdraw() public {
        withdrawfor(_msgSender());
    }


    function withdrawfor(address payable account) public nonReentrant {
        uint256 amount = pendingWithdrawals[account];
        require(amount > 0, "no pending funds");
        pendingWithdrawals[account] = 0;
        account.sendValue(amount);

        emit withDrawal(account, amount);
    }

    function _sendValueWithFallbackWithdrawWithLowGasLimit(address payable account, uint256 amount) internal {
        _sendValueWithFallbackWithdraw(account, amount, 20000);
    }

    function _sendValueWithFallbackWithdrawWithMediumGasLimit(address payable account, uint256 amount) internal {
        _sendValueWithFallbackWithdraw(account, amount, 210000);
    }

    function _sendValueWithFallbackWithdraw(address payable account, uint256 amount, uint256 gaslimit) private {
        require(amount > 0, "no enough funds to send");

        (bool success, ) = account.call({value: amount, gas: gaslimit})("");

        if(!success) {
            pendingWithdrawals[account] = pendingWithdrawals[account].add(amount);
            
            emit withDrawPending(account, amount);
        }
    }

    event withDrawPending(address indexed account, uint256 amount);
    event withDrawal(address indexed account, uint256 amount);
}