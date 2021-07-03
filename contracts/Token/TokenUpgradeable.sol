// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "../Tools/CacheResolverUpgradeable.sol";
import "./ExternStateToken.sol";

// Internal references
import "../Interface/IVoteRecord.sol";
import "../Interface/ISystemStatus.sol";
import "../Interface/IPortal.sol";


contract TokenUpgradeable is OwnableUpgradeable, CacheResolverUpgradeable, ExternStateToken {
    
    uint private startTime;

    uint private mintableTime;

    /* ========== Address Resolver configuration ==========*/
    bytes32 private constant CONTRACT_VOTERECORD = "VoteRecord";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_PORTAL = "Portal";

    function resolverAddressesRequired() public view override returns (bytes32[] memory ) {
        bytes32[] memory existingAddresses = ExternStateToken.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](3);
        newAddresses[0] = CONTRACT_VOTERECORD;
        newAddresses[1] = CONTRACT_SYSTEMSTATUS;
        newAddresses[2] = CONTRACT_PORTAL;
        return combineArrays(existingAddresses, newAddresses);
    }

    function voteRecord() internal view returns (IVoteRecord) {
        return IVoteRecord(requireAndGetAddress(CONTRACT_VOTERECORD));
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function portal() internal view returns (IPortal) {
        return IPortal(requireAndGetAddress(CONTRACT_PORTAL));
    }


    /* ========== ERC20 token function ========== */

    /*
     * @description: Replace Constructor function due to Transparent Proxy module.
     * @dev: The initialize function will be called as a calldata while proxy contract deployment.
     * @param {_name} token name
     * @param {_symbol} token symbol
     * @param {_owner} owner of initial supplyment
     * @param {_tokenState} token state contract which will storage the status of token ownership
     * @param {_resolver} tool contract resolver will storage all system contracts which will be interacted by other system contracts
     * @param {_totalSupply} the initial supplyment
     */ 
    function token_initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _resolver,
        uint256 _totalSupply
        )
        public initializer 
    {
        _externStateTokenInit(
            _name,
            _symbol,
            _owner
        );

        // initialize resolver contract
        _cacheInit(_resolver);

        // initialize the owner of token contract
        __Ownable_init();

        // set the first minter
        minter = _owner;

        // issue initial supply
        _mint(_owner, _totalSupply);

        // record initial mint time
        startTime = block.timestamp;
        mintableTime = startTime + 5 * 365 days;

        emit MinterChanged(address(0), minter);
    }


    /** ========== public mutative functions ========== */

    /*
     * @description: call internal function _transfer() to implement transfer. 
     * @dev: beforeTransfer() function has been replaced with _canTransfer() function 
     * transferring amount must higher than transferable amount. And while transfer function called, 
     * voteRecord() will be called to update vote State even though _msgSender() is a contract.
     * @param {recipient} receive transferred 'amount'
     * @param {amount} transferring token amount
     * @return Returns a boolean value indicating whether the operation succeeded.
     *
     * emit Transfer() event
     * emit DelegateVotesChanged() event
     */ 
    function transfer(address recipient, uint256 amount) public systemActive returns (bool)  {
        _canTransfer(_msgSender(), amount);
        require(_transfer(_msgSender(), recipient, amount), "fail to transfer");
        voteRecord().moveDelegates(_msgSender(), recipient, amount);

        return true;
    }


    /*
     * @description: call internal function _transfer() to implement transferFrom. 
     * @dev: recipient have allownance to receive transferring amoutn.
     * beforeTransfer() function has been replaced with _canTransfer() function 
     * transferring amount must higher than transferable amount. And while transfer function called, 
     * voteRecord() will be called to update vote State even though _msgSender() is a contract.
     * @param {sender} sender must call appprove() before transferFrom()
     * @param {recipient} receive transferred 'amount'
     * @param {amount} transferring token amount
     * @return Returns a boolean value indicating whether the operation succeeded.
     *
     * emit Transfer() event
     * emit DelegateVotesChanged() event
     */ 
    function transferFrom(address sender, address recipient, uint256 amount) public systemActive returns (bool)  {
        _canTransfer(sender, amount);
        require(_transfer(recipient, recipient, amount), "fail to transfer");

        uint256 currentAllowance = allowance(sender, recipient);
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        setAllowance(sender,recipient,currentAllowance - amount);

        voteRecord().moveDelegates(sender, recipient, amount);
        
        return true;
    }

    /*
     * @description: excluding initial supply minting, mintable time is limited by timelock.
     * mintable amount is also limited per year.
     * @dev only minter can call _mint() function.
     * @param {sender} 'to' will receive new supply.
     * @param {value} must not excceed limited amount
     *
     * emit Minted() event
     */ 
    function mint(address to, uint256 value) public systemActive mintfunctionActive {

        require(block.timestamp >= mintableTime, "Sorry, it is not the time of minting new supply");
        require(value <= _mintableAmount(), "Sorry, minting value has excceeded limited amount");

        mintableTime += 365 days;
        _mint(to, value);
    }

    /*
     * @description: token owner could choose to burn their token. 
     * But generally, burn() will be called by burn contract.
     * @dev token owners have the rights to call burn function, but will still be limited by _canTransfer().
     * @param {from} 'from' token owners.
     * @param {value} burning amount.
     *
     * emit Minted() event
     */ 
    function burn(address from, uint256 value) public systemActive burnfunctionActive onlyOwner {
        _canTransfer(from, value);
        _burn(from, value);
        voteRecord().moveDelegates(from, address(0), value);
        
    }

    /** ========== internal view function ========== */

    /*
     * @description: check Portal contract that whether sender have transferable amount or not. 
     * @param {sender} 'sender' token owners.
     * @param {value} operating amount.
     *
     * emit Minted() event
     */ 
    function _canTransfer(address sender, uint256 value) internal view returns (bool) {
        uint256 transferableAmount = portal().getTransferableAmount(sender);
        require(value <= transferableAmount, "can not transfer entered or escrowed");
        return true;
    }

    function _mintableAmount() internal view returns (uint mintableAmount) {
        return mintableAmount = totalSupply * 200000000000000000;
    }


    /** ========== modifier ========== */

    modifier systemActive() {
        systemStatus().requireSystemActive();
        _;
    }

    function _mintfunctionActive() private view returns (bool) {
        bytes32 functionname = "tokenmint";
        bytes32 section_system = "System";
        return systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier mintfunctionActive() {
        require(_mintfunctionActive(), "mint function has been blocked");
        _;
    }

    function _burnfunctionActive() private view returns (bool) {
        bytes32 functionname = "tokenburn";
        bytes32 section_system = "System";
        return systemStatus().requireFunctionActive(functionname,section_system);
    }

    modifier burnfunctionActive() {
        require(_burnfunctionActive(), "burn function has been blocked");
        _;
    }


}