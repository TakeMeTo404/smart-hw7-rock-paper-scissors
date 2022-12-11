import { ethers } from "hardhat";

async function main() {
  const rpcFactory = await ethers.getContractFactory("RockPaperScissors");
  const rpc = await rpcFactory.deploy();

  await rpc.deployed();

  console.log(`RockPaperScissors deployed to ${rpc.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
