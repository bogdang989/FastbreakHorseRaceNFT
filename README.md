## FastbreakHorseRaceNFT

Create a contest tied to a Fastbreak daily run where people predict which Topshot user will win the daily fastbreak run. 
Contract handles buy-ins and entry tracking. 
The real time Fastbreak data is pulled from Topshot API.

Set variables for later
TESTNET:
`$SIGNER = "fbhorseracedev2"`
`$CONTRACTADDR = "0x8abec69aecbca039"`
`$FLOWNETWORK = "testnet"`

EMULATOR:
`$SIGNER = "emulator-account"`
`$CONTRACTADDR = "0xf8d6e0586b0a20c7"`
`$FLOWNETWORK = "emulator"`

Update contract:
`flow project deploy --network testnet --update `

List accounts:
`flow accounts list`

Add a deployment:
`flow config add deployment`

Create a contest (ADMIN):
`flow transactions send .\cadence\transactions\create_contest.cdc "NBA Finals Game 1" "fb-123e4567-e89b-12d3-a456-426614174000" "FLOW" 1.00 1764501000.0 --signer $SIGNER -n $FLOWNETWORK`

List contests:
`flow scripts execute .\cadence\scripts\list_contests.cdc $CONTRACTADDR -n $FLOWNETWORK`

Add entry:
`flow transactions send .\cadence\transactions\add_entry.cdc $CONTRACTADDR 1 "Nuggets" --signer $SIGNER -n $FLOWNETWORK`

Get contest info:
`flow scripts execute .\cadence\scripts\get_contest_info.cdc $CONTRACTADDR 1 -n $FLOWNETWORK`

Get contest entries:
`flow scripts execute .\cadence\scripts\get_contest_entries.cdc $CONTRACTADDR 1 -n $FLOWNETWORK`

Preview payouts:
`flow scripts execute .\cadence\scripts\preview_payout.cdc $CONTRACTADDR 1 "Nuggets" -n $FLOWNETWORK`

Execute payouts (ADMIN):
`flow transactions send .\cadence\transactions\payout_winners.cdc 1 "Nuggets" --signer $SIGNER -n $FLOWNETWORK`

Hide contest from UI (ADMIN):
`flow transactions send .\cadence\transactions\toggle_hidden.cdc 1 --signer $SIGNER -n $FLOWNETWORK`

Delete a contest NFT (ADMIN):
`flow transactions send .\cadence\transactions\destroy_contest.cdc 1 --signer $SIGNER -n $FLOWNETWORK`

Schedule payout using forte scheduled TXN (ADMIN):
`flow transactions send .\cadence\transactions\schedule_payout_winners.cdc 1 "Nuggets" 30.0 0.10 1 1000 --signer $SIGNER -n $FLOWNETWORK`


## Usage (Implemented so far)

Create a contest (Admin):
- Create a contest tied to a fastbreak daily game

Submit an entry
- Pay entry and submit a TS username as your entry

Payout (Admin)
- Distribute winnings based on the actual results to all winning wallets

Destroy a contest (Admin)
- Either hide for UI or completely destroy NFT

Preview payouts:
- Submit the winning answer and print out who wins how much based on the answer

