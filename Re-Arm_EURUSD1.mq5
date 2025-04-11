//+------------------------------------------------------------------+
//|                                               Re-Arm_EURUSD1.mq5 |
//|                                           Ruby Enrique M. Armian |
//|                                     rubyenriquearmian3@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Ruby Enrique M. Armian"
#property link      "rubyenriquearmian3@gmail.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalMA.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include <Expert\Money\MoneyFixedLot.mqh>
#include <Trade\DealInfo.mqh> // Include for accessing deal history details

//+------------------------------------------------------------------+
//| OUR CUSTOM GLOBAL VARIABLES                                      |
//+------------------------------------------------------------------+
bool isFirstTrade = true;              // Flag to check if it's the initial trade
bool lastTradeWon = false;             // Did the last closed trade win?
int  lastTradeDirection = -1;          // What was the direction? -1=None, 0=Buy, 1=Sell
//--- We need access to the trading object later
#include <Trade\Trade.mqh>
CTrade trade;                          // Trading object
CDealInfo dealInfo;           // Object to easily get info about historical deals

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
input string             Expert_Title         ="Re-Arm_EURUSD1"; // Document name
ulong                    Expert_MagicNumber   =16568;            //
bool                     Expert_EveryTick     =false;            //
//--- inputs for main signal
input int                Signal_ThresholdOpen =10;               // Signal threshold value to open [0...100]
input int                Signal_ThresholdClose=10;               // Signal threshold value to close [0...100]
input double             Signal_PriceLevel    =0.0;              // Price level to execute a deal
input double             Signal_StopLevel     =50.0;             // Stop Loss level (in points)
input double             Signal_TakeLevel     =50.0;             // Take Profit level (in points)
input int                Signal_Expiration    =4;                // Expiration of pending orders (in bars)
input int                Signal_MA_PeriodMA   =12;               // Moving Average(12,0,...) Period of averaging
input int                Signal_MA_Shift      =0;                // Moving Average(12,0,...) Time shift
input ENUM_MA_METHOD     Signal_MA_Method     =MODE_SMA;         // Moving Average(12,0,...) Method of averaging
input ENUM_APPLIED_PRICE Signal_MA_Applied    =PRICE_CLOSE;      // Moving Average(12,0,...) Prices series
input double             Signal_MA_Weight     =1.0;              // Moving Average(12,0,...) Weight [0...1.0]
//--- inputs for money
input double             Money_FixLot_Percent =10.0;             // Percent
input double             Money_FixLot_Lots    =0.01;             // Fixed volume
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),Expert_EveryTick,Expert_MagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(Signal_ThresholdOpen);
   signal.ThresholdClose(Signal_ThresholdClose);
   signal.PriceLevel(Signal_PriceLevel);
   signal.StopLevel(Signal_StopLevel);
   signal.TakeLevel(Signal_TakeLevel);
   signal.Expiration(Signal_Expiration);
