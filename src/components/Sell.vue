<template>
  <div>
    <div class="mb-4">
      <h5>Price:</h5>
      <b-input-group append="ALGO">
        <b-input type="number" min="0" max="10000000000" v-model="price" />
      </b-input-group>
    </div>
    <b-button variant="info" @click="sell" :disabled="isLoading">
      <b-spinner v-if="isLoading" class="mr-2" small />
      <b-icon v-else class="mr-2" icon="tag" />
      Sell
    </b-button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import ownerInterface from '@/utils/ownerInterface';

import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

export default {
  name: 'SellView',
  data() {
    return {
      isLoading: false,
      price: 1,
    };
  },
  computed: {
    ...mapState({
      contract: (state) => state.contract,
    }),
  },
  methods: {
    async sell() {
      this.isLoading = true;
      this.contract.p.Owner(Object.assign(ownerInterface, this));
    },
    transferOption() {
      return 1;
    },
    salePrice() {
      return reach.parseCurrency(this.price);
    },
  },
};
</script>

<style></style>
