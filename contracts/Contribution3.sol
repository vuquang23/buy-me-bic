// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Contribution3 is Ownable {
    constructor(address bicAddr, address busdAddr) {
        bicToken = IERC20(bicAddr);
        busdToken = IERC20(busdAddr);
    }

    using SafeMath for uint256;
    IERC20 public bicToken;
    IERC20 public busdToken;

    uint256 public input = 1;
    uint256 public output = 100;
    uint256 public airdrop = 10; // 10%

    event UpdatePrice(uint256 input, uint256 output, uint256 time);
    event UpdateAirdrop(uint256 airdrop, uint256 time);

    event BuySuccess(address buyer, uint256 busdAmount, uint256 bicAmount, uint256 time);

    event WithdrawToken(address token, uint256 amount, address receiver, uint256 time);

    function updatePrice(uint256 _input, uint256 _output) public onlyOwner {
        input = _input;
        output = _output;
        emit UpdatePrice(_input, _output, block.timestamp);
    }

    function updateAirdrop(uint256 _airdrop) public onlyOwner {
        airdrop = _airdrop;
        emit UpdateAirdrop(_airdrop, block.timestamp);
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


    function _receiveBusd(uint256 amount) private {
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
        uint256 outputAmount = amount.mul(output).div(input).mul(100 + airdrop).div(100);

        require(
            bicToken.balanceOf(address(this)) >= outputAmount,
            "BIC insufficient"
        );

        _receiveBusd(amount);

        _sendBic(outputAmount);

        emit BuySuccess(msg.sender, amount, outputAmount, block.timestamp);
    }
}
