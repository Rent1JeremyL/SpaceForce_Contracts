// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IERC20Burnable.sol";
import "./IERC721CSol.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./COS_Util.sol";

contract ConquestOfSolNFTManager is Ownable, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    IERC20Burnable public token;

    uint256 private nonce = 0;
    uint256 public TOKENS_PER_NFT = 4000000000000000000;
    bool public FREE_NFT = false;

    IERC721CSol public nft;

    struct Card {
        uint256 id;
        string cardId;
        string jsonKey;
    }
    
    mapping(uint256 => Card) public _cardDB;
    Counters.Counter public _cardIds;

    event MintedCard(address indexed _address, string _cardId, uint256 _cost);

    constructor(IERC721CSol _nft, address _token) { 
        nft = _nft;
        token = IERC20Burnable(_token);
    }

    function MintRandomCard() public returns(string memory) {
        require(!nft.paused(), "NFT Contract paused.");
        nonce++;
        address buyer = msg.sender;
        uint256 max = _cardIds.current();

        uint256 randNumber = ConquestOfSolUtil.randomNumber(max + 1, nonce);
          
        string memory nftId = _cardDB[randNumber].cardId;
        nft.mintCard(buyer, nftId, "_nft");
        
        if(!FREE_NFT) {
            token.transferFrom(buyer, address(this), TOKENS_PER_NFT);
            token.burn(TOKENS_PER_NFT);
        }

        emit MintedCard(buyer, nftId, TOKENS_PER_NFT);
        return nftId;
    }
    
    function initShipLoop(uint _start, uint _end) public onlyOwner {
        string memory ship = "";
        for (uint i = _start; i <= _end; i++) {
            ship = ConquestOfSolUtil.strConcat("SH", Strings.toString(i));
            AddCard(ship,ship);
        } 
    }

    function initABil() public onlyOwner {
        // Add ability cards  
        string memory abil = "";
        for (uint i = 1; i <= 11; i++) {
            abil = ConquestOfSolUtil.strConcat("AB", Strings.toString(i));
            AddCard(abil,abil);
        }  
    }

    function loadShips1() public onlyOwner {
        // Add ship cards 1/2/3
        initShipLoop(1, 10);
        initShipLoop(11, 21);
    }

    function loadShips2() public onlyOwner {
        // Add ship cards 1/2/3
        initShipLoop(22, 32);
        initShipLoop(33, 42);
    }

    function loadShips3() public onlyOwner {
        // Add ship cards 4/5
        initShipLoop(43, 56);
    }

    function AddCard(string memory _id, string memory _jsonKey) public onlyOwner {
        require(ConquestOfSolUtil.isNullStr(_id) == false, "NFT Manager: Ids cant be blank");
        require(ConquestOfSolUtil.isNullStr(_jsonKey) == false, "NFT Manager: JSON key cant be blank");

        _cardIds.increment();
        uint256 keyId = _cardIds.current();

        _cardDB[keyId].id = keyId;
        _cardDB[keyId].cardId = _id;
        _cardDB[keyId].jsonKey = _jsonKey;
    }

    function EditCard(uint256 _id, string memory _jsonKey) public onlyOwner {
        require(ConquestOfSolUtil.isNullStr(_jsonKey) == false, "NFT Manager: JSON key cant be blank");

        _cardDB[_id].jsonKey = _jsonKey;
    }
    
    function GetCardJSONKey(uint256 _id) public view returns(string memory) {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        return _cardDB[_id].jsonKey;
    }
    
    function withdrawFunds() external onlyOwner {
        require(token.balanceOf(address(this)) > 0,"NFTManager: No Balance to withdraw");
        token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));
    }

    function setTokenPerNFT(uint256 _amount) public onlyOwner {
        require(_amount > 100,"NFT Manager: can't be 0");
        TOKENS_PER_NFT = _amount;
    }

    function toggleFreeNFTS(bool _on) public onlyOwner {
        FREE_NFT = _on;
    }
}