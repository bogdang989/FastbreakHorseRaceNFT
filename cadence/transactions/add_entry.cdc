import "FastbreakHorseRace"
import "FungibleToken"
import "NonFungibleToken"
import "FlowToken"

// Use: flow transactions send .\cadence\transactions\add_entry.cdc 0xOWNER 1 "Nuggets" --signer acc1
transaction(
  contestOwner: Address,
  contestId: UInt64,
  prediction: String
) {
  prepare(
    signer: auth(
      BorrowValue
    ) &Account
  ) {
    // Read contest from owner's public collection
    let ownerCol = getAccount(contestOwner)
      .capabilities
      .borrow<&FastbreakHorseRace.Collection>(FastbreakHorseRace.CollectionPublicPath)
      ?? panic("Owner's FastbreakHorseRace public collection not found")

    let anyContest = ownerCol.borrowNFT(contestId)
      ?? panic("Contest not found")
    let contest = anyContest as! &FastbreakHorseRace.NFT

    // Only FLOW supported in this simplified tx
    if contest.buyInCurrency != "FLOW" {
      panic("This add_entry.cdc supports only FLOW buy-ins. Contest requires ".concat(contest.buyInCurrency))
    }

    // Withdraw exact buy-in from signer's Flow vault
    let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
      from: /storage/flowTokenVault
    ) ?? panic("Signer has no FlowToken vault at /storage/flowTokenVault")

    let payment <- flowVault.withdraw(amount: contest.buyInAmount) // @FlowToken.Vault

    // Atomic: funds → treasury AND entry recorded
    let now: UFix64 = getCurrentBlock().timestamp
    contest.submitEntry(
      wallet: signer.address,
      prediction: prediction,
      payment: <- (payment as @{FungibleToken.Vault}),
      time: now
    )
  }
}
