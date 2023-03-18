// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("0x5d5562b5bF56E4Db526938b4813b97bDD5bf8Fd0");
  const contract = await Contract.deploy("R54合约地址");
  await contract.deployed();
  console.log("合约部署地址:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
