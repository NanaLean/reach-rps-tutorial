<template>
  <div>
    <div class="mb-4">
      <h5>Starting Bid:</h5>
      <b-input-group append="ALGO">
        <b-input type="number" min="0" max="10000000000" v-model="startingBid" />
      </b-input-group>
    </div>
    <div class="mb-4">
      <h5>Duration:</h5>
      <b-input-group append="s">
        <b-input type="number" min="0" max="10000000000" v-model="timeout" />
      </b-input-group>
    </div>
    <b-button variant="info" @click="auction" :disabled="isLoading">
      <b-spinner v-if="isLoading" class="mr-2" small />
      <b-icon v-else class="mr-2" icon="hourglass-split" />
      Auction
    </b-button>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import ownerInterface from '@/utils/ownerInterface';

import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

export default {
  name: 'AuctionView',
  data() {
    return {
      isLoading: false,
      startingBid: 1,
      timeout: 60,
    };
  },
  computed: {
    ...mapState({
      contract: (state) => state.contract,
    }),
  },
  methods: {
    async auction() {
      this.isLoading = true;
      this.contract.p.Owner(Object.assign(ownerInterface, this));
    },
    transferOption() {
      return 2;
    },
    getAuctionProps() {
      return {
        startingBid: reach.parseCurrency(this.startingBid),
        timeout: this.timeout,
      };
    },
  },
};
</script>

<style></style>
