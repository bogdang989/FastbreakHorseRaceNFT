import "FastbreakHorseRace"
import "NonFungibleToken"

transaction {
  prepare(
    signer: auth(
      BorrowValue,
      IssueStorageCapabilityController,
      PublishCapability,
      SaveValue,
      UnpublishCapability
    ) &Account
  ) {
    // If already initialized, exit early (borrow interface ref to avoid type inference issues)
    if signer.storage.borrow<&{NonFungibleToken.Collection}>(
      from: FastbreakHorseRace.CollectionStoragePath
    ) != nil {
      return
    }

    // Create and save an empty FastbreakHorseRace collection
    let collection <- FastbreakHorseRace.createEmptyCollection(
      nftType: Type<@FastbreakHorseRace.NFT>()
    )
    signer.storage.save(<-collection, to: FastbreakHorseRace.CollectionStoragePath)

    // Publish a public capability at the contract's PublicPath
    let cap = signer.capabilities.storage.issue<&FastbreakHorseRace.Collection>(
      FastbreakHorseRace.CollectionStoragePath
    )
    signer.capabilities.publish(cap, at: FastbreakHorseRace.CollectionPublicPath)
  }
}
