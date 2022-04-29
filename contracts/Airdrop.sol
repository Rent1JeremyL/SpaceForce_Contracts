// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTAirdrop is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public token;

    bool public paused = false;
    bool public finish = false;

    uint256 public startTimeStamp;
    uint256 public presaleDays;
    uint256 public constant DAY = 1 days;
    uint256 public constant TOKENS_PER_WALLET = 400000000000000000000;

    uint256 public airdropTokensSent = 0;

    // Airdropped addresses
    mapping(address => bool) private airdropList;
    
    mapping (address => uint256) public tokenBalances;

    event Airdrop(address indexed _address);
    event IncreasePresaleOneMoreDay();
    event Paused();
    event Started();
    event Finish();

    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (
        address _token,
        uint256 _startTimestamp,
        uint256 _presaleDays
    ) {
        owner = msg.sender;
        token = IERC20(_token);
        startTimeStamp = _startTimestamp;
        presaleDays = _presaleDays;
    }

    function requestAirdrop () public {
        require(!paused, "Airdrop: paused");
        require(block.timestamp >= startTimeStamp, "Airdrop: Airdrop not start yet");
        require(block.timestamp <= startTimeStamp + presaleDays * DAY, "Airdrop: Airdrop has already finished");
        
        address buyer = msg.sender;
        require(hasAirdropTokens(buyer) == false, "Airdrop: One airdrop per wallet");
        uint256 tokensAmount = TOKENS_PER_WALLET;
        uint256 CAP = token.balanceOf(address(this));
        require (airdropTokensSent +  tokensAmount <= CAP, "Airdrop: hardcap reached");

        tokenBalances[buyer] = tokenBalances[buyer].add(tokensAmount);
        airdropTokensSent = airdropTokensSent.add(tokensAmount);

        token.safeTransfer(buyer, tokensAmount);
        airdropList[buyer] = true;
        emit Airdrop(buyer);
    }

    /**
     * @dev Exclude or include an address from Airdropped.
     */
    function addToAirdropList(address _account, bool _hasTokens) public onlyOwner {
        airdropList[_account] = _hasTokens;
    }

    /**
     * @dev Returns the address true if the wallet has already recieved tokens
     */
    function hasAirdropTokens(address _account) public view returns (bool) {
        return airdropList[_account];
    }

    function increaseOneMoreDay() external onlyOwner {
        presaleDays += 1;
        emit IncreasePresaleOneMoreDay();
    }

    function setPause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function setStart() external onlyOwner {
        paused = false;
        emit Started();
    }

    function setFinish() external onlyOwner {
        finish = true;
        emit Finish();
    }

    function withdrawUnsoldToken() external onlyOwner {
        require(finish, "withdrawUnsoldToken: not finish");
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
    }
}