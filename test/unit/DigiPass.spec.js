const { network, ethers } = require("hardhat")
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers")
const { networkConfig, developmentChains } = require("../../helper-hardhat-config")
const { numToBytes32 } = require("../../helper-functions")
const { assert, expect } = require("chai")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("DigiPass Unit Tests", async function () {
          //set log level to ignore non errors
          ethers.utils.Logger.setLogLevel(ethers.utils.Logger.levels.ERROR)

          // We define a fixture to reuse the same setup in every test.
          // We use loadFixture to run this setup once, snapshot that state,
          // and reset Hardhat Network to that snapshot in every test.
          async function deployDigiPassFixture() {
              const [deployer] = await ethers.getSigners()
              

              const chainId = network.config.chainId

               const digiPassContract = await ethers.getContractFactory("DigiPass")
               const deployedDigiPassContract = await digiPassContract.connect(deployer).deploy()

               const destinationTicketPurchaser = await ethers.getContractFactory(
                   "DestinationTicketPurchaser"
               )
               const deployedDestinationPurchaser = await destinationTicketPurchaser
                   .connect(deployer)
                   .deploy(
                       networkConfig[chainId]["routerAddress"],
                       deployedDigiPassContract.address
                   )
            console.log("digiPass Contract deployed at:::", deployedDigiPassContract.address)
            console.log("destinationTicketPurchaser deployed at:::", deployedDestinationPurchaser.address)

              return { deployedDigiPassContract, deployedDestinationPurchaser }
          }

          describe("#Create Events", async function () {
              describe("success", async function () {
                  it("Should successfully make an API request", async function () {
                      const { apiConsumer } = await loadFixture(deployAPIConsumerFixture)
                      const transaction = await apiConsumer.requestVolumeData()
                      const transactionReceipt = await transaction.wait(1)
                      const requestId = transactionReceipt.events[0].topics[1]
                      expect(requestId).to.not.be.null
                  })

                  it("Should successfully make an API request and get a result", async function () {
                      const { apiConsumer, mockOracle } = await loadFixture(
                          deployAPIConsumerFixture
                      )
                      const transaction = await apiConsumer.requestVolumeData()
                      const transactionReceipt = await transaction.wait(1)
                      const requestId = transactionReceipt.events[0].topics[1]
                      const callbackValue = 777
                      await mockOracle.fulfillOracleRequest(requestId, numToBytes32(callbackValue))
                      const volume = await apiConsumer.volume()
                      assert.equal(volume.toString(), callbackValue.toString())
                  })

                  it("Our event should successfully fire event on callback", async function () {
                      const { apiConsumer, mockOracle } = await loadFixture(
                          deployAPIConsumerFixture
                      )
                      const callbackValue = 777
                      // we setup a promise so we can wait for our callback from the `once` function
                      await new Promise(async (resolve, reject) => {
                          // setup listener for our event
                          apiConsumer.once("DataFullfilled", async () => {
                              console.log("DataFullfilled event fired!")
                              const volume = await apiConsumer.volume()
                              // assert throws an error if it fails, so we need to wrap
                              // it in a try/catch so that the promise returns event
                              // if it fails.
                              try {
                                  assert.equal(volume.toString(), callbackValue.toString())
                                  resolve()
                              } catch (e) {
                                  reject(e)
                              }
                          })
                          const transaction = await apiConsumer.requestVolumeData()
                          const transactionReceipt = await transaction.wait(1)
                          const requestId = transactionReceipt.events[0].topics[1]
                          await mockOracle.fulfillOracleRequest(
                              requestId,
                              numToBytes32(callbackValue)
                          )
                      })
                  })
              })
          })
      })
