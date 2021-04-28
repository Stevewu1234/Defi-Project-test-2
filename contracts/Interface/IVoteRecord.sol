interface IVoteRecord {

    /** ========== view functions ========== */

    function getPriorVotes(address account, uint blockNumber) public view returns (uint);

    function getCurrentVotes(address account) external view returns (uint);

    /** ========== mutative functions ========== */

    function moveDelegates(address srcRep, address dstRep, uint amount);

    function delegate(address delegatee) public;

    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public;
}
