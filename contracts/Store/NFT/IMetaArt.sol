pragma solidity ^0.8.0;


interface IMetaArt {
    
    function getTokenIdCreator(uint256 tokenId) external view returns (address payable);

    function getCreatorAssistant(address creator) external view returns (address payable);

    function getAssistantCreator(address assistant) external view returns (address payable);

    function getPaymentAddress(uint256 tokenId) external view returns (address payable paymentAddress);

    function ownerOf(uint256 tokenId) external view returns (address owner);


    

    function transferFrom(address from, address to, uint256 tokenId) external; 
}
