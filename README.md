# Autonet Contracts

This repository contains smart contracts written in Solidity for Autonet - economy-as-a-service for deep learning applications. 

The official production version of Autonet is deployed at https://autonet.live

The contracts are still in and testing/auditing stages, and are not intended for production use. The repository also includes some JSON files that contain the ABI (Application Binary Interface) of the contracts, which can be used to interact with them using web3.js or other libraries.

## Table of Contents

1. [Introduction](#introduction)
2. [Smart Contracts](#smart-contracts)
   1. [ATN Token](#atn-token)
   2. [Transaction Types](#transaction-types)
3. [Dependencies](#dependencies)
4. [Deployment](#deployment)
5. [Testing](#testing)
6. [Security](#security)
7. [License](#license)

## Introduction

The ATN platform aims to address the challenge of economic irrelevance targeting all professional categories. By leveraging the power of decentralized equilibrium algorithms, ATN provides a secure and efficient way to distribute ownership of AI services to the public at large, thus allowing for a peaceful and orderly transition of responsibilities from humans to machines. 
The system allows users to create projects, invest in them using the ATN tokens and Ether, and access AI services provided by the projects. The core contracts in the system include MainToken, Source, User, and Project.


## Smart Contracts

### MainToken (ATN)

The MainToken contract is an ERC777 token with the symbol "ATN" and name "AUTONET". It's the native token of the Autonet ecosystem and is used to invest in projects, purchase shares, and pay for AI services. The contract includes a function called `imprima`, which allows the owner of the contract to mint new tokens.

### Source

The Source contract is the central hub of the Autonet ecosystem. It manages users, projects, and investments. The contract creates new User and Project contracts, handles investments, and emits events to signal project status changes. It also allows users to buy and sell ATN tokens in exchange for Ether.

#### Functions

- `createUser()`: Creates a new User contract for the sender and returns its address.
- `balanceATN()`: Returns the ATN token balance of the Source contract.
- `createProject()`: Creates a new Project contract with the specified parameters and returns its address.
- `invest()`: Allows users to invest ATN tokens and Ether in a project. It transfers the invested amount to the project and updates the investor's shares.
- `buy()`: Allows users to buy ATN tokens with Ether.
- `sell()`: Allows users to sell ATN tokens for Ether.

### User

The User contract represents an individual user in the Autonet ecosystem. It stores the user's ATN and Ether balances and manages their assets, including project shares. Users can create projects, sell their shares, and withdraw ATN tokens from their balance.

#### Functions

- `balanceETH()`: Returns the Ether balance of the User contract.
- `balanceATN()`: Returns the ATN token balance of the User contract.
- `sellShares()`: Allows users to sell a specified amount of shares in a project.
- `withdraw()`: Allows users to withdraw a specified amount of ATN tokens from their balance.
- `createProject()`: Allows users to create a new project with the specified parameters.

### Project

The Project contract represents a project in the Autonet ecosystem. Each project has a unique name, code, funding goal, and founder. The contract manages the project's shares, subscriptions, and status (investing, training, validating, or mature). It also implements the IERC777Recipient interface, allowing it to receive ATN tokens and update investors' shares accordingly.

#### Functions

- `changeCodeUrl()`: Allows the deployer or founder to change the project's code URL.
- `transferFoundership()`: Allows the deployer or founder to transfer the project's foundership to another address.
- `completeTraining()`: Allows the project to transition from the training to the validating phase by setting an API endpoint.
- `completeValidation()`: Allows the project to transition from the validating to the mature phase, creating and initializing an Agent contract.
- `subscribe()`: Allows users to subscribe to the project's AI services by investing ATN tokens.
- `requestEndpoint()`: Returns the project's AI service endpoint to the subscribed users.
- `balanceATN()`: Returns the ATN token balance of the Project contract.
- `balanceETH()`: Returns the Ether balance of the Project contract.
- `invest()`: Allows users to invest ATN tokens and Ether in the project and updates their shares.

## Workflow

1. Users interact with the Source contract to create their own User contract using the `createUser()` function.
2. Users can buy ATN tokens from the Source contract using the `buy()` function, which allows them to exchange Ether for ATN tokens.
3. Users create projects by calling the `createProject()` function of their User contract, which in turn interacts with the Source contract to create a new Project contract.
4. Users and other investors can invest in projects by calling the `invest()` function of the Source contract, which transfers ATN tokens and Ether to the Project contract and updates the investor's shares accordingly.
5. The project founder can change the project's code URL using the `changeCodeUrl()` function of the Project contract.
6. The project founder can transfer the project's foundership to another address using the `transferFoundership()` function of the Project contract.
7. Once a project's training phase is complete, the project can transition to the validating phase by calling the `completeTraining()` function, which sets an API endpoint for the project.
8. After the project's validation phase is complete, the project can transition to the mature phase by calling the `completeValidation()` function, which creates and initializes an Agent contract.
9. Users can subscribe to a project's AI services by calling the `subscribe()` function of the Project contract, investing ATN tokens in exchange for access to the AI services.
10. Subscribed users can request the project's AI service endpoint by calling the `requestEndpoint()` function of the Project contract.
11. Users can sell their shares in a project by calling the `sellShares()` function of their User contract, which reduces their share balance and updates the project's available shares.
12. Users can withdraw ATN tokens from their User contract by calling the `withdraw()` function.

### ATN Token

The ATN Token is an ERC-777 based digital asset that serves as the primary medium of exchange within the ATN platform. It has been designed to offer a superior user experience compared to traditional ERC-20 tokens by leveraging the advanced features and capabilities of the ERC-777 standard:

1. **Advanced token operations**: The ERC-777 standard introduces powerful new features, such as `send`, `receive`, and `operatorSend`, which allow for more efficient and flexible token transfers. These features also enable better handling of potential token misuse and enable the implementation of advanced token logic.

2. **Enhanced compatibility**: While the ATN Token is built on the ERC-777 standard, it retains compatibility with ERC-20 based systems. This means that the ATN Token can be easily integrated into existing platforms and services that support the ERC-20 standard, ensuring a smooth transition and widespread adoption.

3. **Hooks and callbacks**: The ERC-777 standard introduces hooks and callbacks, which enable the implementation of custom logic during token transfers. This functionality allows the ATN Token to support complex use cases and enables the creation of unique token features tailored to specific needs.

4. **Reduced transaction costs**: By using the advanced features of the ERC-777 standard, the ATN Token can help reduce transaction costs compared to traditional ERC-20 tokens. This leads to a more efficient and cost-effective ecosystem for digital asset transactions.

5. **Increased security**: The ATN Token leverages the latest security features and best practices in smart contract development. This ensures a secure and reliable token that users can trust for their transactions.

Remember to update your smart contracts and interfaces to be compatible with the ERC-777 standard when working with the ATN Token. This will ensure a seamless integration and a smooth user experience for all parties involved.

## Dependencies

The ATN platform relies on the OpenZeppelin library, a widely-adopted and secure framework for building smart contracts. The library provides the necessary components for implementing the ERC20 token standard and other essential features of the platform.

## Deployment

To deploy the ATN smart contracts, follow the standard Ethereum development workflow, including the use of Truffle or Hardhat for compilation, testing, and deployment. Ensure that you have the required dependencies installed and configured before deploying the contracts.

## Testing

Comprehensive testing is crucial to ensure the security and reliability of the ATN platform. Use the testing framework of your choice (e.g., Mocha, Chai) to test the various features and functions of the smart contracts. Be sure to cover all possible edge cases and potential vulnerabilities.

## Security

The ATN platform is built on top of the Ethereum blockchain, which provides a high level of security and decentralization. However, it is essential to ensure that the smart contracts themselves are secure and free from vulnerabilities. Conduct thorough code reviews and consider engaging external auditors to evaluate the security of the smart contracts.

## License

The ATN platform is released under the MIT License, which allows for the open-source distribution and modification of the software. It provides users with the freedom to use, study, share, and modify the platform according to their needs, while also encouraging collaboration and improvements from the community.

# Contributing

Contributions from the community are highly encouraged and appreciated. If you wish to contribute to the ATN platform, please follow these steps:

1. Fork the repository
2. Create a new branch for your feature or bugfix
3. Implement and test your changes
4. Ensure that your code adheres to the project's coding standards and guidelines
5. Submit a pull request with a detailed description of your changes

We welcome contributions in various forms, including bug reports, feature requests, code improvements, and documentation updates. By contributing to the ATN platform, you help in creating a more robust and efficient ecosystem for digital asset transactions.

# Support

If you encounter any issues or have questions about the ATN platform, please create a new issue on the GitHub repository or reach out to the project maintainers through the provided contact channels. We are committed to providing support and assistance to our users and will do our best to address your concerns in a timely manner.

# Acknowledgements

We would like to extend our gratitude to the Ethereum and OpenZeppelin communities for their ongoing support, guidance, and contributions. The ATN platform is built upon the foundation laid by these communities, and their efforts have been invaluable in shaping the development of the platform.




