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
    url: Bytes(256),
  });
  const Owner = ParticipantClass('Owner', {
    transferOption: Fun([], UInt),
    newOwner: Fun([], Address),
    ...SaleInterface,
    ...AuctionInterface,
  });
  const vNFT = View('NFT', {
    id: UInt,
    royalty: UInt,
    url: Bytes(256),
    owner: Address,
    option: UInt,
  });
  const Logger = Events('Logger', {
    change: [],
  });
  init();

  Creator.only(() => {
    const id = declassify(interact.getId());
    const royalty = declassify(interact.royalty) % 100;
    assert(royalty <= 100);
    const url = declassify(interact.url);
  });
  Creator.publish(id, royalty, url);
  require(royalty <= 100);
  vNFT.id.set(id);
  vNFT.royalty.set(royalty);
  vNFT.url.set(url);

  const royaltyTransfer = (salePrice, owner) => {
    const royaltyPart = salePrice * royalty / 100;
    assert(royalty <= 100);
    assert(royaltyPart <= salePrice);

    transfer(royaltyPart).to(Creator);
    transfer(salePrice - royaltyPart).to(owner);
  };

  var owner = Creator;
  { vNFT.owner.set(owner); };
  invariant(balance() == 0);
  while (true) {
    Logger.change();
    vNFT.option.set(GIFT);
    commit();

    fork()
      .case(Owner,
        (() => {
          const amOwner = this == owner;
          const option = amOwner ? declassify(interact.transferOption()) % 3 : 0;
          assert(isTransferOption(option));
          const isGift = amOwner && option == GIFT;
          const newOwner = isGift ? declassify(interact.newOwner()) : owner;
          return {
            msg: newOwner,
            when: isGift,
          };
        }),
        (newOwner) => {
          require(this == owner);
          owner = newOwner;
          continue;
        })
      .case(Owner,
        (() => {
          const amOwner = this == owner;
          const option = amOwner ? declassify(interact.transferOption()) % 3 : 0;
          assert(isTransferOption(option));
          const isSale = amOwner && option == SALE;
          const salePrice = isSale ? declassify(interact.salePrice()) : 0;
          return {
            msg: salePrice,
            when: isSale,
          };
        }),
        (salePrice) => {
          require(this == owner);
          vNFT.option.set(SALE);
          
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
          const amOwner = this == owner;
          const option = amOwner ? declassify(interact.transferOption()) % 3 : 0;
          assert(isTransferOption(option));
          const isAuction = amOwner && option == AUCTION;
          const auctionProps = isAuction ? declassify(interact.getAuctionProps()) : emptyAuction;
          return {
            msg: auctionProps,
            when: isAuction,
          };
        }),
        (auctionProps) => {
          require(this == owner);
          require(typeof auctionProps == AuctionProps);

          vNFT.option.set(AUCTION);

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
                    when: maybe(mbid, false, ((bid) => isFirstBid ? bid >= currentPrice : bid > currentPrice)),
                    msg : fromSome(mbid, 0),
                  });
                },
                (bid) => bid,
                (bid) => {
                  require(isFirstBid ? bid >= currentPrice : bid > currentPrice);
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