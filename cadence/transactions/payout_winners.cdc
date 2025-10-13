import "FastbreakHorseRace"
import "FungibleToken"

// FLOW-only • no receivers arg
transaction(
  contestId: UInt64,
  winningPrediction: String
) {
  prepare(
    signer: auth(
      BorrowValue
    ) &Account
  ) {
    let admin = signer.storage.borrow<&FastbreakHorseRace.Admin>(
      from: FastbreakHorseRace.AdminStoragePath
    ) ?? panic("Admin not found (must be contract owner)")

    let col = signer.storage.borrow<&FastbreakHorseRace.Collection>(
      from: FastbreakHorseRace.CollectionStoragePath
    ) ?? panic("Owner collection not found")

    let any = col.borrowNFT(contestId) ?? panic("Contest not found")
    let nft = any as! &FastbreakHorseRace.NFT

    // Enforce FLOW-only payout
    if nft.buyInCurrency != "FLOW" {
      panic("payout_winners.cdc (FLOW-only): contest uses ".concat(nft.buyInCurrency))
    }

    // Build receivers map from winners’ public Flow receiver caps
    // Note: admin.payoutWinners splits by *winning entries*, not unique wallets.
    // We only need one receiver ref per wallet (duplicates not required).
    let recvs: {Address: &{FungibleToken.Receiver}} = {}

    var i = 0
    while i < nft.entries.length {
      let e = nft.entries[i]
      if e.prediction == winningPrediction {
        if recvs[e.wallet] == nil {
          let cap = getAccount(e.wallet).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
          let r = cap.borrow() ?? panic("Winner has no FlowToken receiver at /public/flowTokenReceiver: ".concat(e.wallet.toString()))
          recvs[e.wallet] = r
        }
      }
      i = i + 1
    }

    admin.payoutWinners(
      collectionRef: col,
      id: contestId,
      winningPrediction: winningPrediction,
      receivers: recvs
    )
  }
}
