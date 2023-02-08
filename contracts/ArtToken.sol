// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ArtToken is Pausable, Ownable {
    
    // Mapping for balances
    mapping(address => uint256) private _balances;
    // Mapping for allowances to be used via transferFrom
    mapping(address => mapping(address => uint256)) private _allowances;
    // Global variables
    uint256 internal _totalSupply = 1000000000000000000000000;
    uint256 internal _initialSupply = 10000000000000000000000;
    uint256 internal _currentSupply = 0;
    uint8 internal _decimals = 18;
    string internal _name;
    string internal _symbol;
    // Bool to pause transfers
    bool internal _paused;

    /**
     * @dev Sets the values for {name} and {symbol};
     * Defines msg.sender as the owner;
     * and mints initial supply to its address.
     *
     * All of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() Ownable() {
        _name = "Art Token";
        _symbol = "ARTT";
        mint(msg.sender, _initialSupply);

    }

    /// @notice Defines transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @notice Defines approval event
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /// @notice Returns the name of the token.
    /// @return 
    function name() public view returns (string memory) {
        return _name;
    }


    /// @notice Returns the symbol of the token.
    /// @return _symbol symbol of token
    function symbol() public view returns (string memory) {
        return _symbol;
    }


    /// @notice Returns the number of decimals used to get its user representation.
    /// @return _decimals decimals of the token
    function decimals() public view returns (uint8) {
        return _decimals;
    }


    /// @notice Returns the total supply of tokens
    /// @return totalSupply total supply of tokens
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    /// @notice Returns the current supply of tokens
    /// @return currentSupply current supply of tokens
    function currentSupply() public view returns (uint256) {
        return _currentSupply;
    }


    /// @notice Returns the balance of given address
    /// @param account address whose balance we want to know
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    /// @notice Returns the amount the spender can spend on behalf of owner
    function allowance(address owner, address spender) internal view returns (uint256) {
        return _allowances[owner][spender];
    }


    /// @notice Triggers stopped state.
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }


    /// @notice Returns to normal state.
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }


    /// @notice Informs whether ARTT transfers are paused
    function isPaused() public view returns (bool) {
        return _paused;
    }


    /// @notice Moves tokens from caller to receiver ('to').
    function transfer(address to, uint256 amount) public virtual whenNotPaused returns (bool) {
        uint256 accountBalance = _balances[msg.sender];
        // Checks for sufficient Balance
        require(accountBalance >= amount);
        // Checks 'to' address
        require(to != address(0), "Cannot transfer to zero address");
        unchecked{
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[msg.sender] -= amount;
            _balances[to] += amount;
        }
        // Emits transfer event
        emit Transfer(msg.sender, to, amount);
        return true;
    }


    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        address spender = _msgSender();
        // Reduces amount from allowance
        _allowances[from][spender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }


    function approve(address owner, address spender, uint256 amount) external virtual returns (bool) {
        // Checks addresses
        require(owner == _msgSender(), "Only token owner can set approval");
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        // Sets allowance
        _allowances[owner][spender] = amount;
        // Emits approval event
        emit Approval(owner, spender, amount);
        return true;
    }


    /// @notice Mints the wanted amount to selected address.
    /// @param to address to receive newly minted tokens.
    /// @param amount amaount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        // Checks 'to' address
        require(to != address(0), "ERC20: mint to the zero address");
        // Check whether minted amount exceeds total supply
        require(_currentSupply + amount <= _totalSupply, "Cannot exceed total supply");
        // Increases current supply
        _currentSupply += amount;
        // Overflow not possible: balance + amount is at most total Supply + amount, which is checked above.
        unchecked {
            // Increases balance of 'to' address
            _balances[to] += amount;
        }
        // emits transfer event
        emit Transfer(address(0), to, amount);
    }


    /// @notice Burns the selected amount from callers' address.
    /// @param amount amount of tokens to be burned.
    function burn(uint256 amount) public onlyOwner {
        /// Defines balance of caller account 
        uint256 accountBalance = _balances[msg.sender];
        /// Checks for sufficient balance
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        // Overflow not possible: amount <= accountBalance <= totalSupply.
        unchecked {
            // subtracts amount from account balance
            _balances[msg.sender] = accountBalance - amount;
            // subtracts amount from total supply
            _currentSupply -= amount;
        }
        /// emits transfer event
        emit Transfer(msg.sender, address(0), amount);
    }   
}
