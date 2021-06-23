
const ethers = require("ethers");
const hre = require("hardhat");
const fs = require("fs")
require('dotenv').config()

async function main() {

  // We get the contract to deploy
  // await getBalanceOfGanacheUser()
  await displayBalanceOfAlice()

  const provider = new hre.ethers.providers.JsonRpcProvider(hre.network.config.url);
  const wallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY_ALICE, provider);
  
  // setting up the contract
  let contractName = "Source"
  res = await hre.artifacts.readArtifact(contractName)
  const ISource = new ethers.utils.Interface(res.abi)
  abi = ISource.format()
  const Source = await hre.ethers.getContractFactory(
    abi,
    res.bytecode,
    wallet);
  // const fee = ethers.utils.parseEther(process.env.ORACLE_RINKEBY_FEE_1)
  const source_deployment_tx = await Source.deploy();
  await source_deployment_tx.deployed();
  console.log("Source deployed to:", source_deployment_tx.address);

  fs.writeFileSync('./contracts/addresses/' + contractName + '_' + hre.network.name + '.txt', source_deployment_tx.address)
}

// async function transferToAccountDeployer(){
//     if (hre.network.name!='localhost'){
//         return null
//     }
//     const provider = new hre.ethers.providers.JsonRpcProvider(hre.network.config.url);
//     wallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY_GANACHE_USER, provider);
    
//     let amount = ethers.utils.parseEther('99.8');
//     let tx = {to: process.env.ADDRESS_ALICE,
//               value: amount};
//     return wallet.sendTransaction(tx);
// }

async function displayBalanceOfAlice(){
  const provider = new hre.ethers.providers.JsonRpcProvider(hre.network.config.url);
  wallet = new hre.ethers.Wallet(process.env.PRIVATE_KEY_ALICE, provider);
  balance = await wallet.getBalance()
  let amount = ethers.utils.formatEther(balance);
  console.log('Alice', amount)
}



main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

// console.log(Object.keys(hre))

// console.log(hre.network)