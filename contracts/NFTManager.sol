// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./CSFUtil.sol";
import "./CSFCard_NFT.sol";

contract GameManager is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    uint256 private nonce = 0;
    
    string constant SHIP = "SH";
    string constant ABILITY = "AB";
    
    CryptoSpaceForceCard public nft;

    struct Card {
        string cardId;
        string jsonKey;
    }
    
    mapping(uint256 => Card) private _shipDB;
    mapping(uint256 => Card) private _abilDB;
    Counters.Counter private _shipIds;
    Counters.Counter private _abilIds;
            
    constructor(CryptoSpaceForceCard _nft) public { 
        nft = _nft;
        init();
    }

    function GenerateRandomCard() public returns(uint256) {
        nonce++;

        uint256 owned = nft.balanceOf(msg.sender);
        uint256 randNumber;
        uint256 max = _shipIds.current();
        
        if(owned >= 50){
            randNumber = CSpaceForceUtil.randomNumber(max + 1, nonce);
        }else if(owned >= 20 && owned < 50){
            randNumber = CSpaceForceUtil.randomNumber(35, nonce);
        }else{
            randNumber = CSpaceForceUtil.randomNumber(24, nonce);
        }

                
        return randNumber;
    }
    
    function init() private {
        AddShipCard(1,"QmZtqQQhishHEKe2ynp2c5gBGwCvPNhgGBMPLGJwb9mWjG");
        AddShipCard(2,"QmZtqQQhishHEKe2ynp2c5gBGwCvPNhgGBMPLGJwb9mWjG");
    }
    
    function AddShipCard(uint256 _id, string memory _jsonKey) public onlyOwner {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        _shipDB[_id].cardId = CSpaceForceUtil.strConcat(SHIP, Strings.toString(_id));
        _shipDB[_id].jsonKey = _jsonKey;
        
        _shipIds.increment();
    }

    function AddAbilityCard(uint256 _id, string memory _jsonKey) public onlyOwner {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        _abilDB[_id].cardId = CSpaceForceUtil.strConcat(ABILITY, Strings.toString(_id));
        _abilDB[_id].jsonKey = _jsonKey;
        
        _abilIds.increment();
    }
    
    function GetCardJSONKey(uint256 _id) public view returns(string memory) {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        return _shipDB[_id].jsonKey;
    }
    
    
}