<template>
  <div>
    <h5>Contract Info:</h5>
    <div class="mb-5">
      <b-textarea v-model="contractInfo" />
    </div>
    <b-button variant="info" @click="attach" :disabled="isLoading">
      <b-spinner v-if="isLoading" class="mr-2" small />
      Attach
    </b-button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import * as backend from '../../build/index.main.mjs';

export default {
  name: 'AttachView',
  data() {
    return {
      isLoading: false,
      contractInfo: undefined,
    };
  },
  computed: {
    ...mapState({
      account: (state) => state.account,
    }),
  },
  methods: {
    async attach() {
      this.isLoading = true;
      const contract = this.account.contract(backend, this.contractInfo);
      this.$store.dispatch('setContract', contract);
    },
  },
};
</script>
