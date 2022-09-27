// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this branch/repo. Also return variable names that may need to be specified exactly may be referenced (if you are confused, see solutions folder in this repo and/or cross reference with front-end code).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    using SafeMath for uint256; //outlines use of SafeMath for uint256 variables
    IERC20 token; //instantiates the imported contract

    uint256 public totalLiquidity;
    mapping(address => uint256)liquidity; 

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address user, string trade, uint256 ethDeposited, uint256 baloonWithrawn);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address user, string trade, uint256 baloonDeposited, uint256 ethWithdrawn);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(address user, uint256 liquidityMinted, uint256 ethIn, uint256 balloonsIn);

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(address user, uint256 liquidityWithdrawn,  uint256 ethOut, uint256 baloonsOut);

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr)  {
        token = IERC20(token_addr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) public payable returns (uint256) {

        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;

        // transfer tokens from msg.sender to current address
        require(token.transferFrom(msg.sender, address(this), tokens), "Initial transfer failed");

        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev Follow along with the [original tutorial](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90) Price section for an understanding of the DEX's pricing model and for a price function to add to your contract. You may need to update the Solidity syntax (e.g. use + instead of .add, * instead of .mul, etc). Deploy when you are done.
     */
    function price(
        uint256 xInput,
        uint256 xReserves,
        uint256 yReserves
    ) public pure returns (uint256 yOutput) {

        // Taking into account 0.03% fees charged by DEX

        uint256 numerator = yReserves * 997 * xInput;
        uint256 denominator = 1000 * xReserves + 997 * xInput;
        yOutput = numerator / denominator;
    }

    /**
     * @notice returns liquidity for a user. Note this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     * if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
     *
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {

        uint256 tokenInput = msg.value;
        // Eth reserves = balance eth in account - eth sent by current sender
        uint256 ethReserves = address(this).balance - tokenInput;
        uint256 baloonReserves = token.balanceOf(address(this));

    
        tokenOutput = price(tokenInput, ethReserves, baloonReserves);

        require(token.transfer(msg.sender, tokenOutput), "ethToToken transfer failed!");

        emit EthToTokenSwap(msg.sender, "ETH -> BAL", tokenInput, tokenOutput);
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {

          // deposit baloon tokens into DEX
          // assumption is that baloon tokens are already approved by user for usage by DEX

          uint256 ethReserves = address(this).balance;
          uint256 baloonReserves = token.balanceOf(address(this));
 
          ethOutput = price(tokenInput, baloonReserves, ethReserves);
          console.log("baloon balance in sender account %s",  token.balanceOf(msg.sender));
          console.log("baloethon balance in sender account %s",  address(msg.sender).balance);
          console.log("from address %s",  msg.sender);
          console.log("to address %s", address(this));
          console.log("token input %s", tokenInput);  
          console.log("token balance in DEX before transfer %s", address(this).balance); 

          require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth: Failed to transfer tokens into DEX");
          console.log("token balance in DEX after transfer %s", address(this).balance);  

          console.log("eth output %s", ethOutput);  
          console.log("ETH balance in DEX before transfer %s", address(this).balance);  
          (bool success, ) = address(msg.sender).call{value: ethOutput}("");
          console.log("ETH balance in DEX after transfer %s", address(this).balance);  

          require(success, "tokenToEth: Eth transfer to user failed");

          emit TokenToEthSwap(msg.sender, "BAL -> ETH", tokenInput, ethOutput);

    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() public payable returns (uint256 tokensDeposited) {

        uint256 ethDeposit = msg.value;
        uint256 ethReserve = address(this).balance - ethDeposit; // eth reserve before current eth was deposited
        uint baloonReserve = token.balanceOf(address(this));

        uint baloonDeposit = ethDeposit * baloonReserve / ethReserve;

        require(token.transferFrom(msg.sender, address(this), baloonDeposit), "deposit: Baloon deposit failed");

        uint256 liquidityDelta = ethDeposit * totalLiquidity / ethReserve;
        totalLiquidity += liquidityDelta;
        liquidity[msg.sender] += liquidityDelta;

        tokensDeposited = baloonDeposit;

        emit LiquidityProvided(msg.sender, liquidityDelta, ethDeposit, baloonDeposit);
    }

    /**
     * @notice allows withdrawal of $BAL and $ETH from liquidity pool
     * NOTE: with this current code, the msg caller could end up getting very little back if the liquidity is super low in the pool. I guess they could see that with the UI.
     */
    function withdraw(uint256 amount) public returns (uint256 eth_amount, uint256 token_amount) {
        console.log("liquidity to be removed %s", amount);
        console.log("liquidity of user %s", liquidity[msg.sender]);
        require(amount <= liquidity[msg.sender], "Not enough liquidity in pool to withdraw");
        uint256 ethReserve = address(this).balance;
        uint256 baloonReserve = token.balanceOf(address(this));

        uint256 ethWithdraw = amount * ethReserve / totalLiquidity;
        uint256 baloonWithdraw = amount * baloonReserve / totalLiquidity;

        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount; 

        // transfer baloon
        require(token.transfer(msg.sender, baloonWithdraw), "withdraw: baloon transfer failed");

        // transfer eth
        (bool success, ) = address(msg.sender).call{value: ethWithdraw}("");
        require(success, "withdraw: ETH transfer failed");

        emit LiquidityRemoved(msg.sender, amount, ethWithdraw, baloonWithdraw);

        eth_amount = ethWithdraw;
        token_amount = baloonWithdraw;

    }
}
