<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title> Add Liquidity </template>

		<div class="modal-body">
			<div class="form-group">
				<label for="tokenAAmount">{{ pool.aName }} Amount:</label>
				<input
					type="number"
					class="form-control bg-white text-dark"
					id="tokenAAmount"
					v-model="tokenAAmount"
				/>
				<span class="balance-info">Balance: {{ aBal }}</span>
			</div>
			<div class="form-group mt-3">
				<label for="tokenBAmount">{{ pool.bName }} Amount:</label>
				<input
					type="number"
					class="form-control bg-white text-dark"
					id="tokenBAmount"
					v-model="tokenBAmount"
				/>
				<span class="balance-info">Balance: {{ bBal }}</span>
			</div>
		</div>

		<template #footer>
			<button type="button" class="btn btn-secondary" @click="closeModal">
				Cancel
			</button>
			<button
				type="button"
				class="btn btn-primary"
				@click="confirmAddLiquidity"
			>
				Confirm
			</button>
		</template>
	</BaseModal>
</template>

<script>
	import BaseModal from "./BaseModal.vue"
	import { useWeb3Store } from "@/stores/web3"
	import LiquidityPool from "../../../build/contracts/LiquidityPool.json"
	import IERC20 from "../../../build/contracts/IERC20.json"

	export default {
		components: {
			BaseModal,
		},
		props: ["show", "pool"],
		data() {
			return {
				tokenAAmount: "",
				tokenBAmount: "",
				aBal: "",
				bBal: "",
				ta: null,
				tb: null,
			}
		},
		setup() {
			const web3 = useWeb3Store()
			return { web3 }
		},
		watch: {
			async show(v) {
				if (v) {
					this.tokenAAmount = ""
					this.tokenBAmount = ""

					//get balance of each token
					const web3 = this.web3.web3
					const lp = new web3.eth.Contract(
						LiquidityPool.abi,
						this.pool.contractAddress
					)

					try {
						const t0 = await lp.methods.token0().call()
						const t1 = await lp.methods.token1().call()
						this.ta = new web3.eth.Contract(IERC20.abi, t0)
						this.tb = new web3.eth.Contract(IERC20.abi, t1)

						this.aBal = await this.ta.methods
							.balanceOf(this.web3.currentAddress)
							.call()
						this.aBal = web3.utils.fromWei(this.aBal, "ether")
						this.bBal = await this.tb.methods
							.balanceOf(this.web3.currentAddress)
							.call()
						this.bBal = web3.utils.fromWei(this.bBal, "ether")
					} catch (e) {
						console.log(e)
					}
				} else {
					this.ta = null
					this.tb = null
				}
			},
		},
		methods: {
			closeModal() {
				this.$emit("close")
			},
			confirmAddLiquidity() {
				if (this.tokenAAmount === "" || this.tokenBAmount === "") {
					alert("Please enter valid amounts for both tokens")
					return
				}
				if (isNaN(this.tokenAAmount) || isNaN(this.tokenBAmount)) {
					alert("Please enter valid numeric amounts for both tokens")
					return
				}
				if (
					parseFloat(this.tokenAAmount) < 0 ||
					parseFloat(this.tokenBAmount) < 0
				) {
					console.error("Please enter positive amounts for both tokens")
					return
				}
				if (
					parseFloat(this.tokenAAmount) > parseFloat(this.aBal) ||
					parseFloat(this.tokenBAmount) > parseFloat(this.bBal)
				) {
					alert("Please enter amounts less than or equal to your balance")
					return
				}

				this.$emit(
					"confirmAddLiquidity",
					this.tokenAAmount,
					this.tokenBAmount,
					this.pool
				)
			},
		},
	}
</script>

<style lang="less" scoped>
	.balance-info {
		color: #888888; // A subtle color, you can adjust as needed
		font-size: 0.9rem;
		margin-left: 0.5rem;
	}
</style>
