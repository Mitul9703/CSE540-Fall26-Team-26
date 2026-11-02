# CSE540-Fall26-Team-26

# A Blockchain-Based Pharmaceutical Supply Chain Provenance System

CSE 540: Engineering Blockchain Application, Team 26

## Team Members
- Advait Kankati
- Hui Yu Teng
- Mitul Krishna Balamurugan
- Mukund Giridhar
- Skandarsini Ramagiri Ramesh

## Project Description

This project tracks a medicine batch from the manufacturer all the way to the patient and keeps the whole history of that process on the blockchain so that no single company can fake it or quietly change it.

Medicines usually pass through many organizations before they reach a patient such as manufacturers, distributors, and pharmacies. Each of those companies keep their own logs so there is no single history that everyone trusts. This makes it hard to catch fake medicines, trace what happened, or even know if a shipment went outside the safe temperature range along the way, since a spoiled batch can still look normal.

To solve this problem, our solution uses a smart contract on Ethereum to give every organization one shared record that no single party controls. It logs each handoff, lets a regulator certify a batch, flags any batch that goes outside the safe temperature range during shipping, and stores a hash of each lab certificate while the actual file stays off-chain.

This repository is currently updated for the Smart Contract Design Draft milestone. The focus right now is on the structure of the smart contract and not a fully finished and deployed system. Some parts are kept simple on purpose and will be built out in later milestones.

## Tech Stack and Dependencies

- Solidity - for the smart contract language
- OpenZeppelin Contracts  - for role based access control
- Hardhat - to compile, test, and deploy the contract
- Ethers.js - lets the frontend talk to the contract
- React - frontend, planned for a later milestone
- IPFS through Pinata  - for off-chain storage for the certificate files
- Node.js and npm - to run the tools above
- Ethereum Sepolia test network - this is a free practice network, no real money

## Repository Structure
 
```
.
├── contracts/
│   └── PharmaProvenance.sol        # the smart contract
├── scripts/
│   └── deploy.js                   # deploys the contract (draft)
├── test/
│   └── PharmaProvenance.test.js    # a starter test
├── .env.example                    
├── .gitignore
├── hardhat.config.js               # Hardhat settings (Solidity version, Sepolia network)
├── package.json                    # project dependencies
└── README.md
```

The frontend and the temperature oracle script are not in the repo yet. They will be added in the later milestones.

## Smart Contract Overview

The main contract is `PharmaProvenance.sol`. It has:

- Five roles are Manufacturer, Distributor, Pharmacy, Regulator, and Patient/Public. The patient or public can only read the data and does not need a role.
- A Batch record that holds the batch ID, drug name, current owner, status, certified flag, temperature breach flag, and the certificate hash.
- Five events that make a permanent log: `BatchRegistered`, `CustodyTransferred`, `StatusUpdated`, `BatchCertified`, and `ColdChainBreached`.
- The main functions: `registerBatch`, `transferCustody`, `updateStatus`, `certifyBatch`, `recordTemperature`, plus `getBatch` and `getHistory` for reading.

Roles are handled with OpenZeppelin's AccessControl library. We use it only for the role bookkeeping. The rest of the supply chain logic is written by us.

## Setup Instructions

You will need Node.js and npm installed, plus the MetaMask browser extension.

1. Clone this repository.
   ```
   git clone https://github.com/Mitul9703/CSE540-Fall26-Team-26
   cd CSE540-Fall26-Team-26
   ```
2. Install the dependencies.
   ```
   npm install
   npm install --save-dev hardhat
   npm install @openzeppelin/contracts
   ```
3. Set up your environment file. Copy `.env.example` to a new file called `.env` and fill in your own Sepolia RPC URL and a test wallet private key. 
```
   cp .env.example .env
```

## How to Use and Deploy

This is the planned flow for compiling and deploying the contract. It is not fully wired up yet.

1. Compile the contract.
   ```
   npx hardhat compile
   ```
2. Deploy to the Sepolia test network using a Hardhat deploy script (Not added yet).
   ```
   npx hardhat run scripts/deploy.js --network sepolia
   ```
3. After deploying, the admin wallet gives out the roles, Manufacturer, Distributor, and so on,  to the other wallets.
4. The frontend will then connect through MetaMask and call the contract with Ethers.js, so people can register batches, transfer custody, update status, certify, and view a batch's full history.

## Status

The repo is currently designed for submission for the Smart Contract Design milestone. The smart contract structure and comments are in place. The frontend, the simulated temperature oracle and the full deployment setup will be added in the upcoming milestones.
