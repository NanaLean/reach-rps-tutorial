'reach 0.1';
'use strict';

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
  });
  const Owner = ParticipantClass('Owner', {
    showOwner: Fun([UInt, Address], Null),
    newOwner: Fun([], Address),
  });
  init();

  Creator.only(() => {
    const id = declassify(interact.getId());
  });
  Creator.publish(id);

  var owner = Creator;
  invariant(balance() == 0);
  while (true) {
    commit();

    Owner.only(() => {
      interact.showOwner(id, owner);
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