// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IDCT{
    function vaults(address holder) view external returns(uint256 amount, uint256 acquiredTime);
}