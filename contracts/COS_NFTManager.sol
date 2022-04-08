// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./COS_Util.sol";
import "./COS_Card_NFT.sol";

contract GameManager is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 private nonce = 0;
    uint256 public TOKEN_PER_NFT = 400000000000000;
    string constant SHIP = "SH";
    string constant ABILITY = "AB";
    
    ConquestOfSolCard public nft;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    struct Card {
        string cardId;
        string jsonKey;
    }
    
    mapping(uint256 => Card) private _shipDB;
    mapping(uint256 => Card) private _abilDB;
    Counters.Counter private _shipIds;
    Counters.Counter private _abilIds;

    event MintedCard(address indexed _address, string _cardId, uint256 _cost);

    constructor(ConquestOfSolCard _nft, address _token) { 
        nft = _nft;
        token = IERC20(_token);
        init();
    }

    function MintRandomCard() public returns(string memory) {
        require(!nft.paused(), "NFT Contract paused.");
        nonce++;
        address buyer = msg.sender;
        uint256 owned = nft.balanceOf(buyer);
        uint256 randNumber;
        uint256 max = _shipIds.current();
        //token.safeTransferFrom(buyer, BURN_ADDRESS, TOKEN_PER_NFT);

        if(owned >= 9){
            randNumber = ConquestOfSolUtil.randomNumber(max + 1, nonce);
        }else if(owned >= 5 && owned < 9){
            randNumber = ConquestOfSolUtil.randomNumber(35, nonce);
        }else{
            randNumber = ConquestOfSolUtil.randomNumber(24, nonce);
        }
        
        string memory cardID = ConquestOfSolUtil.strConcat(SHIP, Strings.toString(randNumber));
        nft.mintCard(buyer, cardID, "_nft");
        
        emit MintedCard(buyer, cardID, TOKEN_PER_NFT);
        return cardID;
    }
    
    function init() private {
        AddShipCard(1,"SH1");
        AddShipCard(2,"SH2");
    }
    
    function AddShipCard(uint256 _id, string memory _jsonKey) public onlyOwner {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        _shipDB[_id].cardId = ConquestOfSolUtil.strConcat(SHIP, Strings.toString(_id));
        _shipDB[_id].jsonKey = _jsonKey;
        
        _shipIds.increment();
    }

    function AddAbilityCard(uint256 _id, string memory _jsonKey) public onlyOwner {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        _abilDB[_id].cardId = ConquestOfSolUtil.strConcat(ABILITY, Strings.toString(_id));
        _abilDB[_id].jsonKey = _jsonKey;
        
        _abilIds.increment();
    }
    
    function GetCardJSONKey(uint256 _id) public view returns(string memory) {
        require(_id > 0, "NFT Manager: Ids start at 1");
        
        return _shipDB[_id].jsonKey;
    }
    
    function withdrawFunds() external onlyOwner {
        require(token.balanceOf(address(this)) > 0,"NFTManager: No Balance to withdraw");
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function setTokenPerNFT(uint256 _amount) public onlyOwner {
        require(_amount > 500,"NFT Manager: can't be 0");
        TOKEN_PER_NFT = _amount;
    }
}