const WBNB = artifacts.require("WBNB");
const TokenA = artifacts.require("TokenA");
const TokenB = artifacts.require("TokenB");
const DexFactory = artifacts.require("DEXFactory");
const Dex = artifacts.require("DEX"); // If you have a separate Dex contract file
const LiquidityPool = artifacts.require("LiquidityPool"); // If you have a separate LiquidityPool contract file
const LiquidityPoolFactory = artifacts.require("LiquidityPoolFactory"); // If you have a separate LiquidityPoolFactory contract file
const IERC20 = artifacts.require("IERC20");
const Arbitrage = artifacts.require("Arbitrage");
const FlashLoanProvider = artifacts.require("FlashLoanProvider");

function convertWBNBtoUSD(amountInWBNB) {
  const wbnbToUsdRate = 234.22; // 1 WBNB = $234.22
  return (amountInWBNB * +wbnbToUsdRate).toFixed(2);
}

async function displayTokenValues(liquidityPoolFactory, web3) {
  async function getTokenWorth(pool, tokenFrom, tokenTo) {
    return pool.getAmountOut(tokenFrom.address, tokenTo.address, web3.utils.toWei("1", "ether"));
  }

  const pairs = await liquidityPoolFactory.getAllPairings();
  // console.log(pairs);
  const tableData = {};

  for (const pair of pairs) {
    const poolAddress = await liquidityPoolFactory.getLiquidityPool(pair[0], pair[1]);
    const pool = await LiquidityPool.at(poolAddress);

    const token0 = await IERC20.at(pair[0]);
    const token1 = await IERC20.at(pair[1]);

    const token0Symbol = await token0.symbol();
    const token1Symbol = await token1.symbol();

    // console.log(token0Symbol, token1Symbol)

    const token0WorthInToken1 = await getTokenWorth(pool, token0, token1);
    const token1WorthInToken0 = await getTokenWorth(pool, token1, token0);

    tableData[`${token0Symbol}/${token1Symbol}`] = {
      [`Worth in ${token1Symbol}`]: web3.utils.fromWei(token0WorthInToken1.toString(), "ether") + ` ($${convertWBNBtoUSD(web3.utils.fromWei(token0WorthInToken1.toString(), "ether"))})`,
      [`Equivalent for 1 ${token1Symbol}`]: web3.utils.fromWei(token1WorthInToken0.toString(), "ether")
    };
  }

  console.table(tableData);
}

async function createDexAndLiquidity(tokenA, tokenB, wbnb, wbnbAmount, tokenAAmount, tokenBAmount, dexFactory, user) {
  console.log("Creating a Dex")
  await dexFactory.createDex();
  const len = +(await dexFactory.getDEXCount()).toString();
  // console.log("Dex count", len)
  const dexDetails = await dexFactory.dexes(len - 1);
  const dex = await Dex.at(dexDetails.dex);

  //get flashLoanProvider
  const flp = await FlashLoanProvider.at(dexDetails.flashLoanProvider);

  const liquidityPoolFactory = await LiquidityPoolFactory.at(dexDetails.liquidityPoolFactory);

  console.log("Creating liquidity pool from token pair - TokenA")
  await liquidityPoolFactory.createLiquidityPool(tokenA.address, wbnb.address);

  console.log("Creating liquidity pool from token pair - TokenB")
  await liquidityPoolFactory.createLiquidityPool(tokenB.address, wbnb.address);

  async function addLiquidityToPool(token, tokenAmount, poolFactory) {
    const symbol = await token.symbol();
    console.log(`Getting liquidity pool from token pair - ${symbol}`);
    const liquidityPoolAddress = await poolFactory.getLiquidityPool(token.address, wbnb.address);
    const liquidityPool = await LiquidityPool.at(liquidityPoolAddress);

    console.log(`Approving tokens for adding to liquidity pool - ${symbol}`);
    await token.approve(liquidityPoolAddress, web3.utils.toWei(tokenAmount.toString(), "ether"), { from: user });
    await wbnb.approve(liquidityPoolAddress, web3.utils.toWei(wbnbAmount.toString(), "ether"), { from: user });

    console.log(`Adding liquidity to liquidity pool - ${symbol}`);
    await liquidityPool.addLiquidity(web3.utils.toWei(tokenAmount.toString(), "ether"), web3.utils.toWei(wbnbAmount.toString(), "ether"), { from: user });

    const lptokens = await liquidityPool.balanceOf(user);
    console.log(`LPTokens for ${symbol}: `, web3.utils.fromWei(lptokens.toString(), "ether"));
  }

  // console.log((await wbnb.balanceOf(user)).toString())
  await addLiquidityToPool(tokenA, tokenAAmount, liquidityPoolFactory);
  // console.log((await wbnb.balanceOf(user)).toString())
  await addLiquidityToPool(tokenB, tokenBAmount, liquidityPoolFactory);

  return {
    dex: dex,
    liquidityPoolFactory: liquidityPoolFactory,
    flashLoanProvider: flp,
  };
}


