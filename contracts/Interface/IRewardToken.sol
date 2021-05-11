// SPDX-License-Identifier: MIT
interface IRewardToken {

    function transfer(address from, address to, uint value) external;

    function transferFrom(address from, address to, uint value) external;
}