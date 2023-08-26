<template>
	<div class="dex-section">
		<div class="col-12 pr-4 mt-4">
			<button
				class="btn btn-secondary mb-3 w-100"
				@click="openCreateLiquidityModal"
			>
				Create Liquidity Pool
			</button>

			<!-- Liquidity Pools Table -->
			<table class="table mt-4">
				<thead>
					<tr>
						<th>Token Pair</th>
						<th>Token A</th>
						<th>Amount</th>
						<th>Token B</th>
						<th>Amount</th>
						<th>Actions</th>
					</tr>
				</thead>
				<tbody>
					<tr v-for="pool in liquidityPools" :key="pool.contractAddress">
						<td>
							{{ shortAddr(pool.contractAddress) }}
							<!-- Clipboard Button (using Font Awesome icon for clipboard) -->
							<button
								class="btn btn-sm btn-secondary"
								@click="copyToClipboard(pool.contractAddress)"
							>
								<i class="bi bi-clipboard"></i>
							</button>
						</td>
						<td>{{ pool.aSymbol }}</td>
						<td>{{ pool.aBal }}</td>
						<td>{{ pool.bSymbol }}</td>
						<td>{{ pool.bBal }}</td>
						<td>
							<button class="btn btn-primary mx-1" @click="openAddModal(pool)">
								<i class="bi bi-droplet"></i>
							</button>
							<button
								class="btn btn-warning mx-1"
								@click="openWithdrawModal(pool)"
							>
								<i class="bi bi-arrow-down-left-circle"></i>
							</button>
						</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</template>

<script>
	export default {
		name: "LiquidityPoolSection",
		props: {
			liquidityPools: {
				type: Array,
				required: true,
			},
			dex: {
				type: Object,
				required: true,
			},
		},
		methods: {
			copyToClipboard(text) {
				navigator.clipboard
					.writeText(text)
					.then(() => {
						console.log("Text copied to clipboard")
					})
					.catch((err) => {
						console.error("Failed to copy text: ", err)
					})
			},
			shortAddr(addr) {
				//show 0x  first 6 .... last 6
				return `${addr.slice(0, 6)}...${addr.slice(-4)}`
			},
			openCreateLiquidityModal() {
				this.$emit("openCreateLiquidityModal")
			},
			openAddModal(pool) {
				// Handle opening the add liquidity modal
				this.$emit("openAddLiquidityModal", pool)
			},
			openWithdrawModal(pool) {
				this.$emit("openWithdrawModal", pool)
			},
		},
	}
</script>

<style lang="less" scoped>
	@import url("@/assets/colors.less");

	// Dex Liquidity Pools Section
	.dex-section {
		padding: 2rem;
		border-radius: 5px;
		box-shadow: 0 4px 6px @dark-shadow;
	}
</style>
