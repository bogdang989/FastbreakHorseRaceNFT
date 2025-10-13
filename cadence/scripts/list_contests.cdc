import "FastbreakHorseRace"

access(all) fun main(owner: Address): [UInt64] {
  let col = getAccount(owner)
    .capabilities
    .borrow<&FastbreakHorseRace.Collection>(FastbreakHorseRace.CollectionPublicPath)
    ?? panic("Public collection not found")

  return col.getIDs()
}
