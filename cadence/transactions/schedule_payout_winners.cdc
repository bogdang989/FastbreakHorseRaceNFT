import "FastbreakHorseRace"

// Usage:
// flow transactions send .\cadence\transactions\schedule_payout_and_set_winner.cdc ^
//   1 "Nuggets" 60.0 0.50 1 1000 --signer testnetFHRDeployer --network testnet
//
// Args:
// - contestId: UInt64
// - winningPrediction: String
// - executeAfterSeconds: UFix64   (e.g. 60.0 test, 86400.0 prod)
// - feeAmount: UFix64             (FLOW fee budget for scheduling/execution)
// - priority: UInt8               (0=Low, 1=Medium, 2=High)
// - effort: UInt64                (execution effort hint)

transaction(
  contestId: UInt64,
  winningPrediction: String,
  executeAfterSeconds: UFix64,
  feeAmount: UFix64,
  priority: UInt8,
  effort: UInt64
) {
  prepare(
    signer: auth(
      BorrowValue
    ) &Account
  ) {
    let admin = signer.storage.borrow<&FastbreakHorseRace.Admin>(
      from: FastbreakHorseRace.AdminStoragePath
    ) ?? panic("Admin not found (must be contract owner)")

    // 1) Set the contest NFT’s winningPrediction (via entitled setter)
    admin.setWinningPrediction(contestId: contestId, prediction: winningPrediction)

    // 2) Schedule payout; handler will re-read nft.winningPrediction at execution time
    admin.schedulePayout(
      contestId: contestId,
      executeAfterSeconds: executeAfterSeconds,
      feeAmount: feeAmount,
      priority: priority,
      effort: effort
    )
  }
}
