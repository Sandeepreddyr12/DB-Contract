# DB-Contract
# Decentralized Betting Contract

Welcome to the Decentralized Betting Contract repository! This contract is written in Solidity and developed using Hardhat for Ethereum smart contract development. It facilitates unlimited betting on either team in a match, utilizes decentralized oracle functions for fetching match data, leverages events for transparency, and allows users to withdraw their funds.

## Features

- **Unlimited Betting**: Users can place bets on either of the teams in a match without limitations.

- **Decentralized Oracle Functions**: Fetch match data from decentralized oracle functions to ensure data accuracy.( "oracle functions are in beta, haven't had results i wanted, so i given manual code simulates the matchcreation and results") 

- **Event Logging**: Comprehensive use of events to log all significant contract activities for transparency.

- **Withdrawal Functionality**: Users can withdraw their funds when the match results are determined.

## Deployment

This contract is designed to be deployed on the Ethereum blockchain. To deploy it, follow these steps:

1. Install Node.js and npm if you haven't already.

2. Install Hardhat globally:

   ```bash
   npm install -g hardhat

Configure your deployment settings in the hardhat.config.js file, specifying the desired network and account details.

Compile the contract:npx hardhat compile

Deploy the contract:npx hardhat run scripts/deploy.js --network your_network // (i'm using sepolia)



###Usage
Interact with the contract by connecting to it through a web interface or a dApp.
Fetch match data from decentralized oracle functions to ensure that the match details are accurate and unbiased.
Place bets on the team of your choice by sending Ether to the contract address along with your bet details.
Monitor events emitted by the contract to keep track of betting activity and match outcomes.
After the match result is determined, the contract will allow users to withdraw their winnings.


##Contract Structure
The contract is structured as follows:
contracts/BettingContract.sol: Contains the main betting contract code.
interfaces/OracleInterface.sol: Interface for interacting with decentralized oracle functions.
scripts/deploy.js: Deployment script.

###Testing
Ensure contract functionality is working as expected by running tests: npx hardhat test
npx hardhat test


###Contributing
We welcome contributions to improve this contract. To contribute: 
Fork the repository.
Create a new branch for your feature:git checkout -b feature/your-feature
git checkout -b feature/your-feature
Make your changes and commit them: git commit -m "Add your feature"
git commit -m "Add your feature"
Push to the branch: git push origin feature/your-feature
Create a pull request on GitHub.