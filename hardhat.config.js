require("@nomiclabs/hardhat-waffle");
require('dotenv').config();

const chainIds = {
  bscMainnet: 56,
  bscTestnet: 97,
  ganache: 1337,
  hardhat: 31337,
  ethKovan: 42,
  ethMainnet: 1,
  ethRopsten: 3,
};

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      chainId: chainIds.hardhat,
      forking: { // mainnet fork
        enabled: false,
        url: `https://speedy-nodes-nyc.moralis.io/${process.env.MORALIS_SPEEDY_NODE_KEY}/bsc/mainnet`
      }
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      chainId: chainIds.bscTestnet,
      gasPrice: 20000000000,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: chainIds.bscMainnet,
      gasPrice: 20000000000,
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : []
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY,
  },
};