const performSwap = async (dex, route, amount, user) => {
  const tokenCheck = route[route.length - 1];
  const firstToken = route[0];

  // Approve 100 Tokens for DEX
  console.log("Approving tokens for DEX");
  await firstToken.approve(dex.address, web3.utils.toWei(amount.toString(), "ether"), { from: user });

  //get before balance
  const beforeBal = await tokenCheck.balanceOf(user);

  // Swap via route
  console.log("Swapping via route")
  //create a symbol of routes
  const symbols = [];
  const addresses = [];
  for (const token of route) {
    const tokenSymbol = await token.symbol();
    addresses.push(token.address);
    symbols.push(tokenSymbol);
  }
  console.log("Route:", symbols);
  await dex.swapByRoute(addresses, web3.utils.toWei(amount.toString(), "ether"), web3.utils.toWei("0", "ether"), { from: user });

  // Check balance
  console.log(`Checking ${symbols[symbols.length - 1]} balance`);
  const balance = await tokenCheck.balanceOf(user);
  const profit = balance.sub(beforeBal);
  console.log(symbols[symbols.length - 1] + " gained: ", web3.utils.fromWei(profit.toString(), "ether"));
}


// async function testArbitrage(arbitrageContract, dex1, dex2, tokenA, tokenB, web3, user) {
async function testArbitrage(arbitrageContract, web3, user) {
  const amountToArbitrage = web3.utils.toWei("1", "ether"); // Arbitrage with 1 TokenA for simplicity
  // //Get poolA address
  // const poolAaddr = await dex1.liquidityPoolFactory.getLiquidityPool(tokenA.address, tokenB.address);
  // const poolA = await LiquidityPool.at(poolAaddr)
  // //get poolB address
  // const poolBaddr = await dex2.liquidityPoolFactory.getLiquidityPool(tokenA.address, tokenB.address);
  // const poolB = await LiquidityPool.at(poolBaddr);

  // // Fetch the prices on both DEXes
  // const priceOnDex1 = await poolA.getAmountOut(tokenA.address, tokenB.address, amountToArbitrage); // Assuming a function that gets the price
  // const priceOnDex2 = await poolB.getAmountOut(tokenA.address, tokenB.address, amountToArbitrage);

  // const tokenASymbol = await tokenA.symbol();
  // const tokenBSymbol = await tokenB.symbol();
  // console.log(`Price on DEX1: 1 ${tokenASymbol} = ${web3.utils.fromWei(priceOnDex1.toString())} ${tokenBSymbol}`);
  // console.log(`Price on DEX2: 1 ${tokenASymbol} = ${web3.utils.fromWei(priceOnDex2.toString())} ${tokenBSymbol}`);

  // let buyDex, sellDex;
  // if (priceOnDex1 > priceOnDex2) {
  //   buyDex = dex2.dex;
  //   sellDex = dex1.dex;
  // } else if (priceOnDex2 > priceOnDex1) {
  //   buyDex = dex1.dex;
  //   sellDex = dex2.dex;
  // } else {
  //   console.log("No arbitrage opportunity found.");
  //   return;
  // }

  // console.log(`Starting arbitrage: Buying on ${buyDex.address} and selling on ${sellDex.address}`);

  try {
    // Start the arbitrage
    //await arbitrageContract.startArbitrage(amountToArbitrage, { from: user });
    //call the startArbitrage function and return transaction receipt
    // function startArbitrage() {
    //   return new Promise((resolve, reject) => {
    //     arbitrageContract.startArbitrage(amountToArbitrage, { from: user })
    //       .on('transactionHash', (hash) => {
    //         console.log("Transaction hash: ", hash);
    //       })
    //       .on('receipt', (receipt) => {
    //         console.log(receipt);
    //         return resolve();
    //       })
    //       .on('error', (error) => {
    //         console.error(error);
    //         return reject();
    //       });

    //   });
    // }
    // await startArbitrage();
    // const tx = await arbitrageContract.startArbitrage.call(amountToArbitrage, { from: user });
    await arbitrageContract.startArbitrage(amountToArbitrage, { from: user });
    // console.log("Transaction hash: ", tx);
    console.log("Arbitrage successful!");
  } catch (error) {
    //get last transaction hash
    // const lastBlockNumber = await web3.eth.getBlockNumber();
    // console.log('Last block number: ', lastBlockNumber);
    // let block = await web3.eth.getBlock(lastBlockNumber);
    console.error("Arbitrage failed: ", error.message);
  }
}


