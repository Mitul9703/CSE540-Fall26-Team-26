// Hardhat configuration file.
// This tells Hardhat which Solidity version to use and how to reach the Sepolia test network when we deploy. The RPC URL and the private key are read from a .env file so we never put secrets directly in the code.

require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// These come from the .env file (see .env.example). They are left empty by default so the project still loads even before you have added them.
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
};
