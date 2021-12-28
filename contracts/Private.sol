// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Whitelist.sol";
import "./BeinGiveTake.sol";
import "./BICRight.sol";

contract Private is Ownable {
    bytes32 public constant WHITELIST_PRIVATE_SALE = keccak256("WHITELIST_PRIVATE_SALE");
    bytes32 public constant WHITELIST_CORE_TEAM = keccak256("WHITELIST_CORE_TEAM");

    constructor(address bicAddr, address birAddr, address bgtAddr, address busdAddr, address whitelistAddr) {
        bicToken = IERC20(bicAddr);
        birToken = BICRight(birAddr);
        bgtToken = BeinGiveTake(bgtAddr);
        busdToken = IERC20(busdAddr);
        whitelistContract = Whitelist(whitelistAddr);
        startDecay = block.number;
    }

    using SafeMath for uint256;
    IERC20 public bicToken;
    BICRight public birToken;
    BeinGiveTake public bgtToken;
    IERC20 public busdToken;
    Whitelist public whitelistContract;

    // Init Price 1 BIC = 0.011 BUSD => 1000 BIC = 11 BUSD
    uint256 public baseBUSD = 11;
    uint256 public baseBIC = 1000;

    uint256 public soldToken = 0;
    uint256 public amountStep = 10000000 * 1e18; // 10M BIC
    uint256 public priceStep = 1; // real = 1/baseBIC = 0.001 BUSD
    uint256 public maxBICEachBuy = amountStep;
    uint256 public maxBICWithoutBIR = 3000000 * 1e18;

    uint256 public startDecay;
    uint256 public deltaDecay = 864000; // 3600 * 24 * 30/3
    uint256 public maxBUSDCoreMonthly = 5000 * 1e18;
    address public airdropAddress;

    uint256 public coreTeamBonusPercent = 33;

    event UpdateAirdropInfo(address _addrAirdrop, uint256 _startDecay, uint256 _deltaDecay, uint256 _time);
    event UpdateAddressWhitelist(address _addr, uint256 _time);
    event UpdateLimitInfo(uint256 _amountStep, uint256 _priceStep, uint256 _maxBICWithoutBIR, uint256 _time);

    event BuySuccess(address _addUser, address _refAddr, uint256 _amountBUSD, uint256 _maxBIRFinal, uint256 _maxBIC1, uint256 _currentPrice1, uint256 _maxBIC2, uint256 _currentPrice2, uint256 _soldToken, uint256 _time);
    event BuyCoreTeamSuccess(address _addUser, address _refAddr, uint256 _amountBUSD, uint256 _maxBIC1, uint256 _currentPrice1, uint256 _maxBIC2, uint256 _currentPrice2, uint256 _soldToken, uint256 _time);
    event WithdrawToken(address _token, uint256 _amount, address _receiver, uint256 _time);
    event UpdateCoreTeamBonus(uint256 _coreTeamBonusPercent, uint256 _time);

    mapping(uint256 => mapping(address => uint256)) public coreBUSDMonthly;

    function updateAirdropInfo(address _addrAirdrop, uint256 _startDecay, uint256 _deltaDecay) public onlyOwner {
        airdropAddress = _addrAirdrop;
        startDecay = _startDecay;
        deltaDecay = _deltaDecay;
        emit UpdateAirdropInfo(_addrAirdrop, _startDecay, _deltaDecay, block.timestamp);
    }

    function updateAddressWhitelist(address _addr) public onlyOwner {
        whitelistContract = Whitelist(_addr);
        emit UpdateAddressWhitelist(_addr, block.timestamp);
    }

    function updateLimitInfo(uint256 _amountStep, uint256 _priceStep, uint256 _maxBICWithoutBIR) public onlyOwner {
        amountStep = _amountStep;
        priceStep = _priceStep;
        maxBICEachBuy = amountStep;
        maxBICWithoutBIR = _maxBICWithoutBIR;
        emit UpdateLimitInfo(_amountStep, _priceStep, _maxBICWithoutBIR, block.timestamp);
    }

    function updateCoreTeamBonus(uint256 _coreTeamBonusPercent) public onlyOwner {
        coreTeamBonusPercent = _coreTeamBonusPercent;
        emit UpdateCoreTeamBonus(coreTeamBonusPercent, block.timestamp);
    }

    function getBICFinal(uint256 amountBUSD) public view returns (uint256, uint256, uint256, uint256, uint256) {
        // currentPrice1 = 11 + soldToken/amountStep * priceStep
        uint256 currentPrice1 = baseBUSD.add((soldToken.div(amountStep).mul(priceStep)));
        uint256 currentPrice2 = 0;
        uint256 maxBICExpect = amountBUSD.mul(baseBIC).div(currentPrice1);

        uint256 maxBUSD1 = amountBUSD;
        uint256 maxBUSD2 = 0;
        uint256 maxBIC1 = maxBICExpect;
        uint256 maxBIC2 = 0;
        uint256 soldCurrentStep = soldToken.mod(amountStep);
        if (maxBICExpect.add(soldCurrentStep) > amountStep) {
            // 2 prices
            currentPrice2 = currentPrice1.add(priceStep);
            maxBIC1 = amountStep.sub(soldCurrentStep);
            maxBUSD1 = maxBIC1.mul(currentPrice1).div(baseBIC);
            maxBUSD2 = amountBUSD.sub(maxBUSD1);
            maxBIC2 = maxBUSD2.mul(baseBIC).div(currentPrice2);
        }

        uint256 maxBICFinal = maxBIC1.add(maxBIC2);
        return (maxBICFinal, maxBIC1, currentPrice1, maxBIC2, currentPrice2);
    }

    // return (maxBIRFinal, maxBICFinal, maxBIC1, currentPrice1, maxBIC2, currentPrice2)
    function handleCalculation(address user, uint256 amountBUSD, address[] memory listExtra) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 currentUserBIC = bicToken.balanceOf(user);
        for (uint256 i = 0; i < listExtra.length; i++) {
            address extra = listExtra[i];
            if (extra != address(0x0)) {
                uint256 bicAmountTemp = bicToken.balanceOf(extra);
                currentUserBIC = currentUserBIC.add(bicAmountTemp);
            } else {
                break;
            }
        }

        (uint256 maxBICFinal, uint256 maxBIC1, uint256 currentPrice1, uint256 maxBIC2, uint256 currentPrice2) = getBICFinal(amountBUSD);

        uint256 maxBIRFinal = 0;
        // MAX 3M BIC without BIR
        if (maxBICFinal.add(currentUserBIC) > maxBICWithoutBIR) {
            if (currentUserBIC > maxBICWithoutBIR) {
                maxBIRFinal = maxBICFinal;
            } else {
                maxBIRFinal = maxBICFinal.add(currentUserBIC).sub(maxBICWithoutBIR);
            }
        }
        return (maxBIRFinal, maxBICFinal, maxBIC1, currentPrice1, maxBIC2, currentPrice2);
    }

    function handleTransfer(address userAddr, address refAddr, uint256 amountBUSD, uint256 maxBICFinal, uint256 refBIC, uint256 refBGT) private {
        require(
            busdToken.transferFrom(userAddr, owner(), amountBUSD),
            "BUSD transfer from user to owner fail"
        );

        require(
            bicToken.transfer(userAddr, maxBICFinal),
            "BIC transfer from contract to user fail"
        );
        require(
            bicToken.transfer(refAddr, refBIC),
            "BIC transfer from contract to ref fail"
        );
        require(
            birToken.transfer(refAddr, refBIC),
            "BIR transfer from contract to ref fail"
        );

        bgtToken.mintTo(userAddr, amountBUSD);
        bgtToken.mintTo(refAddr, refBGT);
    }

    function buy(uint256 amountBUSD) public {
        (address refAddr, bool roleValue, address[] memory listExtra) = whitelistContract.getUserInfo(msg.sender, WHITELIST_PRIVATE_SALE);
        require(roleValue, "Do not have buy permission!");
        require(
            busdToken.balanceOf(msg.sender) >= amountBUSD,
            "BUSD insufficient"
        );

        (uint256 maxBIRFinal, uint256 maxBICFinal, uint256 maxBIC1, uint256 currentPrice1, uint256 maxBIC2, uint256 currentPrice2) = handleCalculation(msg.sender, amountBUSD, listExtra);
        require(maxBICFinal <= maxBICEachBuy, "MaxBICFinal over maxBICEachBuy.");

        // uint256 refBIC, uint256 refBGT
        uint256 refBIC = maxBICFinal.mul(33).div(1000);
        uint256 refBGT = amountBUSD.mul(88).div(1000);

        // handleTransfer(address userAddr, address refAddr, uint256 amountBUSD, uint256 maxBICFinal, uint256 refBIC, uint256 refBGT)
        handleTransfer(msg.sender, refAddr, amountBUSD, maxBICFinal, refBIC, refBGT);

        if (maxBIRFinal > 0) {
            birToken.burnFrom(msg.sender, maxBIRFinal);
        }
        soldToken = soldToken.add(maxBICFinal);
        emit BuySuccess(msg.sender, refAddr, amountBUSD, maxBIRFinal, maxBIC1, currentPrice1, maxBIC2, currentPrice2, soldToken, block.timestamp);
    }

    function buyCoreTeam(uint256 amountBUSD) public {
        (address refAddr, bool roleValue,) = whitelistContract.getUserInfo(msg.sender, WHITELIST_CORE_TEAM);
        require(roleValue, "Do not have buy permission!");
        require(
            busdToken.balanceOf(msg.sender) >= amountBUSD,
            "BUSD insufficient"
        );

        (uint256 maxBICFinal, uint256 maxBIC1, uint256 currentPrice1, uint256 maxBIC2, uint256 currentPrice2) = getBICFinal(amountBUSD);
        // uint256 refBIC, uint256 refBGT
        uint256 refBIC = maxBICFinal.mul(33).div(1000);
        uint256 refBGT = amountBUSD.mul(88).div(1000);

        // handleTransfer(address userAddr, address refAddr, uint256 amountBUSD, uint256 maxBICFinal, uint256 refBIC, uint256 refBGT)
        handleTransfer(msg.sender, refAddr, amountBUSD, maxBICFinal, refBIC, refBGT);

        uint256 bonus = maxBICFinal.mul(coreTeamBonusPercent).div(100);
        require(
            bicToken.transferFrom(airdropAddress, msg.sender, bonus),
            "BIC transfer bonus from airdropAddress to user fail"
        );
        uint256 countDecay = (block.number.sub(startDecay)).div(deltaDecay);
        uint256 amountBUSDThisMonth = coreBUSDMonthly[countDecay][msg.sender].add(amountBUSD);
        require(amountBUSDThisMonth <= maxBUSDCoreMonthly, "User buy over max 5000 BUSD in this month");
        coreBUSDMonthly[countDecay][msg.sender] = amountBUSDThisMonth;
        soldToken = soldToken.add(maxBICFinal);
        emit BuyCoreTeamSuccess(msg.sender, refAddr, amountBUSD, maxBIC1, currentPrice1, maxBIC2, currentPrice2, soldToken, block.timestamp);
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
}
