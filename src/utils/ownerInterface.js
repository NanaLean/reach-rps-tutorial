export default {
  transferOption() {
    console.log('transferOption default');
    return 0;
  },
  newOwner() {
    console.log('newOwner default');
    return '0x';
  },
  salePrice() {
    console.log('salePrice default');
    return 0;
  },
  buy() {
    console.log('buy default');
    return;
  },
  getAuctionProps() {
    console.log('auctionProps default');
    return {
      startingBid: 0,
      timeout: 0,
    };
  },
  getBid() {
    console.log('getBid default');
    return ['None', null];
  },
};
