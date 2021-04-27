pragma solidity ^0.6.0;

// Inheritance
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../../node_modules/@openzeppelin/contracts/proxy/Initializable.sol";

// Libraries
import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

// // Internal References
// import "./TokenState.sol";


contract ExternStateToken is Ownable{
    
    /* ERC20 parameter. */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    address public minter;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the contract's permit
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;
    
    /* ========== public mutative functions ========== */

    function approve(address spender, uint value) public optionalProxy returns (bool) {
        address sender = messageSender;

        tokenState().setAllowance(sender, spender, value);
        Approval(sender, spender, value);
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
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, uint _amount,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) public
    {
        bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH,keccak256(bytes(name)),getChainId(),address(this)));
        bytes32 STRUCTHASH = keccak256(abi.encode(PERMIT_TYPEHASH,holder,spender,nonce,expiry,allowed));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR,STRUCTHASH));

        require(holder != address(0), "invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "invalid-permit");
        require(expiry == 0 || now <= expiry, "permit-expired");
        require(nonce == nonces[holder]++, "invalid-nonce");
        uint amount = allowed ? _amount : 0;
        tokenState().setAllowance(holder, spender, amount);
        emit Approval(holder, spender, amount);
    }

    /* ========== public view functions ========== */

    /**
     * @notice Returns the ERC20 allowance of one party to spend on behalf of another.
     * @param owner The party authorising spending of their funds.
     * @param spender The party spending tokenOwner's funds.
     */
    function allowance(address owner, address spender) public view returns (uint) {
        return tokenState().allowance(owner, spender);
    }

    /**
     * @notice Returns the ERC20 token balance of a given account.
     * @param account token's owner
     */
    function balanceOf(address account) public view returns (uint) {
        return tokenState().balanceOf(account);
    }

    // /* ========== OnlyOwner functions ========== */

    /**
     * @notice Set the address of the TokenState contract.
     * @dev This can be used to "pause" transfer functionality, by pointing the tokenState at 0x000..
     * as balances would be unreachable.
     */
    function setTokenState(TokenState _tokenState) external OnlyOwner {
        tokenState = _tokenState;
        TokenStateUpdated(address(_tokenState));
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

    function _internalTransfer(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Disallow transfers to irretrievable-addresses. */
        require(to != address(0) && to != address(this) && to != address(proxy), "Cannot transfer to this address");

        // Insufficient balance will be handled by the safe subtraction.
        tokenState().setBalanceOf(from, tokenState().balanceOf(from).sub(value));
        tokenState().setBalanceOf(to, tokenState().balanceOf(to).add(value));

        // Emit a standard ERC20 transfer event
        emitTransfer(from, to, value);

        return true;
    }

    /**
     * @dev Perform an ERC20 token transfer. Designed to be called by transfer functions possessing
     * the onlyProxy or optionalProxy modifiers.
     */
    function _transferByProxy(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        return _internalTransfer(from, to, value);
    }

    /*
     * @dev Perform an ERC20 token transferFrom. Designed to be called by transferFrom functions
     * possessing the optionalProxy or optionalProxy modifiers.
     */
    function _transferFromByProxy(
        address sender,
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        /* Insufficient allowance will be handled by the safe subtraction. */
        tokenState().setAllowance(from, sender, tokenState().allowance(from, sender).sub(value));
        return _internalTransfer(from, to, value);
    }

    /**
     * @notice Mint new tokens
     * @param to The address of the destination account
     * @param amount The number of tokens to be minted
     */
    function _internalmint(address to, uint amount) internal {
        require(msg.sender == minter, "Test:mint: only the minter can mint");
        require(to != address(0) && amount != 0, "this mint is invalid");
        
        totalSupply = totalSupply.add(amount);
        tokenstate().setBalanceOf(to, amount);
        emit Transfer(address(0), to, amount);
    }


    /* ========== internal view functions ========== */


    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
    /* ========== modifier ========== */


    /* ========== event ========== */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event MinterChanged(address indexed minter,address indexed minter_);
}