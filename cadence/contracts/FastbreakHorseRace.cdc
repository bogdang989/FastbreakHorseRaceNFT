import "NonFungibleToken"
import "FungibleToken"
import "ViewResolver"
import "MetadataViews"

access(all) contract FastbreakHorseRace: NonFungibleToken {

    // -------------------------
    // Standard Paths
    // -------------------------
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // -------------------------
    // Contest Entry model
    // -------------------------
    access(all) struct Entry {
        access(all) let wallet: Address
        access(all) let prediction: String
        access(all) let timeOfEntry: UFix64

        init(wallet: Address, prediction: String, timeOfEntry: UFix64) {
            self.wallet = wallet
            self.prediction = prediction
            self.timeOfEntry = timeOfEntry
        }
    }

    // -------------------------
    // NFT (the contest)
    // -------------------------
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64

        // Contest metadata
        access(all) var displayName: String
        access(all) var fastbreakId: String      // external GUID string
        access(all) var buyInCurrency: String    // e.g. "FLOW" / "MVP" / "BETA" / "TSHOT"
        access(all) var buyInAmount: UFix64      // token units
        access(all) var startTime: UFix64        // unix timestamp (seconds)
        access(all) var hidden: Bool             // UI toggle

        // Dynamic entries
        access(all) var entries: [Entry]

        init(
            id: UInt64,
            displayName: String,
            fastbreakId: String,
            buyInCurrency: String,
            buyInAmount: UFix64,
            startTime: UFix64
        ) {
            self.id = id
            self.displayName = displayName
            self.fastbreakId = fastbreakId
            self.buyInCurrency = buyInCurrency
            self.buyInAmount = buyInAmount
            self.startTime = startTime
            self.hidden = false
            self.entries = []
        }

        // Add an entry before the contest starts
        access(all) fun addEntry(wallet: Address, prediction: String, time: UFix64) {
            pre {
                time < self.startTime: "Contest already started"
            }
            let e = Entry(wallet: wallet, prediction: prediction, timeOfEntry: time)
            self.entries.append(e)
        }

        // UI toggle
        access(all) fun toggleHidden() {
            self.hidden = !self.hidden
        }

        // Optional helper (some UIs call from token type)
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FastbreakHorseRace.createEmptyCollection(nftType: Type<@FastbreakHorseRace.NFT>())
        }

        // ---- Minimal Views implemented by this NFT
        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    let title = self.displayName.concat(" (").concat(self.fastbreakId).concat(")")
                    let desc = "Buy-in: ".concat(self.buyInAmount.toString()).concat(" ").concat(self.buyInCurrency)
                    return MetadataViews.Display(
                        name: title,
                        description: desc,
                        thumbnail: MetadataViews.HTTPFile(url: "https://mvponflow.cc/favicon.png")
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return FastbreakHorseRace.resolveContractView(
                        resourceType: Type<@FastbreakHorseRace.NFT>(),
                        viewType: Type<MetadataViews.NFTCollectionData>()
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return FastbreakHorseRace.resolveContractView(
                        resourceType: Type<@FastbreakHorseRace.NFT>(),
                        viewType: Type<MetadataViews.NFTCollectionDisplay>()
                    )
            }
            return nil
        }
    }

    // -------------------------
    // Collection (Cadence 1.0 NFT standard)
    // -------------------------
    access(all) resource Collection: NonFungibleToken.Collection {

        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        init() {
            self.ownedNFTs <- {}
        }

        // Standard views
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let m: {Type: Bool} = {}
            m[Type<@FastbreakHorseRace.NFT>()] = true
            return m
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@FastbreakHorseRace.NFT>()
        }

        // Withdraw requires the Withdraw entitlement
        access(NonFungibleToken.Withdraw)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("FastbreakHorseRace.Collection.withdraw: missing id ".concat(withdrawID.toString()))
            return <- token
        }

        // Deposit any NFT conforming to the interface; we store our concrete type
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let c <- token as! @FastbreakHorseRace.NFT
            let _old <- self.ownedNFTs[c.id] <- c
            destroy _old
        }

        // Views
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        // Optional helper for UIs
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FastbreakHorseRace.createEmptyCollection(nftType: Type<@FastbreakHorseRace.NFT>())
        }

    }

    // -------------------------
    // Admin (contract owner)
    // -------------------------
    access(all) resource Admin {

        // Mint a new contest NFT with no entries
        access(all) fun createContest(
            displayName: String,
            fastbreakId: String,
            buyInCurrency: String,
            buyInAmount: UFix64,
            startTime: UFix64
        ): @FastbreakHorseRace.NFT {
            let newID = FastbreakHorseRace.totalSupply + 1
            FastbreakHorseRace.totalSupply = newID
            let nft <- create FastbreakHorseRace.NFT(
                id: newID,
                displayName: displayName,
                fastbreakId: fastbreakId,
                buyInCurrency: buyInCurrency,
                buyInAmount: buyInAmount,
                startTime: startTime
            )
            return <- nft
        }

        // Burn a contest NFT (needs Withdraw entitlement on the collection ref)
        access(all) fun destroyContest(
            collectionRef: auth(NonFungibleToken.Withdraw) &FastbreakHorseRace.Collection,
            id: UInt64
        ) {
            let nft <- collectionRef.withdraw(withdrawID: id) as! @FastbreakHorseRace.NFT
            destroy nft
        }

        // Toggle hidden flag (only needs a read ref)
        access(all) fun toggleHidden(
            collectionRef: &FastbreakHorseRace.Collection,
            id: UInt64
        ) {
            let anyRef = collectionRef.borrowNFT(id)
                ?? panic("Contest not found")
            let nftRef = anyRef as! &FastbreakHorseRace.NFT
            nftRef.toggleHidden()
        }

        // Payout 90% of total buy-ins equally to all matching winners
        access(all) fun payoutWinners(
            collectionRef: &FastbreakHorseRace.Collection,
            id: UInt64,
            winningPrediction: String,
            receivers: {Address: &{FungibleToken.Receiver}}
        ) {
            let anyRef = collectionRef.borrowNFT(id)
                ?? panic("Contest not found")
            let nftRef = anyRef as! &FastbreakHorseRace.NFT
            let entries = nftRef.entries

            // winners by exact prediction match (Cadence 1.0: predicate must be view fun)
            let winners = entries.filter(view fun (element: FastbreakHorseRace.Entry): Bool {
                return element.prediction == winningPrediction
            })
            if winners.length == 0 {
                log("No winners for ".concat(winningPrediction))
                return
            }

            let totalPool = UFix64(entries.length) * nftRef.buyInAmount
            let payoutTotal = totalPool * 0.9
            let perWinner = payoutTotal / UFix64(winners.length)

            var i = 0
            while i < winners.length {
                let w = winners[i]
                let recv = receivers[w.wallet] ?? panic("Missing receiver for ".concat(w.wallet.toString()))
                let pay <- FastbreakHorseRace.withdrawFromTreasury(
                    currency: nftRef.buyInCurrency,
                    amount: perWinner
                )
                // pay is @{FungibleToken.Vault}, matches receiver’s expected type
                recv.deposit(from: <- pay)
                i = i + 1
            }
        }
    }

    // -------------------------
    // Treasury (per-currency pooled vaults)
    // -------------------------

    access(self) fun vaultStoragePath(currency: String): StoragePath {
        return StoragePath(identifier: "FHR_".concat(currency).concat("_Vault"))!
    }

    access(self) fun vaultReceiverPublicPath(currency: String): PublicPath {
        return PublicPath(identifier: "FHR_".concat(currency).concat("_Receiver"))!
    }

    // Create or reuse the currency vault:
    //  - On first use, the incoming payment vault becomes the base vault.
    //  - Later, we deposit into the stored vault through its receiver cap.
    access(self) fun ensureVaultReady(currency: String, received: @{FungibleToken.Vault}): &{FungibleToken.Receiver} {
        let sPath = self.vaultStoragePath(currency: currency)
        let pPath = self.vaultReceiverPublicPath(currency: currency)

        if self.account.storage.borrow<&{FungibleToken.Vault}>(from: sPath) == nil {
            self.account.storage.save(<- received, to: sPath)

            if !self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).check() {
                let cap = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(sPath)
                self.account.capabilities.publish(cap, at: pPath)
            }

            let recv = self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).borrow()
                ?? panic("Receiver missing after vault init for ".concat(currency))
            return recv
        }

        let recv2 = self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).borrow()
            ?? panic("Receiver missing for currency ".concat(currency))
        // deposit the owned interface vault into existing receiver
        recv2.deposit(from: <- received)
        return recv2
    }

    // Called by add_entry tx: move payment into treasury
    access(all) fun depositBuyIn(currency: String, payment: @{FungibleToken.Vault}) {
        var _ = self.ensureVaultReady(currency: currency, received: <- payment)
    }

    // Withdraw from treasury for payouts (return interface-typed resource @{FungibleToken.Vault})
    access(all) fun withdrawFromTreasury(currency: String, amount: UFix64): @{FungibleToken.Vault} {
        let sPath = self.vaultStoragePath(currency: currency)
        let base = self.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: sPath)
            ?? panic("Treasury vault not found for ".concat(currency))
        let taken <- base.withdraw(amount: amount)
        return <- (taken as @{FungibleToken.Vault})
    }

    // -------------------------
    // Contract Views (required by standard implementations)
    // -------------------------
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: self.CollectionStoragePath,
                    publicPath: self.CollectionPublicPath,
                    publicCollection: Type<&FastbreakHorseRace.Collection>(),
                    publicLinkedType: Type<&FastbreakHorseRace.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <- FastbreakHorseRace.createEmptyCollection(nftType: Type<@FastbreakHorseRace.NFT>())
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(url: "https://mvponflow.cc/favicon.png"),
                    mediaType: "image/png"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Fastbreak Horse Race Contests",
                    description: "Each NFT represents a contest with on-chain entries and buy-ins.",
                    externalURL: MetadataViews.ExternalURL("https://mvponflow.cc/"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {}
                )
        }
        return nil
    }

    // -------------------------
    // Contract state & factories
    // -------------------------
    access(all) var totalSupply: UInt64

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create FastbreakHorseRace.Collection()
    }

    // -------------------------
    // init
    // -------------------------
    init() {
        self.CollectionStoragePath = /storage/FastbreakHorseRaceCollection
        self.CollectionPublicPath  = /public/FastbreakHorseRaceCollection
        self.AdminStoragePath      = /storage/FastbreakHorseRaceAdmin

        self.totalSupply = 0

        // Store Admin resource directly (no nested-resource field)
        let admin <- create Admin()
        self.account.storage.save(<- admin, to: self.AdminStoragePath)

        // Store a collection in the contract account & publish a public cap
        let col <- create FastbreakHorseRace.Collection()
        self.account.storage.save(<- col, to: self.CollectionStoragePath)

        let colCap = self.account.capabilities.storage.issue<&FastbreakHorseRace.Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(colCap, at: self.CollectionPublicPath)
    }
}
