// This script deploys the PharmaProvenance contract to the chosen network.
// To run it: npx hardhat run scripts/deploy.js --network sepolia
// Note: this is a starting draft. We will finish and test it in the next milestone.

const hre = require("hardhat");

async function main() {
  // Get the contract and deploy it.
  const PharmaProvenance = await hre.ethers.getContractFactory("PharmaProvenance");
  const contract = await PharmaProvenance.deploy();
  await contract.waitForDeployment();

  // Print the address so we know where the contract lives on-chain.
  console.log("PharmaProvenance deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
