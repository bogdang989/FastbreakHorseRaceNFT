import "FastbreakHorseRace"

access(all) fun main(owner: Address, id: UInt64): {String: AnyStruct} {
  let col = getAccount(owner)
    .capabilities
    .borrow<&FastbreakHorseRace.Collection>(FastbreakHorseRace.CollectionPublicPath)
    ?? panic("Public collection not found")

  let any = col.borrowNFT(id) ?? panic("Contest not found")
  let nft = any as! &FastbreakHorseRace.NFT

  return {
    "id": id,
    "displayName": nft.displayName,
    "fastbreakId": nft.fastbreakId,
    "buyInCurrency": nft.buyInCurrency,
    "buyInAmount": nft.buyInAmount,
    "startTime": nft.startTime,
    "hidden": nft.hidden,
    "entryCount": nft.entries.length
  }
}
