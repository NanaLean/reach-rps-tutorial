<template>
  <h3>Owner</h3>
  <br />
  <template v-if="!ctc">
    <h3>Please attach to the contract of the NFT you want to interact with:</h3>
    <div>
      <input type="textarea" v-model="ctcInfo">
      <button @click="attach">Attach</button>
    </div>
  </template>
  <template v-else-if="id && owner">
    <div>NFT: {{ id }}</div>
    <div>Owner: {{ owner }}</div>
    <br />
  </template>
  <p v-else>Loading ...</p>

  <div v-if="isOwner">
    <h3>What do you want to do with the NFT?</h3>
    <div>
      <button @click="view = 'gift'">Gift</button>
      <button @click="view = 'sell'">Sell</button>
      <button @click="view = 'auction'">Auction</button>
    </div>
  </div>
  <div v-else-if="owner">
    <h3>You do not own this asset!</h3>
    <button @click="view = 'buy'">Buy</button>
    <button @click="view = 'bid'">Bid</button>
  </div>
  <component :is="view" :ctc="ctc" />
</template>

<script>
import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });
import Gift from '@/components/Gift.vue';
import Sell from '@/components/Sell.vue';
import Auction from '@/components/Auction.vue';

import * as backend from '../../build/index.main.mjs'

export default {
  name: 'OwnerView',
  props: {
    acc: {
      type: Object,
      required: true,
    },
    initialCtc: {
      type: Object,
      required: false,
    },
  },
  components: {
    'gift': Gift,
    'sell': Sell,
    'auction': Auction
  },
  data() {
    return {
      ctc: undefined,
      ctcInfo: undefined,
      view: undefined,
      owner: undefined,
      id: undefined,
    }
  },
  mounted() {
    if (this.initialCtc) {
      this.ctcInfo = this.initialCtc;
      this.attach();
    }
  },
  computed: {
    isOwner() {
      if (!(this.acc && this.owner)) return false;
      return reach.addressEq(this.owner, this.acc);
    },
  },
  methods: {
    async attach() {
      const info = JSON.parse(this.ctcInfo);
      this.ctc = this.acc.contract(backend, info);
      this.watchChange();
    },
    async watchChange() {
      await this.ctc.e.Logger.change.next();
      console.log('Owner changed!');
      this.checkOwner();
      this.watchChange();
    },
    async checkOwner() {
      const [id, owner] = await Promise.all([await this.ctc.v.NFT.id(), await this.ctc.v.NFT.owner()])
      this.id = id[1];
      this.owner = reach.formatAddress(owner[1]);
    },
    salePrice() {
      const price = reach.parseCurrency(0);
      return price;
    },
    buy() {
      console.log(`buy`)
    },
    getAuctionProps() {
      return { startingBid: reach.parseCurrency(1), timeout: 10 };
    },
    getBid() {
      if (reach.parseCurrency(1)) {
        return ['Some', reach.parseCurrency(1)];
      } else {
        return ['None', null];
      }
    },
  }
}
</script>

<style>
</style>
