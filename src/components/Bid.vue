<template>
  <div>
    <h5>Starting bid:</h5>
    <div class="d-flex justify-content-center align-items-center mb-3">
      <img class="icon" src="/img/algorand_white.svg" />
      <span class="ml-2">{{ startingBid }}</span>
    </div>
    <h5>Current bid:</h5>
    <div class="d-flex justify-content-center align-items-center mb-3">
      <img class="icon" src="/img/algorand_white.svg" />
      <span class="ml-2">{{ currentBid }}</span>
    </div>
    <template v-if="!isOwner">
      <div class="mb-4">
        <h5>Your bid:</h5>
        <b-input-group append="ALGO">
          <b-input type="number" min="0" max="10000000000" v-model="nextBid" />
        </b-input-group>
      </div>
      <b-button variant="info" @click="bid" :disabled="isLoading">
        <b-spinner v-if="isLoading" class="mr-2" small />
        <b-icon v-else class="mr-2" icon="tag" />
        Auction
      </b-button>
    </template>
  </div>
</template>

<script>
import { mapState } from 'vuex';
import ownerInterface from '@/utils/ownerInterface';

import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

export default {
  name: 'BidView',
  props: {
    isOwner: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      nextBid: 1,
      startingBid: undefined,
      currentBid: undefined,
    };
  },
  computed: {
    ...mapState({
      contract: (state) => state.contract,
    }),
  },
  async mounted() {
    const startingBid = await this.contract.v.Auction.startingBid();
    const currentBid = await this.contract.v.Auction.currentBid();
    const timeout = await this.contract.v.Auction.timeout();
    console.log(parseInt(timeout[1]));
    this.startingBid = reach.formatCurrency(startingBid[1]);
    this.currentBid = reach.formatCurrency(currentBid[1]);
    this.nextBid = reach.formatCurrency(parseInt(currentBid[1]) + 1000000);
  },
  methods: {
    async bid() {
      this.isLoading = true;
      this.contract.p.Owner(Object.assign(ownerInterface, this));
    },
    getBid() {
      return ['Some', reach.parseCurrency(this.nextBid)];
    },
  },
};
</script>

<style></style>
