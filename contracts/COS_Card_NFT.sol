// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "./COS_Util.sol";

contract ConquestOfSolCard is
    ERC721,
    Ownable,
    ERC721Enumerable,
    ERC721Pausable,
    AccessControlEnumerable
{
    using Counters for Counters.Counter;

    string dynamicBaseURI;
    mapping(uint256 => Card) public cards;
    mapping(address => uint256[]) private _ownedTokens;

    struct Card {
        string cardId;
        string uri;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    Counters.Counter private _tokenIds;

    mapping(uint256 => string) private _tokenURIs;

    event LockCard(
        address indexed holder,
        string cardId,
        string steemAddr,
        uint256 indexed _TokenId
    );
    event MintCard(
        address indexed holder,
        string cardId,
        uint256 indexed tokenId
    );

    /**
     * @dev Make sure to pass trailing seperator on url
     * - Ex: ipfs:// or https://ipfs.io/ipfs/ or https://gateway.pinata.cloud/ipfs/
     */
    constructor(string memory _baseTokenURI)
        ERC721("Conquest of Sol Card", "CSOLCARD")
    {
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

    function cardIdForTokenId(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return cards[_tokenId].cardId;
    }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function tokensOfHolder(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 length = ERC721.balanceOf(owner);
        require(length > 0, "ERC721TokensOfOwner: caller balance is zero");

        uint256[] memory _tokens = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner,i);
        }
        return _tokens;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory _path = ConquestOfSolUtil.strConcat(baseTokenURI(), cards[_tokenId].uri);
        _path = ConquestOfSolUtil.strConcat(_path, "/",cards[_tokenId].cardId,".json");
        return _path;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() internal view returns (uint256) {
        return _tokenIds.current() + 1;
    }

    /**
     * @return unint256 of the token ID
     */
    function mint(address recipient) private returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        return newItemId;
    }

    /**
     * @dev instead of the standard mint we use mint Card
     *
     * Requirements:
     * - Must supply the Card Id and URI tag to append to baseTokenURI
     */
    function mintCard(
        address _recipient,
        string memory _cardId,
        string memory _uriId
    ) public returns (uint256) {
        require(!paused(), "ERC721Pausable: no token minting while paused");
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721: minter only");

        uint256 newTokenId = _getNextTokenId();

        cards[newTokenId].cardId = _cardId;
        cards[newTokenId].uri = _uriId;

        uint256 newItemId = mint(_recipient);
        require(_getNextTokenId() == newTokenId + 1, "Mint Card: Safety Check");

        emit MintCard(_recipient, _cardId, newTokenId);
        return newItemId;
    }

    /**
     * @dev Give the card back to the contract
     * - used in web transactions
     */
    function lockCard(uint256 _TokenId, string memory _steemAddr) public {
        require(
            ownerOf(_TokenId) == _msgSender(),
            "ERC721LockCard: caller is not the owner"
        );

        string memory cardId = cardIdForTokenId(_TokenId);
        transferFrom(msg.sender, address(this), _TokenId);

        emit LockCard(msg.sender, cardId, _steemAddr, _TokenId);
    }

    function unlockCard(uint256 _TokenId, address _newHolder)
        public
        isLockedCard(_TokenId)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721: minter only");

        transferFrom(address(this), _newHolder, _TokenId);
    }

    modifier isLockedCard(uint256 _TokenId) {
        require(ownerOf(_TokenId) == address(this), "ERC721Card: Not Locked");
        _;
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
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to pause"
        );
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
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to unpause"
        );
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
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function totalMint() public view returns (uint256) {
        return _tokenIds.current();
    }

}
