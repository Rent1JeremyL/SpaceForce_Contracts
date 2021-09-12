// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./CSFCard_NFT.sol";

contract GameManager is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    uint256 private nonce = 0;
    CryptoSpaceForceCard public nft;
    Counters.Counter private _cardIds;
    
    struct Card {
        uint256 cardId;
        string jsonKey;
        string uri;
    }
    
    mapping(uint256 => Card) private _cardDB;
    
    constructor(CryptoSpaceForceCard _nft) public { 
        nft = _nft;
        init();
    }
    
    function randomNumber(uint256 mod) public view returns(uint) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)));
        rand = SafeMath.mod(rand, mod);
        return rand;
    }

    function GenerateRandomCard() public returns(uint256) {
        nonce++;

        uint256 owned = nft.balanceOf(msg.sender);
        uint256 randNumber;
        uint256 max = _cardIds.current();
        
        if(owned >= 50){
            randNumber = randomNumber(max + 1);
        }else if(owned >= 20 && owned < 50){
            randNumber = randomNumber(35);
        }else{
            randNumber = randomNumber(24);
        }

                
        return randNumber;
    }
    
    function init() private {
        AddCard(1,"SH_F1_1","QmZtqQQhishHEKe2ynp2c5gBGwCvPNhgGBMPLGJwb9mWjG");
        AddCard(2,"SH_F1_2","QmZtqQQhishHEKe2ynp2c5gBGwCvPNhgGBMPLGJwb9mWjG");
    }
    
    function AddCard(uint256 _id, string memory _jsonKey, string memory _uri) public onlyOwner {
        require(_id > 0, "NFT Manager: Ids start at 1");
        uint256 i = _id - 1;
        
        _cardDB[i].cardId = _id;
        _cardDB[i].jsonKey = _jsonKey;
        _cardDB[i].uri = _uri;
        
        _cardIds.increment();
    }
    
    function GetCardJSONKey(uint256 _id) public view returns(string memory) {
        require(_id > 0, "NFT Manager: Ids start at 1");
        uint256 i = _id - 1;
        
        return _cardDB[i].jsonKey;
    }
    
    function GetCardURI(uint256 _id) public view returns(string memory) {
        require(_id > 0, "NFT Manager: Ids start at 1");
        uint256 i = _id - 1;
        
        return _cardDB[i].uri;
    }
    
}