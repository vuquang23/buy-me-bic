// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./BeinGiveTake.sol";

contract BICRight is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant BLACK_LIST_ROLE = keccak256("BLACK_LIST_ROLE");

    bytes32 public constant MINT_BGT_ROLE = keccak256("MINT_BGT_ROLE");

    constructor(address addrBGT) ERC20("BIC Right", "BIR") {
        address adminAddress = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(BLACK_LIST_ROLE, adminAddress);

        _setupRole(PAUSER_ROLE, adminAddress);

        _mint(adminAddress, 100000000 * 1e18);

        tokenAddressBGT = addrBGT;
    }

    event UpdateTokenAddressBGT(address addr, uint256 time);

    event BlockAddress(address addr, uint256 time);

    event UnblockAddress(address addr, uint256 time);

    event BurnReceiveBGT(address account, uint256 amount, uint256 time);

    mapping(address => bool) public blacklist;
    address public tokenAddressBGT;

    function updateTokenAddressBGT(address addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have DEFAULT_ADMIN_ROLE");
        tokenAddressBGT = addr;
        emit UpdateTokenAddressBGT(addr, block.timestamp);
    }

    function blockAddress(address addr) public {
        require(hasRole(BLACK_LIST_ROLE, _msgSender()), "Must have black list role to block");
        blacklist[addr] = true;
        emit BlockAddress(addr, block.timestamp);
    }

    function unblockAddress(address addr) public {
        require(hasRole(BLACK_LIST_ROLE, _msgSender()), "Must have black list role to unblock");
        blacklist[addr] = false;
        emit UnblockAddress(addr, block.timestamp);
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to pause");
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must have pauser role to unpause");
        _unpause();
    }

    function burnReceiveBGT(uint256 amount) public {
        burn(amount);
        BeinGiveTake bgtToken = BeinGiveTake(tokenAddressBGT);
        bgtToken.mintTo(msg.sender, amount);
        emit BurnReceiveBGT(msg.sender, amount, block.timestamp);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        require(!blacklist[from], "Address is in blacklist");
        if (hasRole(MINT_BGT_ROLE, from)) {
            BeinGiveTake bgtToken = BeinGiveTake(tokenAddressBGT);
            bgtToken.mintTo(to, amount);
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}
