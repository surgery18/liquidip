<template>
	<div class="container text-center mt-5">
		<div class="card bg-white shadow-lg">
			<div class="card-body">
				<div class="card-title h1 text-dark my-5">
					<img src="../assets/logo.png" alt="LiquiDip Logo" class="logo" />
					LiquiDip
				</div>

				<h3 class="text-dark">Decentralized Exchange Platform</h3>
				<p class="card-text lead text-dark">
					Welcome to Liquidip the DEX platform demo. Here, you can interact with
					different functionalities related to decentralized finance, including
					managing liquidity, trading tokens, and exploring arbitrage
					opportunities with flashloans.
				</p>

				<connect-wallet></connect-wallet>

				<div class="grid mt-4">
					<div class="grid-item" v-for="item in gridItems" :key="item.title">
						<router-link :to="item.route">
							<button class="btn btn-success btn-lg w-100">
								{{ item.title }}
							</button>
						</router-link>
					</div>
					<div class="grid-item">
						<button
							class="btn btn-success btn-lg w-100"
							@click="openWBNBModal"
							:disabled="!web3.currentAddress"
						>
							WBNB Functions
						</button>
					</div>
				</div>
			</div>
		</div>
		<WBNBModal :show="showWBNBModal" @close="closeWBNBModal" />
	</div>
</template>

<script>
	import ConnectWallet from "../components/ConnectWallet.vue"
	import WBNBModal from "../components/WBNBModal.vue"
	import { useWeb3Store } from "@/stores/web3"

	export default {
		name: "HomeView",
		components: { ConnectWallet, WBNBModal },
		data() {
			return {
				gridItems: [
					{ title: "Dexes", route: "/dex-management" },
					{ title: "Arbitrage", route: "/arbitrage" },
					// { title: "View DEXs", route: "/dex-list" },
				],
				showWBNBModal: false,
			}
		},
		setup() {
			return { web3: useWeb3Store() }
		},
		methods: {
			openWBNBModal() {
				this.showWBNBModal = true
			},
			closeWBNBModal() {
				this.showWBNBModal = false
			},
		},
	}
</script>

<style lang="less" scoped>
	.container {
		max-width: 800px;
		margin: 0 auto;
		padding-top: 50px;
	}

	// .dark-theme {
	// 	background-color: #1a1a2e;
	// 	min-height: 100vh;
	// }

	.grid {
		display: flex;
		flex-wrap: wrap;
		gap: 20px;
		justify-content: center;
	}

	.grid-item {
		flex: 1;
		min-width: 200px;
		margin-bottom: 20px;
	}

	.logo {
		height: 100px;
	}
</style>
