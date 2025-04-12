# MQL5 Tit-for-Tat EA Experiment (Re-Arm_EURUSD1)

## Description

This is an experimental Expert Advisor (EA) for the MetaTrader 5 platform. It implements a trading strategy inspired by the "Tit-for-Tat" concept often discussed in game theory.

The core logic is:
1.  Place an initial Buy order with a predefined Stop Loss (SL) and Take Profit (TP).
2.  If the last closed trade resulted in a win or break-even, the EA places the next trade in the **same** direction as the last one.
3.  If the last closed trade resulted in a loss, the EA places the next trade in the **opposite** direction of the last one.

This project was primarily created as a learning exercise in MQL5 programming and automated strategy implementation.

## Current Status

* **Version:** 1.00
* **Stage:** Development / Work-in-Progress
* **Functionality:**
    * Core Tit-for-Tat logic implemented in `OnTick()` and `OnTrade()`.
    * Helper functions for placing Buy/Sell orders created.
    * Basic state tracking (first trade, last win/loss, last direction) included.
    * Uses fixed lot size, configurable SL/TP points.
* **Testing:** **Backtesting is currently pending** due to local machine resource limitations. The EA's logical flow needs verification via Strategy Tester Journal logs.

## How to Use

1.  **Platform:** Requires the MetaTrader 5 desktop terminal.
2.  **Installation:** Place the `Re-Arm_EURUSD1.mq5` file into your MetaTrader 5 Data Folder, under the `MQL5\Experts\` directory.
    * (You can find the Data Folder via `File -> Open Data Folder` in the MT5 terminal).
3.  **Compilation:** Open the `Re-Arm_EURUSD1.mq5` file in MetaEditor (press F4 in MT5 terminal or double-click the file). Compile the code by pressing F7 or clicking the "Compile" button. Ensure you get "0 error(s)".
4.  **Attachment:** In the MT5 terminal, find "Re-Arm_EURUSD1" under "Expert Advisors" in the "Navigator" panel. Drag it onto the chart you wish to use (e.g., EURUSD, H1 timeframe recommended for initial observation).
5.  **Configuration:** Ensure "Algo Trading" is enabled (button in the main toolbar should be green). Adjust input parameters if desired when attaching the EA or via `Right-click on chart -> Expert Advisors -> Properties`.

## Input Parameters

* `Expert_Title`: Name used for comments/identification (Default: "Re-Arm_EURUSD1").
* `Expert_MagicNumber`: Unique ID for trades placed by this EA instance (Default: 16568).
* `Expert_EveryTick`: Set to `false` (logic runs once per bar by default via framework, though our custom `OnTick` runs more often - keep `false`).
* `Signal_StopLevel`: Stop Loss distance in **Points** (Default: 50.0).
* `Signal_TakeLevel`: Take Profit distance in **Points** (Default: 50.0).
* `Money_FixLot_Lots`: The fixed trading volume for each order (Default: 0.01).
* *(Other `Signal_...` parameters related to the placeholder MA filter are ignored by the current custom logic)*.

## Data Interpretation

* **Automated data interpretation:**
    * Coming soon (potentially a script to parse logs).

* **Manual data interpretation:**
    * The primary way to understand the EA's step-by-step behavior and decisions during a backtest is by examining the **Journal** log output in the MetaTrader 5 Strategy Tester. We have added specific `Print()` messages to track the core logic.
    * Below is an **example snippet** (mixing our EA's messages and standard MT5 logs) and how to read our key messages:

    ```log
    DI	0	12:36:23.853	Core 1	2025.04.01 00:01:00   No position open. Placing initial Buy order...
    CN	0	12:36:23.853	Core 1	2025.04.01 00:01:00   instant buy 0.01 GBPUSD at 1.29138 sl: 1.29088 tp: 1.29188 (1.29108 / 1.29138 / 1.29108)
    FP	0	12:36:23.853	Core 1	2025.04.01 00:01:00   deal #2 buy 0.01 GBPUSD at 1.29138 done (based on order #2)
    FQ	0	12:36:23.853	Core 1	2025.04.01 00:01:00   deal performed [#2 buy 0.01 GBPUSD at 1.29138]
    HF	0	12:36:23.853	Core 1	2025.04.01 00:01:00   order performed buy 0.01 at 1.29138 [#2 buy 0.01 GBPUSD at 1.29138]
    RH	0	12:36:23.853	Core 1	2025.04.01 00:01:00   CTrade::OrderSend: instant buy 0.01 GBPUSD at 1.29138 sl: 1.29088 tp: 1.29188 [done at 1.29138]
    LJ	0	12:36:23.853	Core 1	2025.04.01 00:01:00   Initial Buy order placed successfully. Ticket: 2
    NK	0	12:36:23.853	Core 1	2025.04.01 00:01:00   OnTrade: Detected our position closed.
    HN	0	12:36:23.853	Core 1	2025.04.01 00:01:00   OnTrade: Detected our position closed.
    JQ	0	12:36:23.853	Core 1	2025.04.01 00:01:00   OnTrade: Detected our position closed.
    JF	0	12:36:23.853	Core 1	2025.04.01 00:01:10   No position open. Last trade won: false. Deciding next trade...
    PI	0	12:36:23.853	Core 1	2025.04.01 00:01:10   --> Reversing last direction. Next is: Sell
    RP	0	12:36:23.853	Core 1	2025.04.01 00:01:10   instant sell 0.01 GBPUSD at 1.29099 sl: 1.29149 tp: 1.29049 (1.29099 / 1.29129 / 1.29099)
    IL	0	12:36:23.853	Core 1	2025.04.01 00:01:10   deal #3 sell 0.01 GBPUSD at 1.29099 done (based on order #3)
    ```

* **Explanation of Key Messages:**
    1.  `DI ... No position open. Placing initial Buy order...`: Our EA (in `OnTick`) detected no open trade and is initiating the first trade (always a Buy).
    2.  `LJ ... Initial Buy order placed successfully. Ticket: 2`: Our EA confirmed the Buy order was accepted by the server.
    3.  `NK/HN/JQ ... OnTrade: Detected our position closed.`: Our EA (in `OnTrade`) detected that the position it was tracking is now closed. (Note: `OnTrade` might trigger multiple times per event).
    4.  *(Missing Message Example)*: After the closure detection, a message like `OnTrade: Last trade closed. Ticket: 2, Profit: -5.00, LastTradeWon set to: false` **should appear** in a real run, showing the profit/loss from history and confirming the update to the `lastTradeWon` variable. This specific line is missing from the sample snippet above but is crucial to the logic.
    5.  `JF ... No position open. Last trade won: false. Deciding next trade...`: Our EA (in `OnTick` again) sees no open trade and checks the status of `lastTradeWon` (which was set to `false` by the logic described in the missing step 4).
    6.  `PI ... --> Reversing last direction. Next is: Sell`: Based on `lastTradeWon` being `false`, the EA correctly decides to reverse the previous direction (which was Buy) and place a Sell order next.
    7.  The subsequent lines show the Sell order being placed and executed.

* By following these custom `Print` messages in the Journal, you can trace the decision-making process of the Tit-for-Tat logic.

## Disclaimer

**⚠️ IMPORTANT: This is experimental code created solely for learning and demonstration purposes. It has NOT been thoroughly backtested or optimized due to system limitations and is provided "AS IS" without warranty of any kind.**

* **Do NOT use this EA on a live trading account.**
* There is no guarantee of profitability or error-free operation.
* Trading Forex involves significant risk, and you could lose your invested capital.
* Use this code entirely at your own risk after extensive testing and understanding its behavior on a demo account.

## Author

* Ruby Enrique M. Armian

## License

This project is licensed under the MIT License - see the `LICENSE` file for details.

