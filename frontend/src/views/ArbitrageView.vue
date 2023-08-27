<!-- ArbitrageView.vue -->
<template>
	<div>
		<!-- Using NavBar component -->
		<NavBar @contractsLoaded="contractsLoaded" />

		<!-- Container for the content -->
		<div class="container" v-if="web3.currentAddress">
			<!-- Button to open create arbitrage dialog -->
			<button @click="openCreateArbitrage">Create Arbitrage</button>

			<!-- Arbitrage Grid -->
			<div class="arbitrage-grid mt-5">
				<ArbitrageCard
					v-for="(arb, id) in arbitrages"
					:key="id"
					:arb="arb"
					:id="id"
					@execute="executeArbitrage"
					@borrowedAmount="onBorrowedAmount"
				/>
			</div>
		</div>

		<wallet-connect-prompt @connected="onConnect" />

		<!-- Create Arbitrage Dialog -->
		<CreateArbitrageDialog
			ref="arbModal"
			:show="showCreateArbitrage"
			@unhide="openCreateArbitrage"
			@close="closeCreateArbModal"
			@hide="hideCreateArbModal"
			@onSelectDexA="onSelectDexA"
			:tokens="tokens"
		/>

		<token-selection-modal
			:show="showTokenSelectionModal"
			:tokens="tokens"
			@close="openCreateArbitrage"
			@select="selectToken"
		/>
	</div>
</template>

<script>
	import NavBar from "@/components/NavBar.vue"
	import CreateArbitrageDialog from "@/components/CreateArbitrageDialog.vue"
	import ArbitrageCard from "@/components/ArbitrageCard.vue"
	import TokenSelectionModal from "../components/TokenSelectionModal.vue"
	import { useWeb3Store } from "@/stores/web3"
	import LiquidityPoolFactory from "../../../build/contracts/LiquidityPoolFactory.json"
	import IERC20 from "../../../build/contracts/IERC20.json"
	import ArbitrageFactory from "../../../build/contracts/ArbitrageFactory.json"
	import Arbitrage from "../../../build/contracts/Arbitrage.json"
	import DEX from "../../../build/contracts/DEX.json"
	import { startLoading, stopLoading } from "@/utils/eventbus"
	import WalletConnectPrompt from "@/components/WalletConnectPrompt.vue"

	export default {
		components: {
			NavBar,
			CreateArbitrageDialog,
			ArbitrageCard,
			TokenSelectionModal,
			WalletConnectPrompt,
		},
		data() {
			return {
				showCreateArbitrage: false,
				showTokenSelectionModal: false,
				arbitrages: [], // This will be fetched from your backend or contract
				tokens: [],
			}
		},
		setup() {
			return { web3: useWeb3Store(), startLoading, stopLoading }
		},
		methods: {
			async contractsLoaded() {
				this.fetchArbitrages()
				// setInterval(this.fetchArbitrages, 60000) // Refresh every minute
			},
			onConnect() {
				this.fetchArbitrages()
			},
			async onBorrowedAmount(amount, id) {
				const arb = this.arbitrages[id]
				if (amount <= 0) {
					this.arbitrages[id] = {
						...arb,
						profitable: false,
						estimatedProfit: 0,
					}
					return
				}
				const newAmount = await this.web3.calcProfits(
					arb.dexA,
					arb.dexB,
					arb.token0.address,
					arb.token1.address,
					amount
				)
				this.arbitrages[id] = {
					...arb,
					profitable: newAmount.profitable,
					estimatedProfit: newAmount.estimatedProfit,
				}
			},
			async onSelectDexA(dex) {
				this.tokens = []
				if (!dex?.liquidityPoolFactory) return

				const web3 = this.web3.web3
				// const lpf = dex.liquidityPoolFactory
				const lpf = new web3.eth.Contract(
					LiquidityPoolFactory.abi,
					dex.liquidityPoolFactory
				)
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
					if (symbol !== "PANGO") {
						atokens.push({ address: token, name, symbol })
					}
				}
				this.tokens = [...atokens]
				// console.log(this.tokens)
			},
			async fetchArbitrages() {
				this.arbitrages = []
				// Fetch the list of arbitrages and set it to the arbitrages data property
				if (!this.web3) return
				const web3 = this.web3.web3
				const nid = this.web3.networkId
				const arbf = new web3.eth.Contract(
					ArbitrageFactory.abi,
					ArbitrageFactory.networks[nid].address
				)
				const arbs = await arbf.methods
					.getUserArbitrages(this.web3.currentAddress)
					.call()

				//loop through each arb and create json for arb card
				for (const arb of arbs) {
					const ac = new web3.eth.Contract(Arbitrage.abi, arb)
					const da = await ac.methods.dexA().call()
					const db = await ac.methods.dexB().call()
					const t0 = await ac.methods.token0().call()
					const t1 = await ac.methods.token1().call()

					const t0c = new web3.eth.Contract(IERC20.abi, t0)
					const t1c = new web3.eth.Contract(IERC20.abi, t1)

					const t0s = await t0c.methods.symbol().call()
					const t1s = await t1c.methods.symbol().call()

					const profitData = await this.web3.calcProfits(da, db, t0, t1, 0.1)

					const data = {
						address: arb,
						dexA: da,
						dexB: db,
						token0: {
							address: t0,
							symbol: t0s,
						},
						token1: {
							address: t1,
							symbol: t1s,
						},
						estimatedProfit: profitData.estimatedProfit,
						profitable: profitData.profitable,
					}
					this.arbitrages.push(data)
				}
			},
			async executeArbitrage(borrowAmount, id) {
				const arb = this.arbitrages[id]
				const web3 = this.web3.web3
				startLoading()
				try {
					const arbc = new web3.eth.Contract(Arbitrage.abi, arb.address)
					const tx = await arbc.methods
						.startArbitrage(web3.utils.toWei(borrowAmount.toString(), "ether"))
						.send({ from: this.web3.currentAddress })
					console.log(tx)
				} catch (e) {
					console.log(e)
				}
				stopLoading()
				await this.fetchArbitrages()
			},
			closeCreateArbModal() {
				this.showCreateArbitrage = false
				this.tokens = []
				this.fetchArbitrages()
			},
			hideCreateArbModal() {
				this.showCreateArbitrage = false
				this.showTokenSelectionModal = true
			},
			openCreateArbitrage() {
				this.showCreateArbitrage = true
				this.showTokenSelectionModal = false
			},
			selectToken(token) {
				this.$refs.arbModal.selectToken(token)
				this.openCreateArbitrage()
			},
		},
	}
</script>

<style scoped>
	.container {
		max-width: 1200px;
		margin: 0 auto;
		padding: 20px;
	}

	.arbitrage-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 20px;
	}
</style>
