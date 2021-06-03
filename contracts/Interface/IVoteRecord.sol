interface IVoteRecord {

    /** ========== view functions ========== */

    function getPriorVotes(address account, uint blockNumber) external view returns (uint);

    function getCurrentVotes(address account) external view returns (uint);

    /** ========== mutative functions ========== */

    function moveDelegates(address srcRep, address dstRep, uint amount) external;

    function delegate(address delegatee) external;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) external;
}
