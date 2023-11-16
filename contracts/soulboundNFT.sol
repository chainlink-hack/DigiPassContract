// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract SoulBoundNFT is ERC721, Ownable {
    /** 
    *@dev Counter for assigning unique token IDs
    */
    uint256 private tokenIdCounter;
    /** 
    *@dev Initial owner address
    */
    address immutable initialOwner;
    /**
    * @dev BaseURI for NFT Metadata
    */
    string private baseURI;

    /**
    * @dev Mapping to store the soul-bound status of each token
    */ 
    mapping(uint256 => address) private soulBoundTokens;

    /**
    * @dev Event to be emitted when a token is soul-bound
    */ 
    event SoulBound(uint256 indexed tokenId, address owner);

    /**
    *@dev  Event to be emitted when a token is unsoul-bound
    */
    event SoulUnbound(uint256 indexed tokenId);

    /**
    *@dev  Constructor to initialize the contract with owner address,organization, baseuri and symbol
    */
    constructor(address _owner,string memory org,string memory url,string memory sym) ERC721(org, sym) Ownable(initialOwner) {
        initialOwner = _owner;
        baseURI = url;
    }
     function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
    *@dev  Mint a new soul-bound token and assign it to the specified owner
    */
    function mintSoulBound(address to) external onlyOwner {
        _mint(to, tokenIdCounter);
        soulBoundTokens[tokenIdCounter] = to;
        emit SoulBound(tokenIdCounter, to);
        tokenIdCounter++;
    }

    /**
    *@dev Check if a token is soul-bound to a specific owner
    */ 
    function isSoulBound(uint256 tokenId, address owner) external view returns (bool) {
        return soulBoundTokens[tokenId] == owner;
    }

    /**
    *@dev Unbind a soul-bound token
    */ 
    function unbindSoul(uint256 tokenId) external onlyOwner {
        require(ownerOf(tokenId) != address(0), "TOKEN_DOES'T_EXIST"); // Use _exists here
        address owner = ownerOf(tokenId);
        require(soulBoundTokens[tokenId] == owner, "TOKEN_NOT_BOUND_TO_CALLER");

        // Unbind the soul by setting the soulBoundTokens mapping to the zero address
        soulBoundTokens[tokenId] = address(0);

        emit SoulUnbound(tokenId);
    }

     /**
     *@dev  Override the _beforeTokenTransfer function to enforce soul-binding rules
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721URIStorage) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Check if the token is soul-bound before transfer
        require(soulBoundTokens[tokenId] != from, "TOKEN_BOUND_TO_SELLER");
    }
}
