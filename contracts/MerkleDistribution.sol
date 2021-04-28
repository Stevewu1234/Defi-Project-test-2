pragma solidity ^0.6.0;


import "../../node_modules/@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interface/IMerkleDistributor.sol";
import "../interface/IDCT.sol";



contract MerkleDistributor is IMerkleDistributor{
    using SafeERC20 for uint;


    address public immutable override token;       // new token.
    bytes32 public immutable override merkleRoot;  // generate off-chain.
    address public holdertoken;           //testtoken address
    
    // Claimed new token by the way of land holder
    mapping(address => uint) public ClaimedToken;             
    
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(address _token, bytes32 _merkleRoot, address _holdertoken) public {
        token = _token;
        merkleRoot = _merkleRoot; 
        holdertoken = _holdertoken;
    }

    /** first Merkle Distribute */
    function isClaimed(uint256 index) public view override returns (bool) {
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

    function claim(uint256 index, address account, uint256 _amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
        require(msg.sender == account, "Sorry, you cannot acquire the token which don't belong to you");
        require(ClaimedToken[account] == 0, "Sorry, you have claimed your token");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, _amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        (uint _tokenamount,) = IDCT(holdertoken).vaults(account);
        
        // Mark it claimed and send the token.
        _setClaimed(index);
        ClaimedToken[account] = _tokenamount;
        
        // claim token
        uint amount = SafeMath.add(_amount,_tokenamount)*10**18;
        require(IERC20(token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');        // transfer new token from contract.
        emit Claimed(index, account, amount);
    }

    /** Second claim without Merkle Distribution */
    function claimoflandholder(address _holder) external {
        
        require(msg.sender == _holder, "Sorry, you cannot acquire the token which don't belong to you");
        require(ClaimedToken[_holder] == 0, "Sorry, you have claimed your token");
        
        (uint _tokenamount, uint _acquiredTime) = IDCT(holdertoken).vaults(_holder);
        require(_acquiredTime == 0 && _tokenamount > 0, "sorry, you have claimed token from holdertoken contract, or maybe you are not the land holder");
        
        uint availableToken = _tokenamount*10**18;
        ClaimedToken[_holder] = availableToken;
        require(IERC20(token).transfer(_holder, availableToken), 'claimoflandholder: Transfer failed.');     // transfer new token from contract.
        emit Claimoflandholder(_holder, availableToken);
    }
}