'reach 0.1';
'use strict';

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
  });
  const Owner = ParticipantClass('Owner', {
    newOwner: Fun([], Address),
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
      const newOwner = amOwner ? declassify(interact.newOwner()) : owner;
    });
    Owner.publish(newOwner)
      .when(amOwner)
      .timeout(false);
    require(this == owner);
    owner = newOwner;
    continue;
  }
  commit();

  assert(false);
});