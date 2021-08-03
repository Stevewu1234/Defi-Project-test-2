interface IToken {
    function balanceOf(address account) external view returns (uint);

    function name() external view returns (string memory);

    function transfer(address account, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
