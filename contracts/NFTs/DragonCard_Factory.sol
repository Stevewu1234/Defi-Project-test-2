// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./DragonCard.sol";

contract DragonCard_Factory is Ownable{

    struct belong {
        address generator_,
        bytes32 category_
    }

    address private generator;
    mapping (address => belong) public belongto;
    mapping (bytes32 => address[]) private categories; 


    bytes32 private constant AVATAR = keccak256("avatar");


    constructor(
        address _generator
    ) {
        generator = _generator;
        emit changegenerator(generator);
    }



    /** =================== external mutative function onlyGenerator =================== */
    function create(
        string memory _name,
        string memory _symbol,
        string memory _baseuri,
        bytes32 _category
    ) external onlyGenerator returns (address) {
        DragonCard DragonCardAddress = new DragonCard(_name,_symbol,_baseuri);
        belongto[address(DragonCardAddress)].generator_ = _msgSender();
        belongto[address(DragonCardAddress)].category_ = _category;
        categories[_category].push(DragonCardAddress);

        emit created(DragonCardAddress, _msgSender(), _category);
        return DragonCardAddress;
    }

    /** =================== external mutative function onlyGenerator =================== */

    function setNewGenerator(address newgenerator) external onlyOwner {
        require(newgenerator != address(0), "generator must not be null");
        
        generator = newgenerator;
        
        emit changegenerator(generator);
    }

    /** =================== external view function =================== */

    function showDetails(address tokenAddress) external view returns (address, bytes32) {
        address _generator = belongto[tokenAddress].generator_;
        bytes32 _category = belongto[tokenAddress].category_;
        return (_generator, _category);
    }

    function numOfCategories(bytes32[] _categories) external view returns (uint256) {
        uint totalamount = 0;
        for(uint i = 0; i < _categories[].length; i++) {
            totalamount += categories[_categories[i]].length;
        }

        return totalamount;
    }

    function isExisted(address tokenAddress) external view returns (bool) {
        require(belongto[tokenAddress].generator_ != address(0) && belongto[tokenAddress].category_ != bytes32(0), "the tokenaddress is not existed");
        return true;
    }


    /** =================== modifier =================== */

    modifier onlyGenerator() {
        require(generator == _msgSender());
        _;
    }


    /** =================== event =================== */
    event created(address indexed newTokenContract, address indexed generator, bytes32 indexed category);
    event changegenerator(address indexed newgenerator);
}