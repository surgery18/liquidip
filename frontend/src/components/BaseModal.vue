<template>
	<div>
		<div v-if="show" class="modal show d-block" tabindex="-1">
			<div class="modal-dialog">
				<div class="modal-content">
					<div class="modal-header">
						<h5 class="modal-title">
							<slot name="title"></slot>
						</h5>
						<button type="button" class="close" @click="closeModal">
							<span>&times;</span>
						</button>
					</div>
					<div class="modal-body">
						<slot></slot>
					</div>
					<div class="modal-footer">
						<slot name="footer"></slot>
					</div>
				</div>
			</div>
		</div>
		<!-- Backdrop -->
		<div v-if="show" class="modal-backdrop show"></div>
	</div>
</template>

<script>
	export default {
		props: ["show"],
		methods: {
			closeModal() {
				this.$emit("close")
			},
		},
	}
</script>

<style lang="less" scoped></style>
