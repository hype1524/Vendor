pragma solidity 0.8.20;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);

    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) Ownable(msg.sender) {
        yourToken = YourToken(tokenAddress);
    }

    // 💰 Mua token
    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        uint256 amountToBuy = msg.value * tokensPerEth;

        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Vendor contract has insufficient tokens");

        bool sent = yourToken.transfer(msg.sender, amountToBuy);
        require(sent, "Token transfer failed");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    // 💸 Bán token
    function sellTokens(uint256 amount) public {
        require(amount > 0, "Specify an amount > 0");
        uint256 ethAmount = amount / tokensPerEth;

        uint256 contractEthBalance = address(this).balance;
        require(contractEthBalance >= ethAmount, "Vendor has insufficient ETH");

        // Transfer tokens from sender to vendor
        bool approved = yourToken.transferFrom(msg.sender, address(this), amount);
        require(approved, "Token transfer failed");

        // Send ETH back to sender
        (bool sent, ) = msg.sender.call{value: ethAmount}("");
        require(sent, "ETH transfer failed");

        emit SellTokens(msg.sender, amount, ethAmount);
    }

    // 🏦 Rút toàn bộ ETH
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Withdraw failed");
    }

    // Nhận ETH fallback
    receive() external payable {}
}
