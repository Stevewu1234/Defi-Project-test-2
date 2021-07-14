// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contract-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contract-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contract-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

abstract contract MetaArtMetaDataUpgradeable is ContextUpgradeable, ERC721Upgradeable, ERC721URIStorageUpgradeable {

    mapping (address => string) private creatorToIPFSPath;

    function metadata_init() internal initializer {
        __Context_init_unchained();
    }

    /** ========== public view functions ========== */
    function getCreatorUniqueIPFSHashAddress(string memory _path) public view returns (bool) {
        return creatorToIPFSPath[_msgSender()] == _path;
    }


    /** ========== internal mutative functions ========== */

    function _setTokenIPFSPath(uint256 tokenId, string memory _path) internal {
        require(bytes(_path).length >= 46, "Invalid IPFS path");
        require(getCreatorUniqueIPFSHashAddress(_path), "NFT has been minted");

        address creator = _msgSender();
        creatorToIPFSPath[creator] = _path;

        _setTokenURI(tokenId, _path);

        emit IPFSPathset(creator);
    }

    /** ========== event ========== */

    event IPFSPathset(address indexed creator);

}