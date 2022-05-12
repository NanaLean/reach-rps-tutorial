'reach 0.1';
'use strict';

const [isTransferOption, GIFT, SALE] = makeEnum(2);

const SaleInterface = {
  buy: Fun([UInt], Null),
  salePrice: Fun([], UInt),
};

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
  });
  const Owner = ParticipantClass('Owner', {
    transferOption: Fun([], UInt),
    newOwner: Fun([], Address),
    ...SaleInterface,
  });
  const vNFT = View('NFT', {
    id: UInt,
    owner: Address,
  });
  init();

  Creator.only(() => {
    const id = declassify(interact.getId());
  });
  Creator.publish(id);
  vNFT.id.set(id);

  var owner = Creator;
  { vNFT.owner.set(owner); };
  invariant(balance() == 0);
  while (true) {
    commit();

    Owner.only(() => {
      const amOwner = this == owner;
      const transferOption = amOwner ? declassify(interact.transferOption()) % 2 : 0;
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
          require(transferOption == SALE);
          commit();

          Owner.only(() => {
            interact.buy(salePrice);
            const newOwner = this;
          });
          Owner.publish(newOwner)
            .pay(salePrice)
            .timeout(false);

          transfer(salePrice).to(owner);

          owner = newOwner;
          continue;
        })
      .timeout(false);
  }
  commit();

  assert(false);
});