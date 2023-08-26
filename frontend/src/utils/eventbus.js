import { ref } from "vue";

const isLoading = ref(false);

function startLoading() {
  isLoading.value = true;
}

function stopLoading() {
  isLoading.value = false;
}

export { isLoading, startLoading, stopLoading };
