<template>
	<div class="card arb-card" :class="{ profitable: arb.profitable }">
		<div class="card-body">
			<h5 class="card-title">
				Arbitrage for {{ arb.token0.symbol }} / {{ arb.token1.symbol }}
			</h5>
			<p class="card-subtitle mb-2 text-muted">
				From: {{ shortAddress(arb.dexA) }} | To:
				{{ shortAddress(arb.dexB) }}
			</p>
			<p class="card-text">Profitable: {{ arb.profitable ? "Yes" : "No" }}</p>
			<span>Estimated Profits</span>
			<div class="card-text">
				<div>{{ arb.token0.symbol }}: {{ arb.estimatedProfit }}</div>
				<div>USD: ${{ usd }}</div>
				<div v-if="!enoughInLP(arb)" class="text-danger">
					Not enough tokens in LP
				</div>
			</div>
			<div class="mb-3">
				<label for="borrowAmount" class="form-label">Borrow Amount</label>
				<input
					type="number"
					class="form-control"
					id="borrowAmount"
					v-model="borrowAmount"
				/>
			</div>
			<button
				class="btn btn-primary"
				@click="executeArbitrage"
				:disabled="isDisabled(arb)"
			>
				Execute
			</button>
		</div>
	</div>
</template>

<script>
	import { useWeb3Store } from "@/stores/web3"
	import DEX from "../../../build/contracts/DEX"
	import WBNB from "../../../build/contracts/WBNB.json"
	import PriceConsumerV3 from "../../../build/contracts/PriceConsumerV3.json"

	export default {
		props: {
			arb: {
				type: Object,
				required: true,
			},
			id: Number,
		},
		data() {
			return {
				borrowAmount: 0.01,
				usd: "0.00",
			}
		},
		setup() {
			return { web3: useWeb3Store() }
		},
		watch: {
			borrowAmount(v) {
				this.$emit("borrowedAmount", v, this.id)
			},
			arb: {
				handler(v) {
					if (v) {
						this.convertToUSD()
					}
				},
				immediate: true,
				deep: true,
			},
		},
		methods: {
			isDisabled(arb) {
				// console.log(arb.profitable, arb.canTake, arb.enoughToBorrow)
				return !arb.profitable || !this.enoughInLP(arb)
			},
			enoughInLP(arb) {
				return arb.canTake && arb.enoughToBorrow
			},
			shortAddress(addr) {
				if (!addr) return ""
				return addr.slice(0, 6) + "..." + addr.slice(-4)
			},
			executeArbitrage() {
				this.$emit("execute", this.borrowAmount, this.id)
			},
			async convertToUSD() {
				const web3 = this.web3.web3
				const nid = this.web3.networkId
				const pc = new web3.eth.Contract(
					PriceConsumerV3.abi,
					PriceConsumerV3.networks[nid].address
				)
				const priceWei = await pc.methods.getLatestData().call()
				const price = +priceWei / 10 ** 8

				if (+this.borrowAmount > 0) {
					// //convert to WBNB and get the expect output
					const nid = this.web3.networkId
					const dex = new web3.eth.Contract(DEX.abi, this.arb.dexB)
					if (this.arb.token0.symbol === "WBNB") {
						this.usd = (price * +this.arb.estimatedProfit).toFixed(2)
					} else {
						//we need to figure out the profit from that token to WBNB
						const route = [this.arb.token0.address, WBNB.networks[nid].address]
						const dir = this.arb.estimatedProfit < 0 ? -1 : 1
						const eo = await dex.methods
							.estimateOutput(
								route,
								web3.utils.toWei(
									(this.arb.estimatedProfit * dir).toString(),
									"ether"
								)
							)
							.call()
						const output = web3.utils.fromWei(eo, "ether")
						// console.log(output)
						// console.log(price, output)
						this.usd = (price * +output * dir).toFixed(2)
					}
				} else {
					this.usd = "0.00"
				}
			},
		},
	}
</script>

<style scoped>
	.arb-card {
		margin-bottom: 20px;
		background-color: #333; /* Dark background for the card */
		color: #f5f5f5; /* Light text color for readability */
		border: 1px solid #444; /* Slight border for definition */
		border-radius: 5px; /* Rounded edges for the card */
		padding: 15px; /* Inner padding for content spacing */
	}

	.profitable {
		background-color: green;
		color: white;
	}
</style>
