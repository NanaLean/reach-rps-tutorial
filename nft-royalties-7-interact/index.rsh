'reach 0.1';
'use strict';

const [isTransferOption, GIFT, SALE, AUCTION] = makeEnum(3);

const AuctionProps = Object({
  startingBid: UInt,
  timeout: UInt,
});
const emptyAuction = { startingBid: 0, timeout: 0 };
const AuctionInterface = {
  getBid: Fun([UInt], Maybe(UInt)),
  getAuctionProps: Fun([], AuctionProps),
};

const SaleInterface = {
  buy: Fun([UInt], Null),
  salePrice: Fun([], UInt),
};

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
    royalty: UInt,
  });
  const Owner = ParticipantClass('Owner', {
    transferOption: Fun([], UInt),
    newOwner: Fun([], Address),
    ...SaleInterface,
    ...AuctionInterface,
  });
  const vNFT = View('NFT', {
    id: UInt,
    owner: Address,
  });
  const Logger = Events('Logger', {
    change: [],
  });
  init();

  Creator.only(() => {
    const id = declassify(interact.getId());
    const royalty = declassify(interact.royalty) % 100;
    assert(royalty <= 100);
  });
  Creator.publish(id, royalty);
  require(royalty <= 100);
  vNFT.id.set(id);

  const royaltyTransfer = (salePrice, newOwner) => {
    const royaltyPart = salePrice * royalty / 100;
    assert(royalty <= 100);
    assert(royaltyPart <= salePrice);

    transfer(royaltyPart).to(Creator);
    transfer(salePrice - royaltyPart).to(newOwner);
  };

  var owner = Creator;
  { vNFT.owner.set(owner); };
  invariant(balance() == 0);
  while (true) {
    Logger.change();
    commit();
    
    Owner.only(() => {
      const amOwner = this == owner;
      const transferOption = amOwner ? declassify(interact.transferOption()) % 3 : 0;
      assert(isTransferOption(transferOption));
    });
    Owner.publish(transferOption)
      .when(amOwner)
      .timeout(false);
    require(this == owner);
    commit();

    fork()
      .case(Owner,
        (() => {
          const isGift = this == owner && transferOption == GIFT;
          const newOwner = isGift ? declassify(interact.newOwner()) : owner;
          return {
            msg: newOwner,
            when: isGift,
          };
        }),
        (newOwner) => {
          require(this == owner);
          require(transferOption == GIFT);
          owner = newOwner;
          continue;
        })
      .case(Owner,
        (() => {
          const isSale = this == owner && transferOption == SALE;
          const salePrice = isSale ? declassify(interact.salePrice()) : 0;
          return {
            msg: salePrice,
            when: isSale,
          };
        }),
        (salePrice) => {
          require(this == owner);
          commit();

          Owner.only(() => {
            const notOwner = this != owner;
            notOwner ? interact.buy(salePrice) : null;
            const newOwner = this;
          });
          Owner.publish(newOwner)
            .when(notOwner)
            .pay(salePrice)
            .timeout(false);

          royaltyTransfer(salePrice, owner);
          owner = newOwner;
          continue;
        })
      .case(Owner,
        (() => {
          const isAuction = this == owner && transferOption == AUCTION;
          const auctionProps = isAuction ? declassify(interact.getAuctionProps()) : emptyAuction;
          return {
            msg: auctionProps,
            when: isAuction,
          };
        }),
        (auctionProps) => {
          require(this == owner);
          require(transferOption == AUCTION);
          require(typeof auctionProps == AuctionProps);

          const { startingBid, timeout } = auctionProps;
          const [ timeRemaining, keepGoing ] = makeDeadline(timeout);

          const [ winner, isFirstBid, currentPrice ] =
            parallelReduce([ owner, true, startingBid ])
              .invariant(balance() == (isFirstBid ? 0 : currentPrice))
              .while(keepGoing())
              .case(Owner,
                () => {
                  const mbid = (this != owner && this != winner)
                    ? declassify(interact.getBid(currentPrice))
                    : Maybe(UInt).None();
                  return ({
                    when: maybe(mbid, false, ((bid) => bid > currentPrice)),
                    msg : fromSome(mbid, 0),
                  });
                },
                (bid) => bid,
                (bid) => {
                  require(bid > currentPrice);
                  // Return funds to previous highest bidder
                  transfer(isFirstBid ? 0 : currentPrice).to(winner);
                  return [ this, false, bid ];
                }
              )
              .timeRemaining(timeRemaining());

          const auctionPrice = isFirstBid ? 0 : currentPrice;
          royaltyTransfer(auctionPrice, owner);
          owner = winner;
          continue;
        })
      .timeout(false);
  }
  commit();

  assert(false);
});