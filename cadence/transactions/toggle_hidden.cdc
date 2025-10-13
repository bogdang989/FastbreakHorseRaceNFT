import "FastbreakHorseRace"

transaction(contestId: UInt64) {
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

    admin.toggleHidden(collectionRef: col, id: contestId)
  }
}
