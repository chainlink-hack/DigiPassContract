// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SoulBoundNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable  {
    /** 
    *@dev Counter for assigning unique token IDs
    */
    uint256 private _nextTokenId;
    
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
    constructor(address initialOwner,string memory org,string memory url,string memory sym) ERC721(org, sym) Ownable(initialOwner) {
        baseURI = url;
    }
     function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
    *@dev  Mint a new soul-bound token and assign it to the specified owner
    */
    function mintSoulBound(address to,string memory uri) external onlyOwner {
        _safeMint(to, _nextTokenId);
        _setTokenURI(_nextTokenId, uri);
        soulBoundTokens[_nextTokenId] = to;
         _nextTokenId++;
        require(ERC721(this).balanceOf(to) <=1,"ALREADY_SOULBOUNDED");
        emit SoulBound(_nextTokenId, to);
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
     *@dev  Override the _update function to enforce soul-binding rules
     */

     event test(address to,address sender);

    function _update(address to, uint256 tokenId,address auth) internal virtual override(ERC721,ERC721Enumerable) returns (address) {
        address result = super._update(to, tokenId,auth);
        // Check if the token is soul-bound before transfer
        require(soulBoundTokens[tokenId] == address(0) && soulBoundTokens[tokenId] !=to &&soulBoundTokens[tokenId] !=msg.sender  , "TOKEN_BOUND_TO_SELLER"); 
        emit test(to,msg.sender);
        return result;
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    
}


