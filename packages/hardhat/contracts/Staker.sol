// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public openForWithdraw = false;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  event Stake(address staker, uint256 stakeAmount);

  modifier notCompleted(){
    require(block.timestamp >= deadline, "Deadline not over yet!");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  function stake() public payable{
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

    // After some `deadline` allow anyone to call an `execute()` function
     function execute() public notCompleted {

       // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
       
       //deadline has passed
       if(block.timestamp > deadline){
          
          
          if(address(this).balance >= threshold){
            // calling example external contract complete function
            exampleExternalContract.complete();

          }
          else{
            // If the `threshold` was not met, allow everyone to call a `withdraw()` function
            // allow users to withdraw funds 
            openForWithdraw = true;
          }
       } 
    }


  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted {

    uint256 balance = balances[msg.sender];
    delete balances[msg.sender];

    if(balance > 0){

      (bool success, ) = msg.sender.call{value: balance}("");
      require(success, "Withdrawal failed");
    }

  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256){
    if(deadline <= block.timestamp) return 0;

    return deadline - block.timestamp;

  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable{

    stake();

  }
}
