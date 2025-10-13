## FastbreakHorseRaceNFT

Update contract:
`flow project deploy --network testnet --update `

List accounts:
`flow accounts list`

Add a deployment:
`flow config add deployment`

Create a contest:
`flow transactions send .\cadence\transactions\create_contest.cdc "NBA Finals Game 1" "fb-123e4567-e89b-12d3-a456-426614174000" "FLOW" 1.00 1731465600.0 --signer acc1`

List contests:
`flow scripts execute .\cadence\scripts\list_contests.cdc 0x179b6b1cb6755e31`

Get contest info:
`flow scripts execute .\cadence\scripts\get_contest_info.cdc 0x179b6b1cb6755e31 1`

Get contest entries:
`flow scripts execute .\cadence\scripts\get_contest_entries.cdc 0x179b6b1cb6755e31 1`

Add entry:
`flow transactions send .\cadence\transactions\add_entry.cdc 0x179b6b1cb6755e31 3 "Nuggets" --signer acc1`

Preview payouts:
`flow scripts execute .\cadence\scripts\preview_payout.cdc 0x179b6b1cb6755e31 3 "Nuggets"`

Hide contest from UI:
`flow transactions send .\cadence\transactions\toggle_hidden.cdc 1 --signer acc1`

## Usage (Implemented so far)

Create a contest (Admin):
- Create a contest tied to a fastbreak daily game

Submit an entry
- Pay entry and submit a TS username as your entry

Payout (Admin)
- Distribute winnings based on the actual results

Destroy a contest (Admin)
- Either hide for UI or completely destroy NFT

Preview payouts:
- Submit the winning answer and print out who wins how much based on the answer

