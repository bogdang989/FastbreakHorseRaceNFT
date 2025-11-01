
# 🏇 FastBreak Horse Race — Predict, Bet & Boost on NBA Top Shot

**Live:** [https://mvponflow.cc/fastbreak](https://mvponflow.cc/fastbreak)

**Built on Flow blockchain**

Smart contract contest management deployed on **testnet**: 
- A.8abec69aecbca039.FastbreakHorseRace

Production contest uses on **mainnet**:
- A.6fd2465f3a22e34c.PetJokicsHorses ($MVP)
- A.1e4aa0b87d10b141.EVMVMBridgedToken_b73bf8e6a4477a952e0338e6cc00cc0ce5ad04ba ($FROTH bridged from EVM)
- A.9db94c9564243ba7.aiSportsJuice ($JUICE)
- A.05b67ba314000b2d.TSHOT ($TSHOT)

---

## 🎯 Short Summary

**FastBreak Horse Race** turns **NBA Top Shot FastBreak leaderboards** into a live on-chain prediction game.  
Players predict which competitor will win each FastBreak run, bet **Flow tokens** to boost their potential winnings, and even stake on themselves.

---

## 🏀 The Concept

Every day, **NBA Top Shot** runs FastBreak contests — competitive stat-based challenges between collectors.  
**FastBreak Horse Race** adds a prediction and wagering layer on top of those contests.

---

## ⚙️ How It Works

### 🏁 Contest Setup
The admin launches a contest tied to a specific **FastBreak ID** on Top Shot.

### 🔮 Predictions Phase
- Users predict the winner (any Top Shot username).  
- A detailed history of previous performance for each user is available for stat nerds.  
- They can wager **Flow tokens** to back their pick.  
- Bets remain hidden until the game starts.

### 🔒 Lock-In & Results
- Once the FastBreak starts, predictions close.  
- After the last game of the day is over, the pot is paid to the player who selected the **highest-ranked user** among predictions.

---

## 💡 Built With

- 🧠 **Flow Smart Contract:** For contest, prediction, and payout tracking  
- ⚙️ **Flow Cadence Transactions:** Handling buy-ins and prize distribution  
- 🏀 **NBA Top Shot API:** Fetching real contest results for validation  

---

## 💰 The Gameplay Loop

1. 🕹️ **Join** a FastBreak contest channel  
2. 🏇 **Predict** the winner — or back yourself  
3. 📈 **Watch** the leaderboard evolve live  
4. 🪙 **Earn** token rewards for correct predictions  

---

## 🧱 Built During the Hackathon

During the hackathon, the focus was on bringing contest logic fully on-chain and expanding the Dapper ecosystem’s gaming layer.  

### Key Milestones

- 🪙 **Integrated $JUICE and $FROTH tokens** as native contest currencies — multiple slates already successfully played.  
- ⚙️ **Moved contest tracking logic** from a traditional SQL database into a **Flow smart contract**, enabling on-chain transparency for entries, wagers, and results *(on testnet).*  
- 📊 **Executed full contest cycles** using live FastBreak data from the **NBA Top Shot API** — from prediction to payout.

