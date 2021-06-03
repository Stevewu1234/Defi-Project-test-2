// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Interface/IToken.sol";
import "./Interface/IDCT.sol";



contract MerkleDistributor {
    using SafeERC20 for IERC20;


    address public rewardtoken;       // new token.
    bytes32 public merkleRoot;  // generate off-chain.
    address public holdertoken;           //testtoken address
    
    // Claimed new token by the way of land holder
    mapping(address => uint) public ClaimedToken;             
    
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address _rewardtoken, bytes32 _merkleRoot, address _holdertoken) {
        rewardtoken = _rewardtoken;
        merkleRoot = _merkleRoot; 
        holdertoken = _holdertoken;
    }

    /** first Merkle Distribute */
    function isClaimed(uint256 index) public view  returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 _amount, bytes32[] calldata merkleProof) external  {
        require(!isClaimed(index), "claim: Drop already claimed.");
        require(ClaimedToken[account] == 0, "Sorry, you have claimed your token");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, _amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'claim: Invalid proof.');

        (uint _tokenamount,) = IDCT(holdertoken).vaults(account);
        
        // Mark it claimed and send the token.
        _setClaimed(index);
        uint amount = (_amount + _tokenamount)*10**18;
        ClaimedToken[account] = amount;
        
        // claim token
        IToken(rewardtoken).transfer(account, amount);        // transfer new token from contract.
        emit Claimed(index, account, amount);
    }

    function holdertokenvaults(address account) public view  returns (uint, uint) {
        ( uint tokenamount, uint acquiretime) = IDCT(holdertoken).vaults(account);
        return (tokenamount, acquiretime);
    }

    /** Second claim without Merkle Distribution */
    function claimoflandholder(address _holder)  external {
        
        require(ClaimedToken[_holder] == 0, "Sorry, you have claimed your token");
        
        (uint _tokenamount, uint _acquiredTime) = IDCT(holdertoken).vaults(_holder);
        require(_acquiredTime == 0 && _tokenamount > 0, "sorry, you have claimed token from holdertoken contract, or maybe you are not the land holder");
        
        uint availableToken = _tokenamount*10**18;
        ClaimedToken[_holder] = availableToken;
        IToken(rewardtoken).transfer(_holder, availableToken);     // transfer new token from contract.
        emit Claimoflandholder(_holder, availableToken);
    }

    /** ========== event ========== */
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 indexed index, address indexed account, uint256 indexed amount);
    event Claimoflandholder(address indexed account, uint indexed availableToken);
}