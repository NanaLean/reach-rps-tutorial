<template>
  <div class="d-flex flex-column align-items-center">
    <h1 class="mb-4">Interact with an NFT</h1>
    <attach v-if="!contract" />
    <template v-else-if="id && address">
      <h4 class="mb-2">{{ nftName }}</h4>
      <p class="text-muted mb-2">{{ contractInfo }}</p>
      <img class="nft-img mb-3" :src="url" v-if="url" />
      <p class="mb-0">{{ address[0] }}<b-icon icon="wallet2" class="mx-1" />{{ address[1] }}</p>
      <div v-if="isOwner" class="mb-4">
        <p class="text-muted mb-4">You own this NFT</p>
        <div v-if="option === 0">
          <b-button v-if="view !== 'gift'" variant="info" class="m-2" @click="view = 'gift'"
            ><b-icon class="mr-2" icon="gift" />Gift</b-button
          >
          <b-button v-if="view !== 'sell'" variant="info" class="m-2" @click="view = 'sell'"
            ><b-icon class="mr-2" icon="tag" />Sell</b-button
          >
          <b-button v-if="view !== 'auction'" variant="info" class="m-2" @click="view = 'auction'"
            ><b-icon class="mr-2" icon="hourglass-split" />Auction</b-button
          >
        </div>
        <h5 v-if="option === 1">You have set this NFT up for sale.</h5>
        <h5 v-if="option === 2">You have set this NFT up for auction.</h5>
      </div>
      <div v-else-if="owner" class="mb-4">
        <p class="text-muted mb-4">You do not own this NFT</p>
        <h5 v-if="option === 0">This NFT is not up for sale or auction.</h5>
        <h5 v-if="option === 1">This NFT is up for sale.</h5>
        <h5 v-if="option === 2">This NFT is up for auction.</h5>
      </div>
      <component ref="owner" :is="view" :isOwner="isOwner" />
    </template>
    <b-spinner v-else />
  </div>
</template>

<script>
import { mapState } from 'vuex';

import Attach from '@/components/Attach.vue';
import Gift from '@/components/Gift.vue';
import Sell from '@/components/Sell.vue';
import Auction from '@/components/Auction.vue';
import Buy from '@/components/Buy.vue';
import Bid from '@/components/Bid.vue';

import { loadStdlib } from '@reach-sh/stdlib';
const reach = loadStdlib({ REACH_CONNECTOR_MODE: 'ALGO' });

export default {
  name: 'OwnerView',
  components: {
    attach: Attach,
    gift: Gift,
    sell: Sell,
    auction: Auction,
    buy: Buy,
    bid: Bid,
  },
  data() {
    return {
      view: undefined,
      owner: undefined,
      id: undefined,
      nftName: undefined,
      url: undefined,
      royalty: undefined,
      option: 0,
    };
  },
  computed: {
    ...mapState({
      account: (state) => state.account,
      contract: (state) => state.contract,
      contractInfo: (state) => state.contractInfo,
    }),
    isOwner() {
      if (!(this.account && this.owner)) return false;
      return reach.addressEq(this.owner, this.account);
    },
    address() {
      if (!this.owner) return;
      return [this.owner.substring(0, 5), this.owner.substring(53)];
    },
  },
  methods: {
    async watchChange() {
      if (!this.contract) return;

      await this.contract.e.Logger.change.next();
      await this.loadInfo();
      this.watchChange();
    },
    async loadInfo() {
      if (!this.id) {
        await this.loadStatic();
      }
      await this.loadChanges();
    },
    async loadChanges() {
      this.view = undefined;
      const [owner, option] = await Promise.all([
        await this.contract.v.NFT.owner(),
        await this.contract.v.NFT.option(),
      ]);
      if (!owner[1]) return;
      this.owner = reach.formatAddress(owner[1]);
      this.option = parseInt(option[1]);
      if (this.option === 1) {
        this.view = 'buy';
      } else if (this.option === 2) {
        this.view = 'bid';
      }
    },
    async loadStatic() {
      const [id, name, url, royalty] = await Promise.all([
        await this.contract.v.NFT.id(),
        await this.contract.v.NFT.name(),
        await this.contract.v.NFT.url(),
        await this.contract.v.NFT.royalty(),
      ]);
      this.id = id[1] || this.id;
      this.nftName = name[1] || this.nftName;
      this.url = url[1] || this.url;
      this.royalty = royalty[1] || this.royalty;
    },
  },
  watch: {
    contract: {
      handler(newValue) {
        if (newValue) {
          this.loadInfo();
          this.watchChange();
        }
      },
      immediate: true,
    },
  },
};
</script>

<style></style>
