interface ITokenState {
    function setAllowance(address tokenOwner, address spender, uint value) external;

    function setBalanceOf(address account, uint value) external;
    
    function allowance(address owner, address spender) external view returns (uint);

    function balanceOf(address owner) external view returns (uint);
}