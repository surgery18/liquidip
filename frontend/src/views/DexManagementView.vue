<template>
	<div>
		<!-- Navigation Bar -->
		<nav-bar @contractsLoaded="contractsLoaded" />

		<!-- Page Content -->
		<div class="content-container">
			<!-- Dex Tabs -->
			<ul class="nav nav-tabs">
				<li class="nav-item" v-for="(dex, id) in dexes" :key="dex">
					<a
						class="nav-link"
						href="#"
						@click="showDex(dex)"
						:class="{ active: isActive(dex) }"
					>
						Dex {{ id + 1 }}
					</a>
				</li>
				<li class="nav-item">
					<a class="nav-link" href="#" @click="showDexModal = true">+</a>
				</li>
			</ul>

			<div v-if="selectedDex">
				<!-- Show Dex Address -->
				<h5 class="dex-address my-2">Dex Address: {{ selectedDex.dex.dex }}</h5>

				<!-- Token Swapping Mechanism (Top Section) -->
				<token-swap
					ref="swap"
					:dex="selectedDex"
					@openTokenModal="openTokenModal"
					:tokens="tokens"
					@swapped="swapped"
				/>

				<!-- Dex Liquidity Pools (Bottom Section) -->
				<liquidity-pool-selection
					:dex="selectedDex"
					:liquidityPools="liquidityPools"
					@openAddLiquidityModal="openAddModal"
					@openCreateLiquidityModal="openCreateLiquidityModal"
					@openWithdrawModal="openWithdrawModal"
				/>
			</div>
			<div v-else>
				<div class="card mt-5 bg-white text-black">
					<div class="card-body">
						<h5 class="card-title">Select Dex</h5>
						<p class="card-text">
							Choose a Dex from the navigation bar to view its details.
						</p>
					</div>
				</div>
			</div>
		</div>

		<!-- Dex Creation Modal -->
		<dex-creation-modal
			:show="showDexModal"
			@close="closeDexModal"
			@createDex="createDex"
		/>

		<!-- Liquidity Pool Creation Modal -->
		<liquidity-pool-modal
			:show="showLiquidityModal"
			@close="closeLiquidityModal"
			@createLiquidity="createLiquidity"
		/>

		<!-- Add Liquidity Modal -->
		<add-liquidity-modal
			:show="showAddLiquidityModal"
			:pool="selectedPool"
			@close="closeAddLiquidityModal"
			@confirmAddLiquidity="confirmAddLiquidity"
		/>

		<!-- Token Selection Modal -->
		<token-selection-modal
			:show="showTokenModal"
			@close="closeTokenModal"
			@select="selectToken"
			:tokens="tokens"
		/>

		<!-- Withdraw Modal -->
		<withdraw-modal
			:show="showWithdrawModal"
			@close="closeWithdrawModal"
			:selectedPool="selectedPool"
			@confirmWithdraw="confirmWithdraw"
		/>
	</div>
</template>

