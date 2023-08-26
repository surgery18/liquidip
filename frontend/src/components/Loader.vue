<template>
	<div v-if="isLoading" class="loader-backdrop">
		<div class="loader-container">
			<div class="loader-animation"></div>
			<p>Loading...</p>
		</div>
	</div>
</template>

<script>
	import { isLoading } from "@/utils/eventbus"
	export default {
		name: "LoaderComponent",
		setup() {
			return {
				isLoading,
			}
		},
	}
</script>

<style scoped>
	.loader-backdrop {
		position: fixed;
		top: 0;
		left: 0;
		width: 100vw;
		height: 100vh;
		background-color: rgba(0, 0, 0, 0.7); /* Semi-transparent backdrop */
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 10050;
	}

	.loader-container {
		text-align: center;
	}

	.loader-animation {
		width: 50px;
		height: 50px;
		border: 5px solid #f3f3f3;
		border-top: 5px solid #3498db;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		0% {
			transform: rotate(0deg);
		}
		100% {
			transform: rotate(360deg);
		}
	}
</style>
