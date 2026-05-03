//+------------------------------------------------------------------+
//|                                     GoldSwingConservative.mq5   |
//|                                        Gold Swing EA - H4       |
//|                              Conservative | Risk 1% | RR 1:1.67 |
//+------------------------------------------------------------------+
#property copyright "Gold Swing Conservative EA"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== Indicator Settings ==="
input int    EMA_Fast       = 50;       // EMA Fast Period
input int    EMA_Slow       = 200;      // EMA Slow Period
input int    RSI_Period     = 14;       // RSI Period
input int    ATR_Period     = 14;       // ATR Period

input group "=== Entry Settings ==="
input double RSI_BuyLevel   = 40.0;    // RSI Buy Level (Oversold zone)
input double RSI_SellLevel  = 60.0;    // RSI Sell Level (Overbought zone)

input group "=== Risk Management ==="
input double RiskPercent    = 1.0;     // Risk per trade (%)
input double SL_ATR_Multi   = 1.5;    // SL Multiplier (x ATR)
input double TP_ATR_Multi   = 2.5;    // TP Multiplier (x ATR)
input int    MagicNumber    = 20250503; // Magic Number

//--- Global Variables
CTrade trade;
int    emaFastHandle, emaSlowHandle, rsiHandle, atrHandle;
double emaFastBuf[], emaSlowBuf[], rsiBuf[], atrBuf[];
bool   rsiWasBelow40 = false;
bool   rsiWasAbove60 = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Set trade magic number
   trade.SetExpertMagicNumber(MagicNumber);

   //--- Create indicator handles
   emaFastHandle = iMA(_Symbol, PERIOD_H4, EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   emaSlowHandle = iMA(_Symbol, PERIOD_H4, EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   rsiHandle     = iRSI(_Symbol, PERIOD_H4, RSI_Period, PRICE_CLOSE);
   atrHandle     = iATR(_Symbol, PERIOD_H4, ATR_Period);

   if(emaFastHandle == INVALID_HANDLE || emaSlowHandle == INVALID_HANDLE ||
      rsiHandle == INVALID_HANDLE || atrHandle == INVALID_HANDLE)
   {
      Print("❌ Error creating indicator handles!");
      return INIT_FAILED;
   }

   //--- Set buffer as series
   ArraySetAsSeries(emaFastBuf, true);
   ArraySetAsSeries(emaSlowBuf, true);
   ArraySetAsSeries(rsiBuf, true);
   ArraySetAsSeries(atrBuf, true);

   Print("✅ GoldSwingConservative EA Initialized Successfully");
   Print("📊 Symbol: ", _Symbol, " | Timeframe: H4");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(emaFastHandle);
   IndicatorRelease(emaSlowHandle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(atrHandle);
   Print("🔴 EA Deinitialized");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Only run on new H4 bar
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_H4, 0);
   if(currentBarTime == lastBarTime) return;
   lastBarTime = currentBarTime;

   //--- Copy indicator data
   if(CopyBuffer(emaFastHandle, 0, 0, 3, emaFastBuf) < 3) return;
   if(CopyBuffer(emaSlowHandle, 0, 0, 3, emaSlowBuf) < 3) return;
   if(CopyBuffer(rsiHandle,     0, 0, 3, rsiBuf)     < 3) return;
   if(CopyBuffer(atrHandle,     0, 0, 3, atrBuf)     < 3) return;

   double emaFast = emaFastBuf[1];
   double emaSlow = emaSlowBuf[1];
   double rsiNow  = rsiBuf[1];
   double rsiPrev = rsiBuf[2];
   double atr     = atrBuf[1];

   //--- Check if already have open position
   if(HasOpenPosition()) return;

   //--- Detect RSI bounce conditions
   // Buy: RSI was below 40, now crossing back above 40
   if(rsiPrev < RSI_BuyLevel)  rsiWasBelow40 = true;
   if(rsiPrev > RSI_SellLevel) rsiWasAbove60 = true;

   //--- BUY Signal
   if(emaFast > emaSlow)           // Uptrend
   {
      if(rsiWasBelow40 && rsiNow > RSI_BuyLevel && rsiPrev <= RSI_BuyLevel)
      {
         double sl = atr * SL_ATR_Multi;
         double tp = atr * TP_ATR_Multi;
         OpenBuy(sl, tp);
         rsiWasBelow40 = false;
      }
   }

   //--- SELL Signal
   if(emaFast < emaSlow)           // Downtrend
   {
      if(rsiWasAbove60 && rsiNow < RSI_SellLevel && rsiPrev >= RSI_SellLevel)
      {
         double sl = atr * SL_ATR_Multi;
         double tp = atr * TP_ATR_Multi;
         OpenSell(sl, tp);
         rsiWasAbove60 = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Open Buy Order                                                   |
//+------------------------------------------------------------------+
void OpenBuy(double slDistance, double tpDistance)
{
   double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl     = ask - slDistance;
   double tp     = ask + tpDistance;
   double lots   = CalculateLotSize(slDistance);

   if(lots <= 0) return;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   if(trade.Buy(lots, _Symbol, ask, sl, tp, "GoldSwing Buy"))
      Print("✅ BUY opened | Lots: ", lots, " | SL: ", sl, " | TP: ", tp);
   else
      Print("❌ BUY failed | Error: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Open Sell Order                                                  |
//+------------------------------------------------------------------+
void OpenSell(double slDistance, double tpDistance)
{
   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double sl     = bid + slDistance;
   double tp     = bid - tpDistance;
   double lots   = CalculateLotSize(slDistance);

   if(lots <= 0) return;

   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);

   if(trade.Sell(lots, _Symbol, bid, sl, tp, "GoldSwing Sell"))
      Print("✅ SELL opened | Lots: ", lots, " | SL: ", sl, " | TP: ", tp);
   else
      Print("❌ SELL failed | Error: ", GetLastError());
}

//+------------------------------------------------------------------+
//| Calculate Lot Size based on Risk %                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
   double balance     = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount  = balance * (RiskPercent / 100.0);
   double tickValue   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize    = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double minLot      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(tickValue == 0 || tickSize == 0) return 0;

   double valuePerLot = (slDistance / tickSize) * tickValue;
   if(valuePerLot == 0) return 0;

   double lots = riskAmount / valuePerLot;
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Check if there's already an open position                        |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
