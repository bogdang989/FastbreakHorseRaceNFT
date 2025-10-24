## FastbreakHorseRaceNFT

Smart contract contest management deployed on **testnet**: A.8abec69aecbca039.FastbreakHorseRace

Production contest use on **mainnet**:
- A.6fd2465f3a22e34c.PetJokicsHorses ($MVP)
- A.1e4aa0b87d10b141.EVMVMBridgedToken_b73bf8e6a4477a952e0338e6cc00cc0ce5ad04ba ($FROTH bridged from EVM)
- A.9db94c9564243ba7.aiSportsJuice ($JUICE)

## About project

Are you playing NBA Top Shot? You feel good about yourself on a given day? 
Now you are able to boost your winnings by playing `Fastbreak Horse Race`, a mini game built on top of NBA Top Shot Fastbreak, where you predict which user ranks highest in a daily game.  
If you feel good about your lineup, bet on yourself and win even more!  
If you are tired of seeing someone else win in fastbreak all the time, bet on them and monetize your piled up frustration.


## How it works
- You chip in and predict which TS user will rank highest on the daily Fastbreak game on NBA Top Shot.
- You can bet on yourself or on someone else if you feel confident about them
- The higher your selected TS user ranks in Fastbreak, the higher you rank
- Unlimited entries, you can bet on anyone 


## Interacting with the smart contract
### Features (Implemented so far)

Create a contest (Admin):
- Create a contest tied to a fastbreak daily game. This mints a contest NFT to the contract address

Submit an entry
- Pay entry and submit your prediction

Payout (Admin)
- Distribute winnings based on the actual results to all winning wallets
- (Forte Scheduled Transaction) Schedule a payout to allow time to apply stat corrections before actual payout occurs

Destroy a contest (Admin)
- We can either hide a contest from UI by marking it hidden or completely destroy the contest NFT. 
- Complete audit trail is still available on the blockchain through historic transactions and events!

Get contest info:
- Get contest metadata
- List contests
- Get contest entries
- Preview payouts: Input the winning prediction and print out who wins how much based on the answer


Set variables for later
TESTNET:
```
$SIGNER = "fbhorseracedev2"
$CONTRACTADDR = "0x8abec69aecbca039"
$FLOWNETWORK = "testnet"
```

EMULATOR:
```
$SIGNER = "emulator-account"
$CONTRACTADDR = "0xf8d6e0586b0a20c7"
$FLOWNETWORK = "emulator"
```

Update contract:
```
flow project deploy --network $FLOWNETWORK --update 
```

List accounts:
```
flow accounts list
```

Add a deployment:
```
flow config add deployment
```

Create a contest (ADMIN):
```
flow transactions send .\cadence\transactions\create_contest.cdc "NBA Finals Game 1" "fb-123e4567-e89b-12d3-a456-426614174000" "FLOW" 1.00 1764501000.0 --signer $SIGNER -n $FLOWNETWORK
```

List contests:
```
flow scripts execute .\cadence\scripts\list_contests.cdc $CONTRACTADDR -n $FLOWNETWORK
```

Add entry:
```
flow transactions send .\cadence\transactions\add_entry.cdc $CONTRACTADDR 1 "Nuggets" --signer $SIGNER -n $FLOWNETWORK
```

Get contest info:
```
flow scripts execute .\cadence\scripts\get_contest_info.cdc $CONTRACTADDR 1 -n $FLOWNETWORK
```

Get contest entries:
```
flow scripts execute .\cadence\scripts\get_contest_entries.cdc $CONTRACTADDR 1 -n $FLOWNETWORK
```

Preview payouts:
```
flow scripts execute .\cadence\scripts\preview_payout.cdc $CONTRACTADDR 1 "Nuggets" -n $FLOWNETWORK
```

Execute payouts (ADMIN):
```
flow transactions send .\cadence\transactions\payout_winners.cdc 1 "Nuggets" --signer $SIGNER -n $FLOWNETWORK
```

Hide contest from UI (ADMIN):
```
flow transactions send .\cadence\transactions\toggle_hidden.cdc 1 --signer $SIGNER -n $FLOWNETWORK
```

Delete a contest NFT (ADMIN):
```
flow transactions send .\cadence\transactions\destroy_contest.cdc 1 --signer $SIGNER -n $FLOWNETWORK
```

Schedule payout using forte scheduled TXN (ADMIN):
```
flow transactions send .\cadence\transactions\schedule_payout_winners.cdc 1 "Nuggets" 30.0 0.10 1 1000 --signer $SIGNER -n $FLOWNETWORK
```

