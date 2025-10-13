import "FastbreakHorseRace"
import "NonFungibleToken"

transaction(contestId: UInt64) {
  prepare(
    signer: auth(
      BorrowValue
    ) &Account
  ) {
    let admin = signer.storage.borrow<&FastbreakHorseRace.Admin>(
      from: FastbreakHorseRace.AdminStoragePath
    ) ?? panic("Admin not found (must be contract owner)")

    // Need Withdraw entitlement on stored collection reference
    let col = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &FastbreakHorseRace.Collection>(
      from: FastbreakHorseRace.CollectionStoragePath
    ) ?? panic("Owner collection (withdraw) not found")

    admin.destroyContest(collectionRef: col, id: contestId)
  }
}
