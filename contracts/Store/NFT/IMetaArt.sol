interface IMetaArt {
    
    function getTokenIdCreator(uint256 tokenId) external view returns (address payable);

    function getCreatorAssistant(uint256 tokenId) external view returns (address payable);

    function getTokenOwnerShip(uint tokenId) external view returns (address payable creator, address payable assistant)

    function getPaymentAddress(uint256 tokenId) external view returns (address payable paymentAddress);

    function isCreatorEqualOwner(uint256 tokenId) external view returns (bool);

    function hasCreatorAssistant(uint256 tokenId) external view returns (bool);
}