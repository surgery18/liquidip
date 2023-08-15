<template>
	<div class="container mt-5">
		<!-- Title -->
		<h2>Manage Liquidity Pools</h2>

		<!-- Select DEX -->
		<div class="mb-3">
			<label for="dexSelect" class="form-label">Select DEX</label>
			<select
				class="form-select"
				id="dexSelect"
				v-model="selectedDex"
				@change="loadPoolFactory"
			>
				<option v-for="dex in dexes" :key="dex.address" :value="dex.address">
					{{ dex.name }}
				</option>
			</select>
		</div>

		<!-- Display Pools for Selected DEX -->
		<div v-if="selectedDex && pairings.length">
			<h4>Available Pairs:</h4>
			<ul>
				<li v-for="(pair, index) in pairings" :key="index">
					{{ pair.tokenA }} / {{ pair.tokenB }}
				</li>
			</ul>
		</div>

		<!-- Liquidity Management -->
		<div v-if="selectedDex">
			<h4>Liquidity Management</h4>
			<p>Here you can add and remove liquidity for the selected DEX</p>

			<!-- Add Liquidity -->
			<div class="liquidity-section">
				<h5>Add Liquidity</h5>
				<div class="form-group">
					<label for="addTokenA">Token A Amount:</label>
					<input
						type="number"
						id="addTokenA"
						v-model="addLiquidityTokenA"
						class="form-control"
					/>
				</div>
				<div class="form-group">
					<label for="addTokenB">Token B Amount:</label>
					<input
						type="number"
						id="addTokenB"
						v-model="addLiquidityTokenB"
						class="form-control"
					/>
				</div>
				<button @click="addLiquidity" class="btn btn-primary">
					Add Liquidity
				</button>
			</div>

			<!-- Remove Liquidity -->
			<div class="liquidity-section mt-4">
				<h5>Remove Liquidity</h5>
				<div class="form-group">
					<label for="removeLiquidityAmount">LP Tokens to Burn:</label>
					<input
						type="number"
						id="removeLiquidityAmount"
						v-model="removeLiquidityAmount"
						class="form-control"
					/>
				</div>
				<button @click="removeLiquidity" class="btn btn-danger">
					Remove Liquidity
				</button>
			</div>
		</div>
	</div>
</template>

<script>
	import Web3 from "web3"

	export default {
		data() {
			return {
				web3: null,
				account: null,
				dexFactoryContract: null,
				poolFactoryContract: null,
				selectedDex: null,
				dexes: [],
				pairings: [],
				addLiquidityTokenA: 0,
				addLiquidityTokenB: 0,
				removeLiquidityAmount: 0,
			}
		},
		async created() {
			if (window.ethereum) {
				this.web3 = new Web3(window.ethereum)
				await window.ethereum.request({ method: "eth_requestAccounts" })
				this.account = (await this.web3.eth.getAccounts())[0]
			} else if (window.web3) {
				this.web3 = new Web3(window.web3.currentProvider)
				this.account = (await this.web3.eth.getAccounts())[0]
			} else {
				console.error("No Ethereum provider detected")
				return
			}
			this.dexFactoryContract = new this.web3.eth.Contract(
				YOUR_DEX_FACTORY_ABI,
				YOUR_DEX_FACTORY_ADDRESS
			)
			this.loadDexes()
		},
		methods: {
			async loadDexes() {
				this.dexes = await this.dexFactoryContract.methods
					.getAllDexes()
					.call({ from: this.account })
			},
			async loadPoolFactory() {
				let poolFactoryAddress = await this.dexFactoryContract.methods
					.getPoolFactory(this.selectedDex)
					.call({ from: this.account })
				this.poolFactoryContract = new this.web3.eth.Contract(
					YOUR_POOL_FACTORY_ABI,
					poolFactoryAddress
				)
				this.loadPairings()
			},
			async loadPairings() {
				this.pairings = await this.poolFactoryContract.methods
					.getAllPairings()
					.call({ from: this.account })
			},
			async addLiquidity() {
				try {
					// Assuming the addLiquidity function in your smart contract requires the amount of both tokens to be added
					const receipt = await this.poolFactoryContract.methods
						.addLiquidity(this.addLiquidityTokenA, this.addLiquidityTokenB)
						.send({ from: this.account })

					if (receipt.status) {
						console.log("Liquidity added successfully")
						// Optionally reset the input values
						this.addLiquidityTokenA = 0
						this.addLiquidityTokenB = 0
					} else {
						console.error("Transaction failed")
					}
				} catch (error) {
					console.error(
						"An error occurred while adding liquidity",
						error.message
					)
				}
			},

			async removeLiquidity() {
				try {
					// Assuming the removeLiquidity function in your smart contract requires the amount of LP tokens to be burnt
					const receipt = await this.poolFactoryContract.methods
						.removeLiquidity(this.removeLiquidityAmount)
						.send({ from: this.account })

					if (receipt.status) {
						console.log("Liquidity removed successfully")
						// Optionally reset the input value
						this.removeLiquidityAmount = 0
					} else {
						console.error("Transaction failed")
					}
				} catch (error) {
					console.error(
						"An error occurred while removing liquidity",
						error.message
					)
				}
			},
		},
	}
</script>

<style lang="less" scoped>
	.container {
		max-width: 800px;
		margin: 0 auto;
	}
	h2,
	h4 {
		margin-bottom: 20px;
	}
	ul {
		list-style-type: none;
		padding-left: 0;
	}
	li {
		background-color: #f5f5f5;
		padding: 10px;
		border-radius: 5px;
		margin-bottom: 10px;
	}
	.form-select {
		width: 100%;
		padding: 10px;
		border-radius: 5px;
		border: 1px solid #ddd;
	}

	.liquidity-section {
		background-color: #f9f9f9;
		padding: 15px;
		border-radius: 5px;

		.form-group {
			margin-bottom: 15px;

			label {
				display: block;
				margin-bottom: 5px;
			}

			input.form-control {
				width: 100%;
				padding: 8px;
				border: 1px solid #ccc;
				border-radius: 4px;
			}
		}

		button.btn {
			padding: 8px 15px;
			border: none;
			border-radius: 4px;
			cursor: pointer;

			&.btn-primary {
				background-color: #007bff;
				color: white;
			}

			&.btn-danger {
				background-color: #dc3545;
				color: white;
			}
		}
	}
</style>
