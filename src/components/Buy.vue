<template>
  <div>
    <h5>Price:</h5>
    <div class="d-flex justify-content-center align-items-center mb-4">
      <img class="icon" src="/img/algorand_white.svg" />
      <span class="ml-2">{{ price }}</span>
    </div>
    <b-button v-if="!isOwner" variant="info" @click="buyNFT" :disabled="isLoading">
      <b-spinner v-if="isLoading" class="mr-2" small />
      <b-icon v-else class="mr-2" icon="tag" />
      Buy
    </b-button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import ownerInterface from '@/utils/ownerInterface';

import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

export default {
  name: 'BuyView',
  props: {
    isOwner: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      price: undefined,
      timeout: undefined,
      break: false,
    };
  },
  computed: {
    ...mapState({
      contract: (state) => state.contract,
    }),
  },
  async mounted() {
    const price = await this.contract.v.Sell.price();
    this.price = reach.formatCurrency(price[1]);
  },
  methods: {
    buyNFT() {
      this.isLoading = true;
      this.contract.p.Owner(Object.assign(ownerInterface, this));
    },
    buy() {
      return;
    },
  },
};
</script>

<style>
.icon {
  height: 11px;
}
</style>
