'reach 0.1';
'use strict';

const AuctionProps = Object({
  startingBid: UInt,
  timeout: UInt,
});

const emptyAuction = { startingBid: 0, timeout: 0 };

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
    royalty: UInt,
  });
  const Owner = ParticipantClass('Owner', {
    newOwner: Fun([], Address),
    buy: Fun([UInt], Null),
    getBid: Fun([UInt], Maybe(UInt)),
  });
  const Seller = ParticipantClass('Seller', {
    salePrice: Fun([], UInt),
  });
  const Auctioneer = ParticipantClass('Auctioneer', {
    getAuctionProps: Fun([], AuctionProps),
  });
  const vNFT = View('NFT', {
    id: UInt,
    owner: Address,
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
    commit();

    fork()
      .case(Owner,
        (() => {
          const amOwner = this == owner;
          const newOwner = amOwner ? declassify(interact.newOwner()) : owner;
          return {
            msg: newOwner,
            when: amOwner,
          };
        }),
        (newOwner) => {
          require(this == owner);
          owner = newOwner;
          continue;
        })
      .case(Seller,
        (() => {
          const amOwner = this == owner;
          const salePrice = amOwner ? declassify(interact.salePrice()) : 0;
          return {
            msg: salePrice,
            when: amOwner,
          };
        }),
        (salePrice) => {
          require(this == owner);
          commit();

          Owner.only(() => {
            interact.buy(salePrice);
            const newOwner = this;
          });
          Owner.publish(newOwner)
            .pay(salePrice)
            .timeout(false);

          royaltyTransfer(salePrice, newOwner);
          owner = newOwner;
          continue;
        })
      .case(Auctioneer,
        (() => {
          const amOwner = this == owner;
          const auctionProps = amOwner ? declassify(interact.getAuctionProps()) : emptyAuction;
          return {
            msg: auctionProps,
            when: amOwner,
          };
        }),
        (auctionProps) => {
          require(this == owner);
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

          const salePrice = isFirstBid ? 0 : currentPrice;
          royaltyTransfer(salePrice, owner);
          owner = winner;
          continue;
        })
      .timeout(false);
  }
  commit();

  assert(false);
});