//--- Creating filter CSignalMA
   CSignalMA *filter0=new CSignalMA;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   // signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.PeriodMA(Signal_MA_PeriodMA);
   filter0.Shift(Signal_MA_Shift);
   filter0.Method(Signal_MA_Method);
   filter0.Applied(Signal_MA_Applied);
   filter0.Weight(Signal_MA_Weight);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   CMoneyFixedLot *money=new CMoneyFixedLot; //watermark :3
   if(money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set money parameters
   money.Percent(Money_FixLot_Percent);
   money.Lots(Money_FixLot_Lots);
//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
// ExtExpert.OnTick(); // Keep this commented out

// --- Check if position for THIS EA on THIS symbol is already open ---
   bool isTradeOpen = false;
   if(PositionSelect(Symbol()))
     {
      if(PositionGetInteger(POSITION_MAGIC) == Expert_MagicNumber)
        {
         isTradeOpen = true;
        }
     }

// If a trade managed by this EA is already open, do nothing further this tick
   if(isTradeOpen)
     {
      return;
     }

// --- If we reached here, it means no trade is open for this EA on this symbol ---

   if(isFirstTrade)
     {
      // --- Place the very first trade using the helper function ---
      Print("No position open. Placing initial Buy order...");
      if(PlaceBuyOrder(Money_FixLot_Lots, "Initial Buy")) // Call helper
        {
         isFirstTrade = false;       // Mark first trade done
         lastTradeDirection = ORDER_TYPE_BUY; // Record direction
        }
     }
   else // It's NOT the first trade
     {
      // --- Decide next trade based on last trade's result ---
      // !!! IMPORTANT: lastTradeWon is currently always false! We need OnTrade logic later.
      Print("No position open. Last trade won: ", lastTradeWon, ". Deciding next trade...");

      int nextTradeDirection = -1; // Variable to hold the direction for the next trade

      if(lastTradeWon) // If last trade won, repeat the last direction
        {
         nextTradeDirection = lastTradeDirection;
         Print("--> Repeating last direction: ", (nextTradeDirection == ORDER_TYPE_BUY ? "Buy" : (nextTradeDirection == ORDER_TYPE_SELL ? "Sell" : "None")));
        }
      else // If last trade lost, reverse the last direction
        {
         // Check previous direction and reverse it
         if(lastTradeDirection == ORDER_TYPE_BUY)
           {
            nextTradeDirection = ORDER_TYPE_SELL; // If last was Buy, next is Sell
           }
         else // If last was Sell (or None initially, though shouldn't happen here)
           {
            nextTradeDirection = ORDER_TYPE_BUY; // If last was Sell, next is Buy
           }
         Print("--> Reversing last direction. Next is: ", (nextTradeDirection == ORDER_TYPE_BUY ? "Buy" : "Sell"));
        }

      // --- Place the determined trade using helper functions ---
      bool placed_successfully = false;
      if(nextTradeDirection == ORDER_TYPE_BUY)
        {
         placed_successfully = PlaceBuyOrder(Money_FixLot_Lots, "Subsequent Buy");
        }
      else if(nextTradeDirection == ORDER_TYPE_SELL)
        {
         placed_successfully = PlaceSellOrder(Money_FixLot_Lots, "Subsequent Sell");
        }
      else
        {
         Print("Error: Invalid nextTradeDirection determined.");
        }

      // If placing the trade worked, update the last direction state
      if(placed_successfully)
        {
         lastTradeDirection = nextTradeDirection;
        }
        
     } // End of 'else' for subsequent trades
     
  } // End of OnTick function
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
// ExtExpert.OnTrade(); // Keep commented out or remove

// --- Check if OUR position for this symbol *just* closed ---

// First, check if currently no position is open for us right now
   bool isOurPositionCurrentlyOpen = false;
   if(PositionSelect(Symbol())) // Try selecting a position on this symbol
     {
      if(PositionGetInteger(POSITION_MAGIC) == Expert_MagicNumber) // Check if it's ours
        {
         isOurPositionCurrentlyOpen = true;
        }
     }

