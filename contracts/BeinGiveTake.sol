// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract BeinGiveTake is Context, AccessControlEnumerable {
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor() {
        address adminAddress = msg.sender;

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(MINT_ROLE, adminAddress);

        _name = "Bein Give and Take";
        _symbol = "BGT";
        _decimal = 18;
    }

    mapping (address => uint256) private _balances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimal;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function mintTo(address account, uint256 amount) public {
        require(hasRole(MINT_ROLE, msg.sender), "Must have MINT_ROLE");

        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimal;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
}
