// This is the starter tests for the PharmaProvenance contract.
// This is a draft. We will add more tests in the next milestone, but this one shows the basic setup and a simple check so the structure is already in place.

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PharmaProvenance", function () {
  it("deploys and makes the deployer the admin", async function () {
    const [admin] = await ethers.getSigners();

    const PharmaProvenance = await ethers.getContractFactory("PharmaProvenance");
    const contract = await PharmaProvenance.deploy();
    await contract.waitForDeployment();

    // In OpenZeppelin AccessControl, DEFAULT_ADMIN_ROLE is 32 zero bytes.
    const DEFAULT_ADMIN_ROLE = ethers.ZeroHash;
    expect(await contract.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.equal(true);
  });
});
