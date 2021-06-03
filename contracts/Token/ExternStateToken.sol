// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


// Internal References
import "../Interface/ITokenState.sol";


contract ExternStateToken is OwnableUpgradeable{

    /* ERC20 parameter. */
    string private _name;
    string private _symbol;
    uint private _totalSupply;
    address public minter;
    ITokenState public tokenState;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the contract's permit
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    
    function _externStateTokenInit(
        string memory name_,
        string memory symbol_,
        address _minter,
        address _tokenState
    ) internal initializer {
        _name = name_;
        _symbol = symbol_;
        minter = _minter;
        tokenState = ITokenState(_tokenState);
    }


    /* ========== public view functions ========== */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /*
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address _owner, address spender) public view returns (uint) {
        return tokenState.allowance(_owner, spender);
    }

    /*
     * @notice Returns the ERC20 token balance of a given account.
     * @param account token's owner
     */
    function balanceOf(address account) public view returns (uint) {
        return tokenState.balanceOf(account);
    }




    /* ========== public mutative functions ========== */

    function approve(address spender, uint value) public returns (bool) {

        tokenState.setAllowance(_msgSender(), spender, value);
        emit Approval(_msgSender(), spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        approve(spender, allowance(_msgSender(), spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subValue) public returns (bool) {
        require(tokenState.allowance(_msgSender(), spender) >= subValue, "decreased allowance below zero.");
        approve(spender, allowance(_msgSender(), spender) - subValue);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param holder The address to approve from
     * @param spender The address to be approved
     * @param _amount The number of tokens that are approved (2^256-1 means infinite)
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address holder, 
        address spender, 
        uint256 nonce, 
        uint256 expiry, 
        uint _amount,
        bool allowed, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) public
    {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH,keccak256(bytes(name())),keccak256(bytes("1")),getChainId(),address(this)));
        bytes32 STRUCTHASH = keccak256(abi.encode(PERMIT_TYPEHASH,holder,spender,nonce,expiry,allowed));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR,STRUCTHASH));

        require(holder != address(0), "invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "permit-expired");
        require(nonce == nonces[holder]++, "invalid-nonce");
        uint amount = allowed ? _amount : 0;
        tokenState.setAllowance(holder, spender, amount);
        emit Approval(holder, spender, amount);
    }

    // /* ========== OnlyOwner functions ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(address _tokenState) external onlyOwner {
        tokenState = ITokenState(_tokenState);
        emit TokenStateUpdated(_tokenState);
    }

    /* ========== external mutative functions ========== */

    /**
     * @notice Change the minter address
     * @param minter_ The address of the new minter
     */
    function setMinter(address minter_) external {
        require(msg.sender == minter, "Test:setMinter: only the minter can change the minter address");
        emit MinterChanged(minter, minter_);
        minter = minter_;
    }


    /* ========== internal mutative functions ========== */

    function _transfer(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(this), "Cannot transfer to this address");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState.setBalanceOf(from, tokenState.balanceOf(from) - value);
        tokenState.setBalanceOf(to, tokenState.balanceOf(to) + value);


        // Emit a standard ERC20 transfer event
        emit Transfer(from, to, value);

        return true;
    }




    /**
     * @notice Mint new tokens
     * @param to The address of the destination account
     * @param value The number of tokens to be minted
     */
    function _mint(address to, uint value) internal {
        require(msg.sender == minter, "Test:mint: only the minter can mint");
        require(to != address(0) && value != 0, "this mint is invalid");
        
        _totalSupply = _totalSupply + value;
        tokenState.setBalanceOf(to, value);
        emit Minted(address(0), to, value);
    }


    function _burn(address from, uint value) internal {
        require(msg.sender == from, "you are not allowed to burn the token which don't belong to you.");
        
        _totalSupply = _totalSupply - value;
        _transfer(from, address(0), value);
        emit Burned(from, value);
    }


    /* ========== internal view functions ========== */


    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }


    /* ========== event ========== */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event MinterChanged(address indexed minter,address indexed minter_);
    event Minted(address indexed from, address indexed to, uint indexed value);
    event Burned(address indexed from, uint indexed value);
    event TokenStateUpdated(address indexed newtokenstate);
}