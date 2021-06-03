// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolver.sol";
import "./ExternStateToken.sol";

// Internal references
import "../Interface/IVoteRecord.sol";
import "../Interface/ISystemStatus.sol";


contract Token is OwnableUpgradeable, CacheResolver, ExternStateToken {
    
    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_VOTERECORD = "VoteRecord";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";



    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = CONTRACT_VOTERECORD;
        addresses[1] = CONTRACT_SYSTEMSTATUS;
        return addresses;
    }



    function voteRecord() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }


    /* ========== ERC20 token function ========== */

    /*
     * @description: Replace Constructor function due to Transparent Proxy module.
     * @dev: The initialize function will be called as a calldata while proxy contract deployment.
     * @param {account} accept the initial supplyment of token and be set as a minter to have the authority to mint new supplyment.
     * @param {_totalSupply} the initial supplyment
     */ 
    function token_initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _tokenState,
        address _resolver
        )
        public initializer 
    {
        _externStateTokenInit(
            _name,
            _symbol,
            _owner,
            _tokenState
        );

        _cacheInit(_resolver);

        __Ownable_init();
        minter = _owner;
        emit MinterChanged(address(0), minter);
    }


    /** ========== public mutative functions ========== */

    function transfer(address recipient, uint256 amount) public systemActive returns (bool)  {
        _transfer(_msgSender(), recipient, amount);
        voteRecord().moveDelegates(_msgSender(), recipient, amount);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public systemActive returns (bool)  {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = tokenState.allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        tokenState.setAllowance(sender,recipient,currentAllowance - amount);

        voteRecord().moveDelegates(_msgSender(), recipient, amount);
        
        return true;
    }


    function mint(address to, uint256 value) public systemActive mintfunctionActive {
        _mint(to, value);
    }


    
    function burn(address from, uint256 value) public systemActive burnfunctionActive {
        _burn(from, value);
        voteRecord().moveDelegates(from, address(0), value);
        
    }


    /** ========== modifier ========== */

    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }

    function _mintfunctionActive() private view {
        bytes32 functionname = "tokenmint";
        bytes32 section_system = "System";
        systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier mintfunctionActive() {
        _mintfunctionActive();
        _;
    }

    function _burnfunctionActive() private view {
        bytes32 functionname = "tokenburn";
        bytes32 section_system = "System";
        systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier burnfunctionActive() {
        _burnfunctionActive();
        _;
    }

    /** ========== event ========== */

}
