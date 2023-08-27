const PriceConsumerV3 = artifacts.require("PriceConsumerV3")
const AggregatorV3InterfaceMock = artifacts.require("AggregatorV3InterfaceMock")

module.exports = async function (deployer, network, accounts) {
    let addr
    if (network === "development") {
        await deployer.deploy(AggregatorV3InterfaceMock)
        const mockDataFeed = await AggregatorV3InterfaceMock.deployed()
        addr = mockDataFeed.address
    } else {
        addr = "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526"
    }
    await deployer.deploy(PriceConsumerV3, addr)
}