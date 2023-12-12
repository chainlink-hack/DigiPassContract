# DigiPass-MVP

## Welcome to the DigiPass MVP repository

<p align="center" width="100%">
  <img src="https://github.com/chainlink-hack/DigiPassContract/assets/58889001/24998f4d-e181-48b2-be89-6b8c739b4b1f" alt="site"/>
</p>

> ## Table of contents
- [Overview](#overview)
- [Core Features Implemented](#core-features-implemented)
- [Technologies](#technologies)
- [Repo Setup](#repo-setup)
- [Requirements](#requirements)
- [Setup the Project](#setup-the-project)
  - [Install Hardhat](#install-hardhat)
  - [Env Setup](#env-setup)
  - [Setup Hardhat.config](#setup-hardhatconfig)
- [Setup the Frontend](#setup-the-frontend)
  - [Install Dependencies](#install-dependencies)
  - [Steps to host the live site on Vercel](#steps-to-host-the-live-site-on-vercel)
- [Testing the Smartcontract](#testing-the-smartcontract)
- [NFT-Factory-MVP Contract Address](#DigiPass-contract-address)
- [Live Link](#live-link)
- [Contributors](#contributors)
- [Contributing to the project](#contributing-to-the-project)
#
> ## Overview
<p align="justify">
DigiPass is a pioneering platform that reimagines event ticketing through decentralization, offering users a novel and versatile approach to ticket ownership and event access. Powered by cutting-edge blockchain technology and leveraging the capabilities of Chainlink, DigiPass aims to redefine the traditional concept of event tickets, transforming them into multifaceted assets with extensive utility.
</p>



#
> ## Core Features Implemented

`Deployment on Polygon chain`
Event Creation and Management:

- Smart contract allows for the creation of events, capturing essential details such as event name, venue, location, image URL, available tickets, start and end dates, ticket prices, categories, and organizing entity information.
Ticketing System:

- Manages ticket sales and distribution with different ticket types (regular, VIP, VVIP), associating each ticket with its owner, event ID, ticket number, price, QR code, and verification status.
Entities and Roles:

-Defines entities as users or organizations within the ecosystem, capturing their names, addresses, proofs (polygon ID), verification status, and roles (organization or participant).
Cross-Chain Ticket Purchases:

- Facilitates ticket purchases across different blockchain networks through the purchaseTicketCrossChain function, enabling users to acquire tickets using tokens from other chains.
IPFS and Decentralized Storage:


Event and Ticket Management Functions:

- Offers functions to create events, purchase tickets, verify ticket authenticity, manage event participants, check event validity, and handle event remittance for ticket sales.
  


`Test Coverage`
- Unit testing ensures that all the codes meet the quality standards and the functions return the expected output.
- Test coverage shows us the extent of how much of our codes are covered by tests. We ideally aim for 100% coverage.

`Natspec commenting`
- This documentation provides information about the codebase and their implementation for both technical and non technical people. 


</p>

#
> ## Technologies
| <b><u>Stack</u></b> | <b><u>Usage</u></b> |
| :------------------ | :------------------ |
| **`Solidity`**      | Smart contract      |
| **`React JS`**      | Frontend            |

#
> ## Repo Setup

<p align="justify">
To setup the repo, first fork the chainlink-hack Repo, then clone the forked repository to create a copy on the local machine.
</p>

    $ git clone https://github.com/chainlink-hack/DigiPassContract.git

<p align="justify">
Change directory to the cloned repo and set the original chainlink-hack repository as the "upstream" and your forked repository as the "origin" using gitbash. and make sure to switch to dev branch
</p>

    $ git remote add upstream  https://github.com/chainlink-hack/DigiPassContract.git

#

> ## Requirements
#
- Hardhat
- Polygon key
- Metamask key
- Node JS
#
> ## Setup the Project
**`*Note:`**

<p align="justify">
This project was setup on a windows 10 system using the gitbash terminal. Some of the commands used may not work with the VScode terminal, command prompt or powershell.
</p>

The steps involved are outlined below:-
#
> ### Install Hardhat
The first step involves cloning and installing hardhat.
```shell
$ cd core

$ npm i -D hardhat

$ npm install

$ npm install --save-dev "@nomiclabs/hardhat-waffle" "ethereum-waffle" "chai" "@nomiclabs/hardhat-ethers" "ethers" "web3" "@nomiclabs/hardhat-web3" "@nomiclabs/hardhat-etherscan" "@openzeppelin/contracts" "dotenv" "@tenderly/hardhat-tenderly" "hardhat-gas-reporter" "hardhat-deploy"
```
> ### Env Setup
 Next create a `.env` file by using the sample.env. Retrieve your information from the relevant sites and input the information where needed in the `.env` file.





#
> ## Setup the Frontend
- First run the frontend on your local server to ensure it's fully functional before building for production.
#
> ### Install Dependencies
- Setup and install dependencies

```shell
$ cd digipass_frontend

$ npm install

$ npm run dev
```


#
> ## Testing the Smartcontract

- Coverage is used to view the percentage of the code required by tests and unittests were implemented to ensure that the code functions as expected
#
**`Coverage Test`**
- To test the smartcontract, first open a terminal and run the following command:

- First install Solidity Coverage
```
  $ npm i solidity-coverage
```
- Add `require('solidity-coverage')` to hardhat.config.json

- Install Ganache
``` 
  $ npm i ganache-cli
``` 
- Run coverage
```
$ npx hardhat coverage --network localhost

# if you get errors and you want to trace the error in the terminal
$ npx hardhat coverage --network localhost --show-stack-traces
```

#
> ## digipass contractt Address/ Available 2 transaction hash 

- https://mumbai.polygonscan.com/address/0xe7D708a90E15051F5dd1e59493AE1C040f1D65A6

Tx: 

- 0x1d3d1b3156528b009f9e21b7a0577eddf8e4a73340093ac2aaeb50a652fdb9ab

- 0x706dbbd31ebbef21b5aedbd044477e23f90e830b9401d6abe590ce8bb9057609

the transaction hashes

> ## source ticket purchaser  contract address: sepolia/ Available 2 transanction hash

- https://sepolia.etherscan.io/address/0x23107CFBd172eE8dD40afad286C0cF2c9e0B6757

  Tx: 

- 0x1a0e37432b7df21b28ae2302ca33e4e9bf6a2bfdee4228d9657c9e6ded6ab3d0

  0xb968328ebf3d64f6a8238157d015d961f09fda9934b4d2b8c69b8f0ddddd86d5

the transaction hashes


# 

## Useful links

## View attribution files here



## Explainer video (User POV)


https://github.com/chainlink-hack/digipass_frontend/assets/58889001/98cae9c5-8553-499b-be63-1f6ec7ea24e8

## Demo Video (Clients POV)

https://github.com/chainlink-hack/DigiPassContract/assets/58889001/3d778d49-32eb-458b-bc1c-947165fbe987


- [Pitch Deck](https://github.com/chainlink-hack/digipass_frontend/files/13629815/Microsoft.365.Office.pdf)
- [Frontend Deployment](https://digipass-frontend.vercel.app/)
- [Figma design](https://www.figma.com/file/L5HHWOtdtUdJ0hDfWWJOMK/Untitled?type=design&node-id=618-1052&mode=design&t=fPNKhXS8MDtIFJ6r-0)


> ## Contributors

This Project was created by these awesome dedicated members

<p align="center" width="100%">
  <img src="https://github.com/chainlink-hack/digipass_frontend/assets/58889001/09329a63-113c-4b3d-8ff3-46844d880ad0" alt="DigiPass"/>
</p>

#
> ## Contributing to the project

If you find something worth contributing, please fork the repo, make a pull request and add valid and well-reasoned explanations about your changes or comments.

Before adding a pull request, please note:

- This is an open source project.
- Your contributions should be inviting and clear.
- Any additions should be relevant.
- New features should be easy to contribute to.

All **`suggestions`** are welcome!
#
> ##### README Created by `Enebeli Emmanuel` for DigiPass

