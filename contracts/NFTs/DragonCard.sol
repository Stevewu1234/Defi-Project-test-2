// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract DragonCard is ERC721PresetMinterPauserAutoId {
    

    constructor (
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    )
    ERC721PresetMinterPauserAutoId(name_, symbol_,baseURI_) {}


    /** ========== external mutative function ========== */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
        _setTokenURI(tokenId,_tokenURI);
    }
    

    /** ========== external mutative function onlyOwner ========== */

 
}