//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double StartLot = 0.01;
input double LotMultiplier = 1.5;
input double TargetProfitPercent = 0.1;

//+------------------------------------------------------------------+
double currentLot = 0.01;

//+------------------------------------------------------------------+
double GetTotalProfitPercent()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   return ((equity - balance) / balance) * 100.0;
}

//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   double profitPercent = GetTotalProfitPercent();

   // ===== ปิดทั้งหมดเมื่อถึงเป้า =====
   if(profitPercent >= TargetProfitPercent)
   {
      CloseAllPositions();
      currentLot = StartLot;
      return;
   }

   double high1 = iHigh(_Symbol, _Period, 1);
   double low1  = iLow(_Symbol, _Period, 1);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ===== BUY =====
   if(MathAbs(ask - high1) <= 5 * _Point)
   {
      if(trade.Buy(currentLot, _Symbol))
      {
         currentLot *= LotMultiplier;
      }
   }

   // ===== SELL =====
   if(MathAbs(bid - low1) <= 5 * _Point)
   {
      if(trade.Sell(currentLot, _Symbol))
      {
         currentLot *= LotMultiplier;
      }
   }
}
//+------------------------------------------------------------------+
