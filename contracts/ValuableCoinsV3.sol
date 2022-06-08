// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract ValuableCoinsV3 is ERC20, Ownable {
    using SafeMath for uint256;
    address public feeTo;
    bool public feeFlag;

    constructor(address payable _feeTo, uint256 _totalsupply) ERC20("ValuableCoins", "VC") {
        feeTo = _feeTo;
        feeFlag = false;
        _mint(feeTo, _totalsupply * 10 ** decimals());
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address _sender = _msgSender();
        if (feeFlag) {
            uint256 _tokenToDev = amount.div(50);       // 2% -> feeTo
            uint256 _tokenToBurn = amount.div(100);     // 1% -> burn
            uint256 _tokenToTransfer = amount.sub(_tokenToDev).sub(_tokenToBurn);

            _transfer(_sender, to, _tokenToTransfer);
            _transfer(_sender, feeTo, _tokenToDev);
            _burn(_sender, _tokenToBurn);
        }
        else {
            _transfer(_sender, to, amount);
        }
        return true;
    }

    function setFeeTo(address payable _feeTo) external onlyOwner {
        require(_feeTo != address(0), "Invalid Address");
        feeTo = _feeTo;
    }

    function setFeeFlag(bool _feeFlag) external onlyOwner {
        feeFlag = _feeFlag;
    }
}
