// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Contribution is Ownable {
    constructor(address bicAddr, address busdAddr, uint256 _startDecay, uint256 _deltaDecay) {
        bicToken = IERC20(bicAddr);
        busdToken = IERC20(busdAddr);
        startDecay = _startDecay;
        deltaDecay = _deltaDecay;
    }

    using SafeMath for uint256;
    IERC20 public bicToken;
    IERC20 public busdToken;

    uint256 public input = 1;
    uint256 public output = 100;

    uint256 public startDecay;
    uint256 public deltaDecay;

    mapping(address => bool) public whitelist;

    event UpdatePrice(uint256 input, uint256 output, uint256 time);

    event BuySuccess(address buyer, uint256 busdAmount, uint256 bicAmount, uint256 time);

    event WithdrawToken(address token, uint256 amount, address receiver, uint256 time);

    event AddToWhitelist(address _addr, uint256 time);

    event RemoveToWhitelist(address _addr, uint256 time);

    function addToWhitelist(address _addr) public onlyOwner {
        whitelist[_addr] = true;
        emit AddToWhitelist(_addr, block.timestamp);
    }

    function removeToWhitelist(address _addr) public onlyOwner {
        whitelist[_addr] = false;
        emit RemoveToWhitelist(_addr, block.timestamp);
    }

    function updatePrice(uint256 _input, uint256 _output) public onlyOwner {
        input = _input;
        output = _output;
        emit UpdatePrice(_input, _output, block.timestamp);
    }

    function withdraw(address _token) public onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 amount = token.balanceOf(address(this));

        require(
            amount > 0,
            "Token insufficient"
        );

        require(
            token.transfer(owner(), amount),
            "Token transfer fail"
        );

        emit WithdrawToken(
            _token,
            amount,
            owner(),
            block.timestamp
        );
    }


    function _receiveBusd( uint256 amount) private {
        require(
            busdToken.balanceOf(msg.sender) >= amount,
            "BUSD insufficient"
        );

        require(
            busdToken.transferFrom(msg.sender, owner(), amount),
            "Token transfer fail"
        );
    }


    function _sendBic(uint256 amount) private {
        require(
            bicToken.transfer(msg.sender, amount),
            "BIC transfer fail"
        );
    }


    function buy(uint256 amount) public {
        require(whitelist[msg.sender], "Do not have buy permission!");

        uint256 bonus = 10;
        if (block.number > startDecay) {
            uint256 countDecay = (block.number - startDecay).div(deltaDecay);
            if (countDecay < 10) {
                bonus = 10 - countDecay;
            } else {
                bonus = 0;
            }
        }

        uint256 outputAmount = amount.mul(output).div(input).mul(100 + bonus).div(100);

        require(
            bicToken.balanceOf(address(this)) >= outputAmount,
            "BIC insufficient"
        );

        _receiveBusd(amount);

        _sendBic(outputAmount);

        emit BuySuccess(msg.sender, amount, outputAmount, block.timestamp);
    }
}
