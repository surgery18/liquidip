<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title>
			<input
				type="text"
				class="form-control"
				placeholder="Search token name, symbol, or address..."
				v-model="tokenSearch"
			/>
		</template>

		<ul class="token-list">
			<li
				v-for="token in filteredTokens"
				:key="token.id"
				@click="selectToken(token)"
			>
				{{ token.name }} ({{ token.symbol }})
			</li>
		</ul>
	</BaseModal>
</template>

<script>
	import BaseModal from "./BaseModal.vue"

	export default {
		components: {
			BaseModal,
		},
		props: ["show", "tokens"],
		data() {
			return {
				tokenSearch: "",
				// allTokens: [
				// 	// Example tokens
				// 	{ id: 1, name: "Ethereum", symbol: "ETH" },
				// 	{ id: 2, name: "Bitcoin", symbol: "BTC" },
				// 	// ... more tokens
				// ],
			}
		},
		computed: {
			filteredTokens() {
				if (!this.tokenSearch) return this.tokens
				const search = this.tokenSearch.toLowerCase()
				return this.tokens.filter(
					(token) =>
						token.name.toLowerCase().includes(search) ||
						token.symbol.toLowerCase().includes(search) ||
						token.address.toLowerCase().includes(search)
				)
			},
		},
		methods: {
			closeModal() {
				this.$emit("close")
			},
			selectToken(token) {
				this.$emit("select", token)
				this.closeModal()
			},
		},
	}
</script>

<style lang="less" scoped>
	@import url("@/assets/colors.less");

	:deep(.modal-body) {
		max-height: 300px; // or adjust based on your preference
		overflow-y: auto;

		.token-list {
			list-style: none;
			padding: 0;

			li {
				padding: 0.5rem;
				cursor: pointer;
				transition: background-color 0.2s;

				&:hover {
					background-color: @light-border-color;
				}
			}
		}
	}

	:deep(.modal-header) {
		padding: 1rem;

		.modal-title {
			flex: 1; // Take remaining available width
			margin: 0 1rem;
		}

		input {
			border: none;
			border-bottom: 1px solid @light-border-color;
			border-radius: 0;
			background-color: @light-bg-color;
			color: @dark-text-color;
		}
	}
</style>
