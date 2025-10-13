import "FastbreakHorseRace"

access(all) fun main(owner: Address, id: UInt64): [{String: AnyStruct}] {
  let col = getAccount(owner)
    .capabilities
    .borrow<&FastbreakHorseRace.Collection>(FastbreakHorseRace.CollectionPublicPath)
    ?? panic("Public collection not found")

  let any = col.borrowNFT(id) ?? panic("Contest not found")
  let nft = any as! &FastbreakHorseRace.NFT

  let out: [{String: AnyStruct}] = []
  var i = 0
  while i < nft.entries.length {
    let e = nft.entries[i]
    out.append({
      "wallet": e.wallet,
      "prediction": e.prediction,
      "timeOfEntry": e.timeOfEntry
    })
    i = i + 1
  }
  return out
}
