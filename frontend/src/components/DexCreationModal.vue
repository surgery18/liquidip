<template>
	<BaseModal :show="show" @close="closeModal">
		<template #title> New Dex </template>

		<div>Do you want to create a dex?</div>

		<template #footer>
			<button type="button" class="btn btn-secondary" @click="closeModal">
				Cancel
			</button>
			<button type="button" class="btn btn-primary" @click="createDex">
				Create Dex
			</button>
		</template>
	</BaseModal>
</template>

<script>
	import BaseModal from "./BaseModal.vue"

	export default {
		components: {
			BaseModal,
		},
		props: ["show"],
		methods: {
			closeModal() {
				this.$emit("close")
			},
			createDex() {
				this.$emit("createDex")
			},
		},
	}
</script>

<style lang="less" scoped>
	// Specific styles for this modal
</style>
