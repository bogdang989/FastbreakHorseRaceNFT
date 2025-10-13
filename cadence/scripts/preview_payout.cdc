import "FastbreakHorseRace"

access(all) fun main(owner: Address, id: UInt64, winningPrediction: String): {String: AnyStruct} {
  let col = getAccount(owner)
    .capabilities
    .borrow<&FastbreakHorseRace.Collection>(FastbreakHorseRace.CollectionPublicPath)
    ?? panic("Public collection not found")

  let any = col.borrowNFT(id) ?? panic("Contest not found")
  let nft = any as! &FastbreakHorseRace.NFT

  let entries = nft.entries

  // Count winners and aggregate by wallet (multiple winning entries per wallet allowed)
  var totalWinners: Int = 0
  let counts: {Address: Int} = {}

  var i = 0
  while i < entries.length {
    let e = entries[i]
    if e.prediction == winningPrediction {
      totalWinners = totalWinners + 1
      let c = counts[e.wallet] ?? 0
      counts[e.wallet] = c + 1
    }
    i = i + 1
  }

  let totalPool: UFix64 = UFix64(entries.length) * nft.buyInAmount
  let payoutTotal: UFix64 = totalPool * 0.9
  let perWinner: UFix64 = totalWinners > 0 ? payoutTotal / UFix64(totalWinners) : 0.0

  // Build per-wallet breakdown
  let breakdown: [{String: AnyStruct}] = []
  for addr in counts.keys {
    let entryCount = counts[addr]!
    let amount: UFix64 = UFix64(entryCount) * perWinner
    breakdown.append({
      "wallet": addr,
      "winningEntries": entryCount,
      "amount": amount
    })
  }

  return {
    "totalEntries": entries.length,
    "winnerCount": totalWinners,
    "perWinner": perWinner,
    "totalPool": totalPool,
    "payoutTotal": payoutTotal,
    "breakdown": breakdown
  }
}
