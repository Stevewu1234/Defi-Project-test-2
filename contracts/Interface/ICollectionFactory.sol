interface ICollectionFactory {

     function create(
        string memory _name,
        string memory _symbol,
        string memory _baseurl,
        address owner
    ) external returns (address);

    function getlength() external view returns (uint);

    function getcollection(address owner) external returns (address);
}