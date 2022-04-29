// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @custom:security-contact conquestofsol@gmail.com
contract CSOLSHARD is ERC20, ERC20Burnable, Pausable, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
	
	// Max transfer amount rate in basis points. (default is 100=1% of total supply)
	uint16 public maxTransferAmountRate = 100;
	// Min value of the max transfer amount rate. (0.5%)
	uint16 public constant maxTransferMinRate = 50;

	// Addresses that excluded from antiWhale
	mapping(address => bool) private _excludedFromAntiWhale;

    // Is the transfer enabled? (False by default)
    bool public isTransactionEnabled = false;

    // Blacklisted addresses
    mapping(address => bool) private blackList;
	// anti-bot end block
	uint256 public antiBotBlock;
    // The duration that the anti-bot function last: 200 blocks ~  10mins (from launch)
    uint256 public constant ANTI_BOT_TIME = 200;

	// Track minted
	uint256 public totalMinted;

	// Events
	event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
	event MaxTransferAmountRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);

    // Modifiers
	modifier antiWhale(address sender, address recipient, uint256 amount) {
		if (maxTransferAmount() > 0) {
			if (_excludedFromAntiWhale[sender] == false && _excludedFromAntiWhale[recipient] == false) {
				require(amount <= maxTransferAmount(), "TOKEN::antiWhale: Transfer amount exceeds the maxTransferAmount");
			}
		}
		_;
	}

    /**
     * @dev Blocks transaction before launch, so can inject liquidity before launch
     */
    modifier blockTransaction(address sender) { 
        if (isTransactionEnabled == false) { 
            require(hasRole(OWNER_ROLE, sender), "TOKEN::blockTransaction: Transfers can only be done by operator."); 
        }
        _; 
    }

	modifier antiBot(address recipient) {
		if (isTransactionEnabled && block.number <= antiBotBlock) {
			require(balanceOf(recipient) <= maxTransferAmount(), "TOKEN:: antiBot: Suspected bot activity");
		}
        _; 
	}

	/**
	 * @notice Constructs the contract.
	 */
	constructor() ERC20("Conquest of Sol Shard", "CSOLS") {
		
		_excludedFromAntiWhale[msg.sender] = true;
		_excludedFromAntiWhale[address(0)] = true;
		_excludedFromAntiWhale[address(this)] = true;
		
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_setupRole(OWNER_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
	}

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
	/// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
	function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
		_mint(_to, _amount);
		totalMinted += _amount;
	}

	/// @dev overrides transfer function to meet tokenomics of BTN
	function _transfer(address sender, address recipient, uint256 amount) internal virtual override 
										blockTransaction(sender) antiWhale(sender, recipient, amount) antiBot(recipient) {
        require(blackList[sender] == false,"TOKEN::transfer: You're blacklisted");

		super._transfer(sender, recipient, amount);

	}

	/**
	 * @dev Returns the max transfer amount.
	 */
	function maxTransferAmount() public view returns (uint256) {
		return totalSupply().mul(maxTransferAmountRate).div(10000);
	}

	/**
	 * @dev Returns the address is excluded from antiWhale or not.
	 */
	function isExcludedFromAntiWhale(address _account) public view returns (bool) {
		return _excludedFromAntiWhale[_account];
	}

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

	/**
	 * @dev Update the max transfer amount rate.
	 * Can only be called by the current operator.
	 */
	function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyRole(OWNER_ROLE) {
		require(_maxTransferAmountRate <= 10000, "TOKEN::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
		require(_maxTransferAmountRate >= maxTransferMinRate,"TOKEN::updateMaxTransferAmountRate: Max transfer amount rate must be grater than min rate");
		emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
		maxTransferAmountRate = _maxTransferAmountRate;
	}

	/**
	 * @dev Exclude or include an address from antiWhale.
	 * Can only be called by the current operator.
	 */
	function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyRole(OWNER_ROLE) {
		_excludedFromAntiWhale[_account] = _excluded;
	}

    /**
     * @dev Enable transactions.
     * Can only be called once by the current operator.
     */
    function enableTransaction() public onlyRole(OWNER_ROLE) {
		require(isTransactionEnabled == false,"TOKEN::enableTransaction: This meothod can only be called once");
        isTransactionEnabled = true;
		antiBotBlock = block.number.add(ANTI_BOT_TIME);
    }

    /**
     * @dev Exclude or include an address from blackList.
     */
    function addToBlackList(address _account, bool _excluded) public onlyRole(OWNER_ROLE) {
        blackList[_account] = _excluded;
    }

    /**
     * @dev Returns the address is excluded from blackList or not.
     */
    function isBlackListed(address _account) public view returns (bool) {
        return blackList[_account];
    }


	function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
		require(n < 2**32, errorMessage);
		return uint32(n);
	}

	function getChainId() internal view returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}
}