import "FastbreakHorseRace"

transaction(
  displayName: String,
  fastbreakId: String,
  buyInCurrency: String,
  buyInAmount: UFix64,
  startTime: UFix64
) {
  prepare(
    signer: auth(
      BorrowValue,
      SaveValue
    ) &Account
  ) {
    let admin = signer.storage.borrow<&FastbreakHorseRace.Admin>(
      from: FastbreakHorseRace.AdminStoragePath
    ) ?? panic("FastbreakHorseRace.Admin not found in signer storage (must be contract owner)")

    let newContest <- admin.createContest(
      displayName: displayName,
      fastbreakId: fastbreakId,
      buyInCurrency: buyInCurrency,
      buyInAmount: buyInAmount,
      startTime: startTime
    )

    let col = signer.storage.borrow<&FastbreakHorseRace.Collection>(
      from: FastbreakHorseRace.CollectionStoragePath
    ) ?? panic("Signer has no FastbreakHorseRace.Collection in storage. Run setup_collection first.")

    col.deposit(token: <- newContest)
  }
}
