// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hardhat = require("hardhat");
const { ethers } = hardhat;

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const accounts = await ethers.getSigners();
  // ValuableCoinsV3 token address in BSC Testnet
  const owner = "0xdD9C6B59577E49Dafc39F37Ee99A115F4087a301";
  const ValuableCoinsV3InBSC = "0xc06365510021B68fa31cfAc90e41D820B1827f6A";
  // ValuableCoinsV3 token address in BSC Mainnet
  // const owner = 0xdD9C6B59577E49Dafc39F37Ee99A115F4087a301;
  // const ValuableCoinsV3InBSC = 0xF6e497Bd65DfB7c0556020DD68d007f0AC76bc6a;

  // We get the contract to deploy
  // const ValuableCoinsV3 = await hre.ethers.getContractFactory("ValuableCoinsV3");
  // const valuableCoinsV3 = await ValuableCoinsV3.deploy(accounts[0].address);
  // await valuableCoinsV3.deployed();

  const MoonFomoV3 = await ethers.getContractFactory("MoonFomoV3");
  const moonFomoV3 = await MoonFomoV3.deploy(owner, ValuableCoinsV3InBSC);
  await moonFomoV3.deployed();

  console.log("ValuableCoinsV3 deployed to:", ValuableCoinsV3InBSC);
  console.log("MoonFomoV3 deployed to:", moonFomoV3.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
