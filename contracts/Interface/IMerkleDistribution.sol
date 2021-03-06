interface IMerkleDistribution{
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;
    // Claim the given amount of the token to the given address with an available amount from user's former contribution.
    function claimoflandholder(address _holder) external;

    function holdertokenvaults(address account) external view returns (uint, uint);

    function ClaimedToken(address account) external view returns (uint);

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
    
}