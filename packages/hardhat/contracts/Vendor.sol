pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";
// import "hardhat/console.sol";

contract Vendor is Ownable {

  YourToken public yourToken;
  
  
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfETH, uint256 amountOfTokens);
  uint256 public constant tokensPerEth = 100;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() external payable{
    uint256 numTokens = (msg.value * tokensPerEth);

    bool success = yourToken.transfer(msg.sender, numTokens);
    require(success, "Transfer failed!");

    emit BuyTokens(msg.sender, msg.value, numTokens);
  }
  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() external payable onlyOwner{

    require(owner() == msg.sender, "Only owner can withdraw funds");

    (bool success, ) = (msg.sender).call{value: address(this).balance}("");

    require(success, "Withraw failed!");

  }


  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 _amount) external payable{

    // first approve Your Token held by user
    // bool isApproved = yourToken.approve(address(this), _amount);

    // next accept tokens from user
    // if(isApproved){
      // console.log("amount of tokens %s", _amount);
      // console.log("amount of eth %s", _amount / tokensPerEth);

      bool success = yourToken.transferFrom(msg.sender, address(this), _amount);
      require(success, "Your token buyback by vendor failed!");

      payable(msg.sender).transfer(_amount / tokensPerEth) ;

      emit SellTokens(msg.sender, _amount/tokensPerEth, _amount);
    }
  // }


}
