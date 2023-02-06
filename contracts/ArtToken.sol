// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Implement onlyOwner modifier to mint and burn

contract ArtToken is ERC20, Pausable, Ownable {
    mapping(address => uint256) private _balances;

    
    uint256 private _totalSupply = 1000000000000000000000000;
    uint256 private _decimals = 18;

    string private _name;
    string private _symbol;

    bool private _paused;

    /**
     * @dev Sets the values for {name} and {symbol}. Defines msg.sender as the owner and mints total supply to its address
     *
     * All of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() Ownable() ERC20("Art Token", "ART") {
        _mint(msg.sender, _totalSupply);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal override onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal override onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Mints the wanted amount to selected address.
     *
     * Requirements:
     *
     * - The caller must be the contract ow2ner.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burns the selected amount from callers' address.
     *
     * Requirements:
     *
     * - The caller must be the contract owner.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }   


    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
}