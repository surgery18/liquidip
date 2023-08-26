<template>
	<div class="token-swap-section">
		<div class="swap-card">
			<!-- You Pay Token Input Box -->
			<div class="token-input-box">
				<div class="input-wrapper">
					<span class="label-text">You Pay</span>
					<input
						class="amount-input"
						type="text"
						placeholder="0.0"
						v-model="payAmount"
					/>
					<span class="usd-amount">${{ usdSwapFrom }}</span>
				</div>
				<div
					class="token-symbol-content text-end"
					@click="openTokenModal('from')"
				>
					<span class="balance-display"> Balance: {{ balanceSwapFrom }} </span>
					<span
						class="token-symbol"
						v-text="swapFrom.symbol"
						v-if="swapFrom.symbol"
					></span>
					<span class="token-symbol" v-else>Select Token</span>
					<span class="token-dropdown-icon bi bi-chevron-down"></span>
				</div>
			</div>

			<!-- Swap Icon -->
			<div class="d-flex justify-content-center">
				<span class="bi bi-arrow-down-up swap-icon" @click="swapTokens"></span>
			</div>

			<!-- You Receive Token Input Box -->
			<div class="token-input-box">
				<div class="input-wrapper">
					<span class="label-text">You Receive</span>
					<input
						class="amount-input"
						type="text"
						placeholder="0.0"
						v-model="receiveAmount"
						readonly
					/>
					<span class="usd-amount">${{ usdSwapTo }}</span>
				</div>
				<div
					class="token-symbol-content text-end"
					@click="openTokenModal('to')"
				>
					<span class="balance-display"> Balance: {{ balanceSwapTo }} </span>
					<span
						class="token-symbol"
						v-text="swapTo.symbol"
						v-if="swapTo.symbol"
					></span>
					<span class="token-symbol" v-else>Select Token</span>
					<span class="token-dropdown-icon bi bi-chevron-down"></span>
				</div>
			</div>
			<small class="token-rate" v-if="swapFrom.symbol && swapTo.symbol"
				>1 {{ swapFrom.symbol }} = {{ oneToOne }} {{ swapTo.symbol }}</small
			>

			<!-- Swap Button -->
			<button class="btn-swap" @click="swap" v-text="btnText"></button>
		</div>
	</div>
</template>

