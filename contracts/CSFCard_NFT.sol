// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CSPFORCE is 
  ERC721, 
  Ownable, 
  ERC721Enumerable, 
  ERC721Pausable, 
  AccessControlEnumerable
{
  using Counters for Counters.Counter;
  using Strings for uint256;
  
  string dynamicBaseURI;
  mapping(uint256 => Card) public cards;
  mapping(string => uint256) public ethIds;
  mapping(address => uint256[]) private _ownedTokens;
  
      struct Card {
        string cardId;
        string uri;
    }
    
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  
  Counters.Counter private _tokenIds;
  
  mapping (uint256 => string) private _tokenURIs;
  
  event MintCard(address indexed holder, string cardId, uint256 indexed ethId);
  
   constructor(string memory _baseTokenURI) ERC721("Crypto Space Force", "CSFCARD") {
      dynamicBaseURI = _baseTokenURI;
      
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(PAUSER_ROLE, _msgSender());
   }

    function baseTokenURI() public view returns (string memory) {
        return dynamicBaseURI;
    }

    function setDynamicBaseURI(string memory _newBaseURI) public onlyOwner {
        dynamicBaseURI = _newBaseURI;
    }

    function cardIdForTokenId(uint256 _tokenId) public view returns (string memory) {
        return cards[_tokenId].cardId;
    }
    
   function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    
    function tokensOfHolder(address holder) public view returns (uint256[] memory) {
        return _tokensOfOwner(holder);
    }

/**     
  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
  {
    _tokenURIs[tokenId] = _tokenURI;
  }*/
  
  /**
  function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory _tokenURI = _tokenURIs[tokenId];
    return _tokenURI;
  } */
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return Strings.strConcat(
            baseTokenURI(),
            cards[_tokenId].cardId
        );
    }
 
  function mintTo(address _to) internal {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _mint(_to, newTokenId);
  }
  
  function mintCard(address _recipient, string memory _cardId, string memory _uriId) public {
    // require(0 == ethIds[_cardId], "Card Exists");
    require(!paused(), "ERC721Pausable: no token minting while paused");
    require(hasRole(MINTER_ROLE, _msgSender()), "ERC721: minter only");
    
    uint256 newEthId = _getNextTokenId();

    cards[newEthId].cardId = _cardId;
    cards[newEthId].uri = _uriId;

    mintTo(_recipient);
    require(_getNextTokenId() == newEthId + 1, "Mint Card: Safety Check");

    emit MintCard(_recipient, _cardId, newEthId);
  }
  
      /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
  
  /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   * - for OpenSea
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    } 
    
}