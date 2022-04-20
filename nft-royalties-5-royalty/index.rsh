'reach 0.1';
'use strict';

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
    royalty: UInt,
  });
  const Owner = ParticipantClass('Owner', {
    newOwner: Fun([], Address),
    buy: Fun([UInt], Null),
  });
  const Seller = ParticipantClass('Seller', {
    salePrice: Fun([], UInt),
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

          const royaltyPart = salePrice * royalty / 100;

          assert(royalty <= 100);
          assert(royaltyPart <= salePrice);
  
          transfer(royaltyPart).to(Creator);
          transfer(salePrice - royaltyPart).to(owner);
          owner = newOwner;
          continue;
        })
      .timeout(false);
  }
  commit();

  assert(false);
});