<script>
	import { startLoading, stopLoading } from "@/utils/eventbus"
	import { useWeb3Store } from "@/stores/web3"
	// import LiquidityPool from "../../../build/contracts/LiquidityPool.json"
	import IERC20 from "../../../build/contracts/IERC20.json"
	export default {
		name: "TokenSwap",
		props: {
			dex: {
				type: Object,
				required: true,
			},
			tokens: {
				type: Array,
				required: true,
				default: [],
			},
		},
		data() {
			return {
				swapFrom: { symbol: "" },
				swapTo: { symbol: "" },
				payAmount: "",
				receiveAmount: "",
				oneToOne: 0,
				balanceSwapFrom: 0,
				balanceSwapTo: 0,
				usdSwapFrom: "0.00",
				usdSwapTo: "0.00",
				btnText: "Swap",
			}
		},
		setup() {
			const web3 = useWeb3Store()
			return { web3, startLoading, stopLoading }
		},
		// mounted() {
		// 	console.log("len", this.tokens.length)
		// 	this.swapFrom = { ...this.tokens?.[0] } ?? { symbol: "" }
		// },
		watch: {
			tokens: {
				handler(v) {
					if (v.length > 0) {
						this.swapFrom = { ...v[0] }
						this.getBalances()
					}
				},
				immediate: true,
			},
			async payAmount(newVal) {
				// if (!this.swapTo.symbol) {
				// 	this.payAmount = ""
				// 	return
				// }
				await this.getBtnText()
				if (newVal === "" || +newVal === 0) {
					this.receiveAmount = ""
					return
				}
				this.receiveAmount = await this.getOutputTokens(
					this.swapFrom,
					this.swapTo,
					newVal
				)
			},
			// async receiveAmount(newVal) {
			// 	// if (!this.swapFrom.symbol) {
			// 	// 	this.receiveAmount = ""
			// 	// 	return
			// 	// }
			// 	this.payAmount = await this.getOutputTokens(
			// 		this.swapTo,
			// 		this.swapFrom,
			// 		newVal
			// 	)
			// },
		},
		methods: {
			async swap() {
				if (!this.swapTo.symbol || !this.swapFrom.symbol) {
					alert("Must select tokens in both fields")
					return
				}

				if (this.swapTo.symbol === this.swapFrom.symbol) {
					alert("Cannot be the same token")
					return
				}

				if (!this.payAmount || +this.payAmount < 0 || isNaN(this.payAmount)) {
					alert("Please fill out a proper pay amount")
					return
				}
				if (+this.payAmount > +this.balanceSwapFrom) {
					alert("Cannot put more than your balance")
					return
				}

				//get the route
				const web3 = this.web3.web3
				const dex = this.dex.dexContract
				const lpf = this.dex.liquidityPoolFactory
				const route = await dex.methods
					.getRoute(this.swapFrom.address, this.swapTo.address)
					.call()

				//get the pool from the route
				const pair = route.slice(-2)
				const pool = await lpf.methods.getLiquidityPool(pair[0], pair[1]).call()

				//get balance of pool of token
				const token = new web3.eth.Contract(IERC20.abi, this.swapTo.address)
				const balWei = await token.methods.balanceOf(pool).call()
				const bal = web3.utils.fromWei(balWei, "ether")

				if (+this.receiveAmount > +bal) {
					alert("Not enough tokens in the pool to swap to it")
					return
				}

				startLoading()
				try {
					//approve token to pool
					const pa = web3.utils.toWei(this.payAmount, "ether")
					const ra = web3.utils.toWei(this.receiveAmount, "ether")
					let tx
					const aeth = await this.getAllowance()
					//only give the approval if needed
					if (+aeth == 0 || +aeth < +this.payAmount) {
						const ftoken = new web3.eth.Contract(
							IERC20.abi,
							this.swapFrom.address
						)
						const dexAddr = this.dex.dex.dex
						tx = await ftoken.methods
							.approve(dexAddr, pa)
							.send({ from: this.web3.currentAddress })
						console.log(tx)
					}
					//perform swap
					tx = await dex.methods
						.swapByRoute(route, pa, ra)
						.send({ from: this.web3.currentAddress })
					console.log(tx)
					//update balances
					await this.getBalances()
					//update usd amount
					await this.getUSDAmounts()

					this.payAmount = ""
					this.$emit("swapped")
				} catch (e) {
					console.log(e)
				}
				stopLoading()
			},
			async getUSDAmounts() {},
			async getBalances() {
				const web3 = this.web3.web3
				if (this.swapFrom.address) {
					const token = new web3.eth.Contract(IERC20.abi, this.swapFrom.address)
					const bal = await token.methods
						.balanceOf(this.web3.currentAddress)
						.call()
					this.balanceSwapFrom = web3.utils.fromWei(bal, "ether")
				} else {
					this.balanceSwapFrom = 0
				}

				if (this.swapTo.address) {
					const token = new web3.eth.Contract(IERC20.abi, this.swapTo.address)
					const bal = await token.methods
						.balanceOf(this.web3.currentAddress)
						.call()
					this.balanceSwapTo = web3.utils.fromWei(bal, "ether")
				} else {
					this.balanceSwapTo = 0
				}
			},
			async calcOnetoOne() {
				if (this.swapFrom.symbol && this.swapTo.symbol) {
					const out = await this.getOutputTokens(
						this.swapFrom,
						this.swapTo,
						"1"
					)
					this.oneToOne = out
					return
				}
				this.oneToOne = 0
			},
			async swapTokens() {
				const temp = this.swapFrom
				this.swapFrom = { ...this.swapTo }
				this.swapTo = { ...temp }

				if (+this.payAmount > 0) {
					this.receiveAmount = await this.getOutputTokens(
						this.swapFrom,
						this.swapTo,
						this.payAmount
					)
				}
				await this.calcOnetoOne()
				await this.getBtnText()
			},
			openTokenModal(dir) {
				// Logic to open the token modal
				// This will probably involve emitting an event to the parent to handle
				this.$emit("openTokenModal", dir)
			},
			async confirmToken(token, dir) {
				if (dir === "to") {
					this.swapTo = { ...token }
				} else {
					this.swapFrom = { ...token }
					await this.getBtnText()
				}
				if (+this.payAmount > 0) {
					this.receiveAmount = await this.getOutputTokens(
						this.swapFrom,
						this.swapTo,
						this.payAmount
					)
				}
				await this.calcOnetoOne()
				await this.getBalances()
			},
			async getOutputTokens(a, b, amountIn) {
				if (!a.symbol || !b.symbol) {
					return 0
				}
				const web3 = this.web3.web3
				const dex = this.dex.dexContract

				//calc route
				const route = await dex.methods.getRoute(a.address, b.address).call()
				// console.log(route)
				const ao = await dex.methods
					.estimateOutput(route, web3.utils.toWei(amountIn.toString(), "ether"))
					.call()
				const amount = web3.utils.fromWei(ao, "ether")
				return amount
			},
			async getBtnText() {
				if (!this.swapFrom.symbol) {
					this.btnText = "Swap"
					return
				}
				if (!this.payAmount || isNaN(this.payAmount) || +this.payAmount == 0) {
					this.btnText = "Swap"
					return
				}

				//only give the approval if needed
				const web3 = this.web3.web3
				const pa = web3.utils.toWei(this.payAmount, "ether")
				const aeth = await this.getAllowance()
				if (+aeth == 0 || +aeth < +this.payAmount) {
					this.btnText = "Approve & Swap"
				} else {
					this.btnText = "Swap"
				}
			},
			async getAllowance() {
				const web3 = this.web3.web3
				const dexAddr = this.dex.dex.dex
				const ftoken = new web3.eth.Contract(IERC20.abi, this.swapFrom.address)
				const allowance = await ftoken.methods
					.allowance(this.web3.currentAddress, dexAddr)
					.call()
				const aeth = web3.utils.fromWei(allowance, "ether")
				return aeth
			},
		},
	}
