pragma solidity ^0.6.0;

// Inheritance
import "../../node_modules/@openzeppelin/contracts/proxy/Initializable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../Tools/CacheResolver.sol";
import "./ExternStateToken.sol";

// // Libraries
// import "../../node_modules/@openzeppelin/contracts/math/SafeMath.sol";

// Internal references
import "../Interface/IAddressResovler.sol";
import "../Interface/ITokenState.sol";
import "../Interface/IVoteRecord.sol";
import "../SystemController/ISystemStatus.sol";


contract BaseToken is Ownable, Initializable, CacheResolver, ExternStateToken {

    /** erc20 token details */

    string public constant TOKEN_NAME = "TEST";
    string public constant TOKEN_SYMBOL = "TT";
    uint8 public constant TOKEN_DECIMALS = 18;

    // save it for upgrades
    bytes32 public mediatoken;

    AddressResolver public resolver;
    
    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_RESOLVER = "Resolver";
    bytes32 private constant CONTRACT_TOKENSTATE = "TokenState";
    bytes32 private constant CONTRACT_VOTERECORD = "VoteRecord";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";



    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses[0] = CONTRACT_RESOLVER;
        addresses[1] = CONTRACT_TOKENSTATE;
        addresses[2] = CONTRACT_VOTERECORD;
        addresses[3] = CONTRACT_SYSTEMSTATUS;
    }

    function resolver() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function tokenState() internal view returns (ITokenState) {
        return ITokenState(requireAndGetAddress(CONTRACT_TOKENSTATE));
    }

    function voteRecord() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }


    /* ========== ERC20 token function ========== */

    /**
     * @description: Replace Constructor function due to Transparent Proxy module.
     * @dev: The initialize function will be called as a calldata while proxy contract deployment.
     * @param {account} accept the initial supplyment of token and be set as a minter to have the authority to mint new supplyment.
     * @param {_totalSupply} the initial supplyment
     */ 
    function initialize(
        uint _totalSupply,
        address _owner
        )
        public initializer 
    {
        name = TOKEN_NAME;
        symbol = TOKEN_SYMBOL;
        decimals = TOKEN_DECIMALS;

        totalSupply = _totalSupply;
        emit Transfer(address(0), account, _totalSupply);

        minter = _owner;
        emit MinterChanged(address(0), minter);
    }


    /** ========== public mutative functions ========== */

    function transfer(address from, address to, uint value) public systemActive {



        // record user's vote amount after transfer
        voteRecord().moveDelegates(from, to, value);

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferByProxy(messageSender, to, value);
    }

    function transferFrom(address from, address to, uint value) public systemActive {

        

        // record user's vote amount after transfer
        voteRecord().moveDelegates(from, to, value);

        // Perform the transfer: if there is a problem an exception will be thrown in this call.
        _transferFromByProxy(messageSender, to, value);
    }


    function mint(address to, uint value) public systemActive {
        _internalmint(to, value);
        voteRecord().moveDelegates(address(0), to, value);
    }

    


    /** ========== public view functions ========== */


    /** ========== external mutative functions ========== */

    
    /** ========== external view functions ========== */


    /** ========== internal mutative functions ========== */


    /** ========== internal view functions ========== */


    /** ========== modifier ========== */

    modifier systemActive() {
        systemStatus().requireSystemActive();
    }

    /** ========== event ========== */

}