import "@nomicfoundation/hardhat-toolbox";
import { config as dotenvConfig } from "dotenv";
import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import '@openzeppelin/hardhat-upgrades';


import "./tasks/accounts";
import "./tasks/deploy";
import "./tasks";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC;
// if (!mnemonic) {
//   throw new Error("Please set your MNEMONIC in a .env file");
// }

// Ensure that we have all the environment variables we need.
const privatekey: string | undefined = process.env.PRIVATEKEY;
if (!privatekey) {
  throw new Error("Please set your privatekey in a .env file");
}

const prodPrivatekey: string | undefined = process.env.PRODPRIVATEKEY;
if (!prodPrivatekey) {
  throw new Error("Please set your production privatekey in a .env file")
}

const starlandPrivatekey: string | undefined = process.env.STARLANDPRIVKEY;
if (!starlandPrivatekey) {
  throw new Error("Please set your starland privatekey in a .env file")
}

// const accounts = [privatekey]
// const prodAccounts = [prodPrivatekey]
const accounts = [starlandPrivatekey]
const prodAccounts = [prodPrivatekey]

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY;
if (!infuraApiKey) {
  throw new Error("Please set your INFURA_API_KEY in a .env file");
}

const chainIds = {
  hardhat: 31337,
  mainnet: 1,
  goerli: 5,

  bsc: 56,
  "bsc-testnet": 97,

  "optimism-mainnet": 10,

  "polygon-mainnet": 137,
  "polygon-mumbai": 80001,

  "avalanche-mainnet": 43114,

  "arbitrum-mainnet": 42161,

  "aurora-mainnet": 1313161554,
  "aurora-betanet": 1313161556,

  sepolia: 11155111,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "bsc":
      jsonRpcUrl = "https://bsc-dataseed1.binance.org";
      break;
    case "bsc-testnet":
      jsonRpcUrl = "https://data-seed-prebsc-1-s1.binance.org:8545/";
      break;
    default:
      jsonRpcUrl = "https://" + chain + ".infura.io/v3/" + infuraApiKey;
  }

  let key: string[]
  switch (chain) {
    case "mainnet":
      key = prodAccounts;
      break;
    case "bsc":
      key = prodAccounts;
      break;
    case "polygon-mainnet":
      key = prodAccounts;
      break;
    default:
      key = accounts;
  }

  return {
    // accounts: {
    //   count: 10,
    //   mnemonic,
    //   // path: "m/44'/60'/0'/0",
    // },
    accounts:key,
    chainId: chainIds[chain],
    url: jsonRpcUrl,
    saveDeployments: true,
    live: true,
    tags: ["staging"],
  };
}

// @ts-ignore
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: {
      arbitrumOne: process.env.ARBISCAN_API_KEY || "",
      avalanche: process.env.SNOWTRACE_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || "",
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      optimisticEthereum: process.env.OPTIMISM_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
    feeCollector:{
      default: 1, // here this will by default take the second account as feeCollector (so in the test this will be a different account than the deployer)
    }
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic,
      },
      chainId: chainIds.hardhat,
      saveDeployments: true,
      live: false,
      tags: ["test", "local"],
    },
    arbitrum: getChainConfig("arbitrum-mainnet"),
    avalanche: getChainConfig("avalanche-mainnet"),
    bsc: getChainConfig("bsc"),
    "bsc-testnet": getChainConfig("bsc-testnet"),
    goerli: getChainConfig("goerli"),
    mainnet: getChainConfig("mainnet"),
    optimism: getChainConfig("optimism-mainnet"),
    "polygon-mainnet": getChainConfig("polygon-mainnet"),
    "polygon-mumbai": getChainConfig("polygon-mumbai"),
    sepolia: getChainConfig("sepolia"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
    deploy: 'deploy',
    deployments: 'deployments',
    imports: 'imports',
  },
  solidity: {
    version: "0.8.17",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/hardhat-template/issues/31
        bytecodeHash: "none",
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
};

export default config;
