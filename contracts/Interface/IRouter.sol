interface IRouter {


    // external mutative functions
    // AirDrop acquirement
    function claim(uint256 index, address account, uint256 _amount, bytes32[] calldata merkleProof) external;

    function claimoflandholder(address _holder) external;

    // Liquidity Staking
    function stake(uint256 amount) external; 

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    // Come and join in the game;
    function comeforfun(address from, uint amount) external;




    // public viewable data
}