// If no position is currently open NOW,
// AND we know what the last trade's direction was (meaning a trade HAD been placed),
// THEN our trade must have just closed.
   if(!isOurPositionCurrentlyOpen && lastTradeDirection != -1)
     {
      Print("OnTrade: Detected our position closed.");

      // Get the ticket of the very last deal in the account history
      // Note: This assumes no other EAs/manual trades are closing instantly after ours. Robustness could be improved.
      ulong lastDealTicket = 0;
      if(HistoryDealsTotal() > 0) // Make sure history is not empty
         lastDealTicket = HistoryDealGetTicket(HistoryDealsTotal() - 1);
      else
        {
         Print("OnTrade: HistoryDealsTotal is zero, cannot check last deal.");
         return; // Exit if no history
        }


      // Try to select this last deal from history
      if(HistoryDealSelect(lastDealTicket))
        {
         // Check if this last deal belongs to our EA (magic number) and symbol
         if(dealInfo.Magic() == Expert_MagicNumber && dealInfo.Symbol() == Symbol())
           {
            // Check if it represents a position closing event
            // DEAL_ENTRY_OUT = closing by SL/TP or manually closing a simple position
            // DEAL_ENTRY_INOUT = closing part of a position due to a reversal trade (less likely for us now)
            if(dealInfo.Entry() == DEAL_ENTRY_OUT || dealInfo.Entry() == DEAL_ENTRY_INOUT)
              {
               // Get the profit of this closing deal
               double profit = dealInfo.Profit();

               // Update our crucial state variable based on profit
               lastTradeWon = (profit >= 0.0); // Treat break-even (profit=0) as a "win"

               Print("OnTrade: Last trade closed. Ticket: ", lastDealTicket, ", Profit: ", profit, ", LastTradeWon set to: ", lastTradeWon);

               // Optional: We could reset lastTradeDirection = -1 here if we only want OnTrade to process
               // the result once, but OnTick needs the direction, so we leave it for now.
              }
            else
              {
               // Print("OnTrade: Last deal (", lastDealTicket, ") was ours, but not a closing deal (Entry=", dealInfo.Entry(), ").");
              }
           }
         else
           {
             // Print("OnTrade: Last deal (",lastDealTicket,") was not ours (Magic/Symbol mismatch).");
           }
        }
      else
        {
         Print("OnTrade: Error selecting last deal from history (Ticket: ", lastDealTicket, ") - Error code: ", GetLastError());
        }
     } // End if position just closed
   // Optional else block for debugging other OnTrade triggers if needed later
   // else { // Print("OnTrade triggered, but our position still open or not yet placed."); }

  } // End OnTrade function
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Helper function to place a Buy order                             |
//+------------------------------------------------------------------+
bool PlaceBuyOrder(double volume, string comment)
  {
   // Get current market prices and point value
   double ask_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   // Use SL/TP from inputs (ensure they are positive, using 50 points as fallback)
   double sl_points = (Signal_StopLevel > 0) ? Signal_StopLevel : 50.0;
   double tp_points = (Signal_TakeLevel > 0) ? Signal_TakeLevel : 50.0;

   // Calculate absolute SL and TP prices
   double stop_loss_price = NormalizeDouble(ask_price - sl_points * point, digits);
   double take_profit_price = NormalizeDouble(ask_price + tp_points * point, digits);

   // Use the CTrade object to place the order
   bool order_placed = trade.Buy(volume, Symbol(), ask_price, stop_loss_price, take_profit_price, comment);

   // Check results and return true/false
   if(order_placed && (trade.ResultRetcode() == TRADE_RETCODE_DONE || trade.ResultRetcode() == TRADE_RETCODE_PLACED))
     {
      Print(comment, " order placed successfully. Ticket: ", trade.ResultOrder());
      return(true); // Success
     }
   else
     {
      Print("Failed to place ", comment, " order. Error: ", trade.ResultComment(), " (Code: ", trade.ResultRetcode(), "), LastError: ", GetLastError());
      return(false); // Failure
     }
  }

//+------------------------------------------------------------------+
//| Helper function to place a Sell order                            |
//+------------------------------------------------------------------+
bool PlaceSellOrder(double volume, string comment)
  {
   // Get current market prices and point value
   double bid_price = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);

   // Use SL/TP from inputs (ensure they are positive, using 50 points as fallback)
   double sl_points = (Signal_StopLevel > 0) ? Signal_StopLevel : 50.0;
   double tp_points = (Signal_TakeLevel > 0) ? Signal_TakeLevel : 50.0;

   // Calculate absolute SL and TP prices (Note: SL is above price, TP is below for Sell)
   double stop_loss_price = NormalizeDouble(bid_price + sl_points * point, digits);
   double take_profit_price = NormalizeDouble(bid_price - tp_points * point, digits);

   // Use the CTrade object to place the order
   bool order_placed = trade.Sell(volume, Symbol(), bid_price, stop_loss_price, take_profit_price, comment);

    // Check results and return true/false
   if(order_placed && (trade.ResultRetcode() == TRADE_RETCODE_DONE || trade.ResultRetcode() == TRADE_RETCODE_PLACED))
     {
      Print(comment, " order placed successfully. Ticket: ", trade.ResultOrder());
      return(true); // Success
     }
   else
     {
      Print("Failed to place ", comment, " order. Error: ", trade.ResultComment(), " (Code: ", trade.ResultRetcode(), "), LastError: ", GetLastError());
      return(false); // Failure
     }
  }
// --- END OF HELPER FUNCTIONS ---