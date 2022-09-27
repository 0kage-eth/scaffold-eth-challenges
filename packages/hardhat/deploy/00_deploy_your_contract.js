// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

// change this later
//const OWNER = "0x3d3d9c716669d4529fcadac17ea87fb697f924d5";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();
  console.log("deployer address", deployer);
  await deploy("Balloons", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    // args: [ "Hello", ethers.utils.parseEther("1.5") ],
    log: true,
  });
  const balloons = await ethers.getContract("Balloons", deployer);
  await deploy("DEX", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [balloons.address],
    log: true,
    waitConfirmations: 5,
  });
  const dex = await ethers.getContract("DEX", deployer);
  // paste in your front-end address here to get 10 balloons on deploy:
  await balloons.transfer(deployer, ethers.utils.parseEther("10"));
  // const balance = await balloons.balanceOf(OWNER);
  // console.log(`balance in baloon is ${balance}`);
  // uncomment to init DEX on deploy:
  console.log(
    "Approving DEX (" + dex.address + ") to take Balloons from main account..."
  );
  // If you are going to the testnet make sure your deployer account has enough ETH
  // approve use of tokens by Dex
  const approvalResponse = await balloons.approve(
    dex.address,
    ethers.utils.parseEther("100")
  );
  await approvalResponse.wait(1);
  // we are sending 5 ethers and 5 balloon tokens
  // notice that its assumed to be 1-to-1 conversion
  console.log("INIT exchange...");
  await dex.init(ethers.utils.parseEther("0.001"), {
    value: ethers.utils.parseEther("0.001"),
    gasLimit: 200000,
  });
  //const allowance = await balloons.allowance(deployer, dex.address);
  //console.log(`allowance for Dex contract is ${allowance.toString()}`);
  // console.log("funded DEX with 5 Ether and 5 Baloons");
};
module.exports.tags = ["Balloons", "DEX"];