module.exports = async (callback) => {
  const accounts = await web3.eth.getAccounts();
  const [deployer, user] = accounts;

  // Deploy WBNB, TokenA, TokenB
  console.log("Deploying WBNB, TokenA, TokenB")
  const wbnb = await WBNB.new();
  const tokenA = await TokenA.new({ from: user });
  const tokenB = await TokenB.new({ from: user });

  console.log(`Depositing BNB to get WBNB`)
  await wbnb.deposit({ from: user, value: web3.utils.toWei("20", "ether") });

  // console.log(wbnb.address, tokenA.address, tokenB.address)

  // Deploy DexFactory
  console.log("Creating a DexFactory")
  const dexFactory = await DexFactory.new();

  const dexA = await createDexAndLiquidity(tokenA, tokenB, wbnb, 5, 1000, 10000, dexFactory, user);

  // // single hop
  // await performSwap(dexA.dex, [tokenA, wbnb], 1, user);

  // // now try multihops
  // await performSwap(dexA.dex, [tokenA, wbnb, tokenB], 1, user);

  await displayTokenValues(dexA.liquidityPoolFactory, web3);

  const dexB = await createDexAndLiquidity(tokenA, tokenB, wbnb, 5, 900, 9500, dexFactory, user);

  // // single hop
  // await performSwap(dexB.dex, [tokenA, wbnb], 1, user);

  // // now try multihops
  // await performSwap(dexB.dex, [tokenA, wbnb, tokenB], 1, user);

  await displayTokenValues(dexB.liquidityPoolFactory, web3);

  console.log("------")

  //get flashloan provider
  const flp = dexA.flashLoanProvider;
  console.log("Creating Arbitrage")
  const arb = await Arbitrage.new(dexA.dex.address, dexB.dex.address, flp.address, wbnb.address, tokenB.address, { from: user });

  //get balance of wbnb before flashloan
  const wbnbBefore = await wbnb.balanceOf(user);
  //test the arb
  console.log("Testing arbitrage")
  await testArbitrage(arb, web3, user);
  // const profit = await wbnb.balanceOf(arb.address);
  // call withdraw to get wbnb back
  // console.log("Withdrawing tokens")
  // await arb.withdrawTokens(wbnb.address, { from: user });
  //get wbnb balance after
  const wbnbAfter = await wbnb.balanceOf(user);
  //profit
  const profit = wbnbAfter.sub(wbnbBefore);
  //check difference
  console.log("WBNB profit from flashloan: ", web3.utils.fromWei(profit.toString(), "ether"));

  callback();  // Important to ensure the script exits
};
