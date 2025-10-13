import "NonFungibleToken"
import "FungibleToken"
import "ViewResolver"
import "MetadataViews"
import "FlowToken"

// Forte (Scheduled Transactions)
import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"

access(all) contract FastbreakHorseRace: NonFungibleToken {

    // -------------------------
    // Standard Paths
    // -------------------------
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath

    // -------------------------
    // Scheduling (paths for our handler)
    // -------------------------
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath

    // -------------------------
    // Events
    // -------------------------
    access(all) event PayoutScheduled(
        contestId: UInt64,
        scheduledTxId: UInt64,
        executeAt: UFix64,
        priority: UInt8,
        effort: UInt64,
        fee: UFix64
    )

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
        access(all) var buyInCurrency: String    // e.g. "FLOW"
        access(all) var buyInAmount: UFix64      // token units
        access(all) var startTime: UFix64        // unix timestamp (seconds)
        access(all) var hidden: Bool             // UI toggle

        // Dynamic entries
        access(all) var entries: [Entry]

        // Mutable winner configuration (set by admin; read at payout time)
        access(all) var winningPrediction: String?   // nil until set

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
            self.winningPrediction = nil
        }

        // INTERNAL: append an entry (no payment) — only callable from this contract.
        access(contract) fun addEntry(wallet: Address, prediction: String, time: UFix64) {
            pre { time < self.startTime: "Contest already started" }
            let e = Entry(wallet: wallet, prediction: prediction, timeOfEntry: time)
            self.entries.append(e)
        }

        // PUBLIC: atomic entry + payment
        access(all) fun submitEntry(
            wallet: Address,
            prediction: String,
            payment: @{FungibleToken.Vault},
            time: UFix64
        ) {
            pre {
                time < self.startTime: "Contest already started"
                payment.balance == self.buyInAmount: "Payment must equal buy-in amount"
            }

            FastbreakHorseRace.depositBuyIn(
                currency: self.buyInCurrency,
                payment: <- payment
            )

            let e = Entry(wallet: wallet, prediction: prediction, timeOfEntry: time)
            self.entries.append(e)
        }

        // Admin-only setter for winning prediction (entitlement-gated)
        access(NonFungibleToken.Update) fun setWinningPrediction(_ p: String?) {
            self.winningPrediction = p
        }

        // UI toggle
        access(all) fun toggleHidden() { self.hidden = !self.hidden }

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

        init() { self.ownedNFTs <- {} }

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
        access(all) view fun getIDs(): [UInt64] { return self.ownedNFTs.keys }
        access(all) view fun getLength(): Int { return self.ownedNFTs.length }
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? { return &self.ownedNFTs[id] }

        // Entitled, typed ref for admin updates (e.g., setWinningPrediction)
        access(all) fun borrowContestForUpdate(_ id: UInt64): auth(NonFungibleToken.Update) &FastbreakHorseRace.NFT? {
            if let anyRef = &self.ownedNFTs[id] as auth(NonFungibleToken.Update) &{NonFungibleToken.NFT}? {
                return anyRef as! auth(NonFungibleToken.Update) &FastbreakHorseRace.NFT
            }
            return nil
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

        // Ensure Admin methods are called only by the contract owner
        access(self) fun assertOwner() {
            pre {
                self.owner?.address == FastbreakHorseRace.account.address:
                    "Only the contract owner may call this Admin method"
            }
        }

        // ---- Contest lifecycle
        access(all) fun createContest(
            displayName: String,
            fastbreakId: String,
            buyInCurrency: String,
            buyInAmount: UFix64,
            startTime: UFix64
        ): @FastbreakHorseRace.NFT {
            self.assertOwner()
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

        access(all) fun destroyContest(
            collectionRef: auth(NonFungibleToken.Withdraw) &FastbreakHorseRace.Collection,
            id: UInt64
        ) {
            self.assertOwner()
            let nft <- collectionRef.withdraw(withdrawID: id) as! @FastbreakHorseRace.NFT
            destroy nft
        }

        access(all) fun toggleHidden(
            collectionRef: &FastbreakHorseRace.Collection,
            id: UInt64
        ) {
            self.assertOwner()
            let anyRef = collectionRef.borrowNFT(id) ?? panic("Contest not found")
            let nftRef = anyRef as! &FastbreakHorseRace.NFT
            nftRef.toggleHidden()
        }

        // ---- Winners config (on the NFT itself, via entitled setter)
        access(all) fun setWinningPrediction(contestId: UInt64, prediction: String) {
            self.assertOwner()
            let col = FastbreakHorseRace.account.storage.borrow<&FastbreakHorseRace.Collection>(
                from: FastbreakHorseRace.CollectionStoragePath
            ) ?? panic("Owner collection not found")
            let nftUpd = col.borrowContestForUpdate(contestId)
                ?? panic("Contest not found or cannot borrow update ref")
            nftUpd.setWinningPrediction(prediction)
        }

        // ---- Payout (manual)
        access(all) fun payoutWinners(
            collectionRef: &FastbreakHorseRace.Collection,
            id: UInt64,
            winningPrediction: String,
            receivers: {Address: &{FungibleToken.Receiver}}
        ) {
            self.assertOwner()

            let anyRef = collectionRef.borrowNFT(id) ?? panic("Contest not found")
            let nftRef = anyRef as! &FastbreakHorseRace.NFT
            let entries = nftRef.entries

            let winners = entries.filter(view fun (e: FastbreakHorseRace.Entry): Bool {
                return e.prediction == winningPrediction
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
                recv.deposit(from: <- pay)
                i = i + 1
            }
        }

        // ---- Schedule payout (auto, reads NFT.winningPrediction at execution)
        access(all) fun schedulePayout(
            contestId: UInt64,
            executeAfterSeconds: UFix64,
            feeAmount: UFix64,
            priority: UInt8,
            effort: UInt64
        ) {
            self.assertOwner()

            // 0) Ensure we have a scheduler Manager in storage
            if !FastbreakHorseRace.account.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(
                from: FlowTransactionSchedulerUtils.managerStoragePath
            ) {
                let mgr <- FlowTransactionSchedulerUtils.createManager()
                FastbreakHorseRace.account.storage.save(<- mgr, to: FlowTransactionSchedulerUtils.managerStoragePath)

                // optional read-only cap
                let cap = FastbreakHorseRace.account.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(
                    FlowTransactionSchedulerUtils.managerStoragePath
                )
                FastbreakHorseRace.account.capabilities.publish(cap, at: FlowTransactionSchedulerUtils.managerPublicPath)
            }

            // 1) Ensure handler exists in storage
            if !FastbreakHorseRace.account.storage.check<@FastbreakHorseRace.PayoutHandler>(
                from: FastbreakHorseRace.HandlerStoragePath
            ) {
                let h <- FastbreakHorseRace.createPayoutHandler()
                FastbreakHorseRace.account.storage.save(<- h, to: FastbreakHorseRace.HandlerStoragePath)
            }

            // 2) Issue the EXECUTE-authorized handler capability from storage
            let execHandlerCap = FastbreakHorseRace.account.capabilities.storage.issue<
                auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}
            >(FastbreakHorseRace.HandlerStoragePath)

            // 3) Compute executeAt
            let now = getCurrentBlock().timestamp
            let executeAt = now + executeAfterSeconds

            // 4) Withdraw FLOW fees from the contract’s Flow vault
            let vault = FastbreakHorseRace.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: /storage/flowTokenVault
            ) ?? panic("Contract Flow vault missing for fees")
            let fees <- vault.withdraw(amount: feeAmount) as! @FlowToken.Vault

            // 5) Borrow manager and schedule with the exec-capability
            let manager = FastbreakHorseRace.account.storage.borrow<
                auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}
            >(from: FlowTransactionSchedulerUtils.managerStoragePath)
                ?? panic("Manager not found after creation")

            let pr = FlowTransactionScheduler.Priority(rawValue: priority)
                ?? FlowTransactionScheduler.Priority.Medium

            let scheduledId = manager.schedule(
                handlerCap: execHandlerCap,
                data: contestId,                // pass contestId; handler will read NFT.winningPrediction
                timestamp: executeAt,
                priority: pr,
                executionEffort: effort,
                fees: <- fees
            )

            emit PayoutScheduled(
                contestId: contestId,
                scheduledTxId: scheduledId,
                executeAt: executeAt,
                priority: priority,
                effort: effort,
                fee: feeAmount
            )
        }
    }

    // -------------------------
    // Scheduled Transaction Handler (executes later)
    // -------------------------
    access(all) resource PayoutHandler: FlowTransactionScheduler.TransactionHandler {
        // The protocol calls this with EXECUTE entitlement
        access(FlowTransactionScheduler.Execute)
        fun executeTransaction(id: UInt64, data: AnyStruct?) {
            // contestId passed in data
            let contestId = data as! UInt64

            // Borrow owner collection & Admin
            let col = FastbreakHorseRace.account.storage.borrow<&FastbreakHorseRace.Collection>(
                from: FastbreakHorseRace.CollectionStoragePath
            ) ?? panic("Owner collection not found")

            let admin = FastbreakHorseRace.account.storage.borrow<&FastbreakHorseRace.Admin>(
                from: FastbreakHorseRace.AdminStoragePath
            ) ?? panic("Admin not found")

            // Borrow contest
            let anyRef = col.borrowNFT(contestId) ?? panic("Contest not found")
            let nft = anyRef as! &FastbreakHorseRace.NFT

            // FLOW-only payouts
            if nft.buyInCurrency != "FLOW" {
                panic("Scheduled payout supports FLOW only, contest uses ".concat(nft.buyInCurrency))
            }

            // Read CURRENT winningPrediction from the NFT
            let winOpt = nft.winningPrediction
            if winOpt == nil {
                panic("Winning prediction not set on contest ".concat(contestId.toString()))
            }
            let win = winOpt!

            // Build receivers map from winners’ Flow receivers
            let recvs: {Address: &{FungibleToken.Receiver}} = {}
            var i = 0
            while i < nft.entries.length {
                let e = nft.entries[i]
                if e.prediction == win {
                    if recvs[e.wallet] == nil {
                        let cap = getAccount(e.wallet).capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                        let r = cap.borrow()
                            ?? panic("Winner missing /public/flowTokenReceiver: ".concat(e.wallet.toString()))
                        recvs[e.wallet] = r
                    }
                }
                i = i + 1
            }

            // Delegate to Admin payout (owner-guarded + uses contract-only withdraw)
            admin.payoutWinners(
                collectionRef: col,
                id: contestId,
                winningPrediction: win,
                receivers: recvs
            )
        }

        access(all) view fun getViews(): [Type] { return [] }
        access(all) fun resolveView(_ view: Type): AnyStruct? { return nil }
    }

    access(all) fun createPayoutHandler(): @PayoutHandler { return <- create PayoutHandler() }

    // -------------------------
    // Treasury (FLOW uses /storage/flowTokenVault)
    // -------------------------
    access(self) fun vaultStoragePath(currency: String): StoragePath {
        return StoragePath(identifier: "FHR_".concat(currency).concat("_Vault"))!
    }
    access(self) fun vaultReceiverPublicPath(currency: String): PublicPath {
        return PublicPath(identifier: "FHR_".concat(currency).concat("_Receiver"))!
    }

    access(self) fun ensureVaultReady(currency: String, received: @{FungibleToken.Vault}): &{FungibleToken.Receiver} {
        if currency == "FLOW" {
            let sPath: StoragePath = /storage/flowTokenVault
            let pPath: PublicPath  = /public/flowTokenReceiver

            if self.account.storage.borrow<&{FungibleToken.Vault}>(from: sPath) == nil {
                self.account.storage.save(
                    <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>()),
                    to: sPath
                )
                if !self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).check() {
                    let cap = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(sPath)
                    self.account.capabilities.publish(cap, at: pPath)
                }
            }

            let recv = self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).borrow()
                ?? panic("FLOW receiver missing on contract account")
            recv.deposit(from: <- received)
            return recv
        }

        let sPath = self.vaultStoragePath(currency: currency)
        let pPath = self.vaultReceiverPublicPath(currency: currency)

        if self.account.storage.borrow<&{FungibleToken.Vault}>(from: sPath) == nil {
            self.account.storage.save(<- received, to: sPath)
            if !self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).check() {
                let cap = self.account.capabilities.storage.issue<&{FungibleToken.Receiver}>(sPath)
                self.account.capabilities.publish(cap, at: pPath)
            }
            let recv = self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).borrow()
                ?? panic("Receiver missing after vault init")
            return recv
        }

        let recv2 = self.account.capabilities.get<&{FungibleToken.Receiver}>(pPath).borrow()
            ?? panic("Receiver missing for currency ".concat(currency))
        recv2.deposit(from: <- received)
        return recv2
    }

    access(all) fun depositBuyIn(currency: String, payment: @{FungibleToken.Vault}) {
        var _ = self.ensureVaultReady(currency: currency, received: <- payment)
    }

    // Contract-only withdraw for payouts
    access(contract) fun withdrawFromTreasury(currency: String, amount: UFix64): @{FungibleToken.Vault} {
        if currency == "FLOW" {
            let base = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: /storage/flowTokenVault
            ) ?? panic("Contract Flow vault missing")
            let taken <- base.withdraw(amount: amount)
            return <- (taken as @{FungibleToken.Vault})
        }

        let sPath = self.vaultStoragePath(currency: currency)
        let base = self.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: sPath)
            ?? panic("Treasury vault not found for ".concat(currency))
        let taken <- base.withdraw(amount: amount)
        return <- (taken as @{FungibleToken.Vault})
    }

    // -------------------------
    // Contract Views
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

        self.HandlerStoragePath    = /storage/FHR_PayoutHandler
        self.HandlerPublicPath     = /public/FHR_PayoutHandler

        self.totalSupply = 0

        // Save Admin resource
        let admin <- create Admin()
        self.account.storage.save(<- admin, to: self.AdminStoragePath)

        // Save a collection & publish cap
        let col <- create FastbreakHorseRace.Collection()
        self.account.storage.save(<- col, to: self.CollectionStoragePath)
        let colCap = self.account.capabilities.storage.issue<&FastbreakHorseRace.Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(colCap, at: self.CollectionPublicPath)
    }
}