<script>
	import NavBar from "@/components/NavBar.vue"
	import DexCreationModal from "@/components/DexCreationModal.vue"
	import LiquidityPoolModal from "../components/LiquidityPoolModal.vue"
	import AddLiquidityModal from "../components/AddLiquidityModal.vue"
	import TokenSelectionModal from "../components/TokenSelectionModal.vue"
	import TokenSwap from "@/components/TokenSwap.vue"
	import LiquidityPoolSelection from "@/components/LiquidityPoolSelection.vue"
	import WithdrawModal from "../components/WithdrawModal.vue"
	import { startLoading, stopLoading } from "@/utils/eventbus"
	import DEX from "../../../build/contracts/DEX.json"
	import LiquidityPoolFactory from "../../../build/contracts/LiquidityPoolFactory.json"
	import LiquidityPool from "../../../build/contracts/LiquidityPool.json"
	import IERC20 from "../../../build/contracts/IERC20.json"
	import Multicall from "../../../build/contracts/Multicall.json"
	// console.log(DEX, LiquidityPool)

	import { useWeb3Store } from "@/stores/web3"

	export default {
		components: {
			NavBar,
			DexCreationModal,
			LiquidityPoolModal,
			AddLiquidityModal,
			TokenSelectionModal,
			TokenSwap,
			LiquidityPoolSelection,
			WithdrawModal,
		},
		data() {
			return {
				dexes: [],
				showDexModal: false,
				showLiquidityModal: false,
				showAddLiquidityModal: false,
				showTokenModal: false,
				showWithdrawModal: false,
				selectedDex: null,
				liquidityPools: [],
				tokens: [],
				selectedPool: null, // To store the selected liquidity pool
				tokenDir: "",
			}
		},
		setup() {
			const web3 = useWeb3Store()
			return { web3, startLoading, stopLoading }
		},
		methods: {
			isActive(dex) {
				// console.log(this.selectedDex, dex)
				return this.selectedDex?.dex?.dex === dex.dex
			},
			swapped() {
				this.showDex(this.selectedDex.dex)
			},
			async contractsLoaded() {
				try {
					const count = await this.web3.dexFactory.methods.getDEXCount().call()
					// console.log(count)
					this.dexes = []
					if (count > 0) {
						for (let i = 0; i < count; i++) {
							const dex = await this.web3.dexFactory.methods
								.getDEXDetails(i)
								.call()
							this.dexes.push(dex)
						}
					}
				} catch (e) {
					console.log(e)
				}
				// console.log(this.dexes)
			},
			async createDex(dex) {
				const df = this.web3.dexFactory
				if (!df) alert("Contract not loaded yet")
				startLoading()
				try {
					const tx = await df.methods
						.createDex()
						.send({ from: this.web3.currentAddress })
					console.log(tx)
					const event = tx.events.DEXCreated
					const rv = event.returnValues
					this.dexes.push({
						dex: rv.dex,
						flashLoanProvider: rv.flashLoanProvider,
						liquidityPoolFactory: rv.liquidityPoolFactory,
					})
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				this.closeDexModal()
			},
			async showDex(dex) {
				this.liquidityPools = []
				//fetch entire liquidity pool from blockchain
				//first load up contract
				const web3 = this.web3.web3
				const dexc = new web3.eth.Contract(DEX.abi, dex.dex)
				const lpf = new web3.eth.Contract(
					LiquidityPoolFactory.abi,
					dex.liquidityPoolFactory
				)
				//next fetch the pool
				try {
					//if this function runs out of gas then we will need to switch it to a for loop and get each one as its own call
					//so for now quick and dirty
					const pools = await lpf.methods.getAllPools().call()
					// console.log(pools)
					//load details
					for (const pool of pools) {
						const details = await this.getPoolDetails(pool)
						// console.log(details)
						this.liquidityPools.push(details)
					}
				} catch (e) {
					console.log(e)
				}
				this.selectedDex = {
					dex,
					dexContract: dexc,
					liquidityPoolFactory: lpf,
				}
				await this.getTokens(dex.liquidityPoolFactory)
			},
			async createLiquidity(tokena, tokenb) {
				const web3 = this.web3.web3
				const lpf = this.selectedDex.liquidityPoolFactory
				console.log(tokena, tokenb)
				startLoading()
				try {
					const tx = await lpf.methods
						.createLiquidityPool(tokena, tokenb)
						.send({ from: this.web3.currentAddress })
					console.log(tx)
					const event = tx.events.LiquidityPoolCreated
					const rv = event.returnValues
					const details = await this.getPoolDetails(rv.pool)
					this.liquidityPools.push(details)
					this.closeLiquidityModal()
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				await this.getTokens(this.selectedDex.dex.liquidityPoolFactory)
			},
			async confirmAddLiquidity(amountA, amountB, pool) {
				const web3 = this.web3.web3
				const p = new web3.eth.Contract(LiquidityPool.abi, pool.contractAddress)
				startLoading()
				try {
					const t0 = await p.methods.token0().call()
					const t1 = await p.methods.token1().call()

					const ta = new web3.eth.Contract(IERC20.abi, t0)
					const tb = new web3.eth.Contract(IERC20.abi, t1)

					//TODO ONLY CALL APPROVE IF NEEDED

					const aAllowance = await ta.methods
						.allowance(this.web3.currentAddress, pool.contractAddress)
						.call()
					const aA = +web3.utils.fromWei(aAllowance, "ether")
					if (aA < +amountA) {
						await ta.methods
							.approve(
								pool.contractAddress,
								web3.utils.toWei(amountA.toString(), "ether")
							)
							.send({ from: this.web3.currentAddress })
					}

					const bAllowance = await tb.methods
						.allowance(this.web3.currentAddress, pool.contractAddress)
						.call()
					const aB = +web3.utils.fromWei(bAllowance, "ether")
					if (aB < +amountB) {
						await tb.methods
							.approve(
								pool.contractAddress,
								web3.utils.toWei(amountB.toString(), "ether")
							)
							.send({ from: this.web3.currentAddress })
					}

					// .encodeABI()

					// const mc = new web3.eth.Contract(
					// 	Multicall.abi,
					// 	Multicall.networks[this.web3.networkId].address
					// )
					// const callme = []
					// if (amountA > 0) {
					// 	callme.push({
					// 		target: ta._address,
					// 		data: a,
					// 	})
					// }
					// if (amountB > 0) {
					// 	callme.push({
					// 		target: tb._address,
					// 		data: b,
					// 	})
					// }

					// let tx = await mc.methods
					// 	.aggregate(callme)
					// 	.send({ from: this.web3.currentAddress })
					// console.log(tx)

					const tx = await p.methods
						.addLiquidity(
							web3.utils.toWei(amountA.toString(), "ether"),
							web3.utils.toWei(amountB.toString(), "ether")
						)
						.send({ from: this.web3.currentAddress })
					console.log(tx)

					const np = await this.getPoolDetails(pool.contractAddress)
					//replace the object in the liquidity pools with new info
					const index = this.liquidityPools.findIndex(
						(p) => p.contractAddress === pool.contractAddress
					)
					if (index > -1) {
						this.liquidityPools[index] = { ...np }
					}
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				this.closeAddLiquidityModal()
			},
			async confirmWithdraw(amount) {
				const web3 = this.web3.web3
				startLoading()
				try {
					const lp = new web3.eth.Contract(
						LiquidityPool.abi,
						this.selectedPool.contractAddress
					)
					const tx = await lp.methods
						.removeLiquidity(web3.utils.toWei(amount.toString(), "ether"))
						.send({ from: this.web3.currentAddress })
					console.log(tx)

					const np = await this.getPoolDetails(
						this.selectedPool.contractAddress
					)
					//replace the object in the liquidity pools with new info
					const index = this.liquidityPools.findIndex(
						(p) => p.contractAddress === this.selectedPool.contractAddress
					)
					if (index > -1) {
						this.liquidityPools[index] = { ...np }
					}
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				this.closeWithdrawModal()
			},

			closeWithdrawModal() {
				this.selectedPool = null
				this.showWithdrawModal = false
			},
			openWithdrawModal(pool) {
				this.showWithdrawModal = true
				this.selectedPool = pool
			},
			openCreateLiquidityModal() {
				this.showLiquidityModal = true
			},
			openAddModal(pool) {
				this.showAddLiquidityModal = true
				this.selectedPool = pool
			},
			openTokenModal(dir) {
				this.showTokenModal = true
				this.tokenDir = dir
			},
			selectToken(token) {
				this.$refs.swap.confirmToken(token, this.tokenDir)
				this.tokenDir = ""
			},
			closeDexModal() {
				this.showDexModal = false
			},
			closeLiquidityModal() {
				this.showLiquidityModal = false
			},
			closeAddLiquidityModal() {
				this.showAddLiquidityModal = false
				this.selectedPool = null
			},
			closeTokenModal() {
				this.showTokenModal = false
				this.tokenDir = ""
			},
			async getPoolDetails(addr) {
				const web3 = this.web3.web3
				const lp = new web3.eth.Contract(LiquidityPool.abi, addr)
				const details = await lp.methods.getPoolDetails().call()
				return {
					contractAddress: addr,
					aName: details[0],
					aSymbol: details[1],
					aBal: web3.utils.fromWei(details[2], "ether"),
					bName: details[3],
					bSymbol: details[4],
					bBal: web3.utils.fromWei(details[5], "ether"),
				}
			},
			async getTokens(lpfAddr) {
				// this.tokens = []
				const web3 = this.web3.web3
				// const lpf = dex.liquidityPoolFactory
				const lpf = new web3.eth.Contract(LiquidityPoolFactory.abi, lpfAddr)
				// console.log(dex)
				//for simplicity for now
				const tokens = await lpf.methods.getAllTokens().call()
				const atokens = []
				for (const token of tokens) {
					//get the token details
					//name and symbol
					const t = new web3.eth.Contract(IERC20.abi, token)
					const name = await t.methods.name().call()
					const symbol = await t.methods.symbol().call()
					atokens.push({ address: token, name, symbol })
				}
				this.tokens = [...atokens]
				// console.log(this.tokens)
			},
		},
	}
</script>

<style lang="less" scoped>
	@import url("@/assets/colors.less");

	// Styling for text boxes and dropdowns
	select,
	input[type="text"] {
		background-color: @light-bg-color;
		border: 1px solid @light-border-color;
		color: @dark-text-color;
	}

	// Global container
	.content-container {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem 1rem;
	}
</style>