</script>

<style lang="less" scoped>
	@import url("@/assets/colors.less");

	// Token Swapping Section
	.token-swap-section {
		display: flex;
		justify-content: center;
		color: @dark-text-color;

		.swap-card {
			width: 100%;
			max-width: 500px;
			background-color: @light-bg-color;
			padding: 1rem;
			border-radius: 10px;
			box-shadow: 0 4px 6px @dark-shadow;
			margin-top: 2rem;

			// Token Input Box Styling
			.token-input-box {
				display: flex;
				align-items: center;
				position: relative;
				padding: 0.5rem;
				// margin-bottom: 1rem;
				border: 1px solid @light-border-color;
				border-radius: 5px;

				.input-wrapper {
					flex: 1;
					display: flex;
					flex-direction: column;
					align-items: start; // Aligns items to the left
					padding: 0rem 1rem; // Adjust the padding as per requirement

					.label-text {
						font-size: 0.9rem; // Adjust font size
						margin-bottom: 0.2rem; // Reduces space below the label
					}

					.amount-input {
						width: 100%;
						// padding: 0.5rem 0.75rem; // Adjust padding
						font-size: 1.2rem; // Adjust font size
						// margin-bottom: 0.2rem; // Reduces space below the input
						border: none; // Removes the border
						outline: none; // Removes the outline
						background: transparent; // Makes the background transparent
						color: @dark-text-color;
					}

					.usd-amount {
						font-size: 0.8rem; // Adjust font size
					}
				}

				.token-symbol-content {
					cursor: pointer;

					.balance-display {
						display: block;
						font-size: 0.8rem;
						margin-bottom: 0.5rem;
						color: #888;
					}

					.token-symbol {
						margin-right: 0.5rem;
						background-color: orange;
						padding: 10px;
						border-radius: 10px;
						color: white;
					}
				}
			}

			.swap-icon-container {
				display: flex;
				align-items: center;
				justify-content: center;
				margin: 0.5rem 0; // Adjust the vertical spacing
			}

			.swap-icon {
				font-size: 1.5rem; // Adjust size
				cursor: pointer;
				margin: 0; // Remove margin to reduce spacing
			}

			// Token Rate Styling
			.token-rate {
				text-align: center;
				color: #888;
			}

			// Swap Button Styling
			.btn-swap {
				width: 100%;
				padding: 1rem 1.5rem;
				background-color: @primary-blue;
				border: none;
				color: @light-bg-color;
				font-size: 1rem;
				border-radius: 5px;
				cursor: pointer;
				transition: background-color 0.3s;
				margin-top: 2rem;

				&:hover {
					background-color: @hover-blue;
				}
			}
		}
	}
</style>
