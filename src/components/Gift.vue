<template>
  <div>Gift</div>
  <div>Address</div>
  <input v-model="address" />
  <button @click="gift">Gift</button>
</template>

<script>
import * as backend from '../../build/index.main.mjs'

export default {
  name: 'GiftView',
  props: {
    ctc: {
      type: Object,
      required: true,
    }
  },
  data() {
    return {
      address: '',
    };
  },
  methods: {
    async gift() {
      backend.Owner(this.ctc, this);
    },
    transferOption() {
      console.log('Gift NFT');
      return 0;
    },
    newOwner() {
      console.log(`To: ${this.address}`)
      return this.address;
    },
  }
}
</script>

<style>
</style>
