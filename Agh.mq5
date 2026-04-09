//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double StartLot = 0.01;
input double LotMultiplier = 2.0;
input double TargetProfitPercent = 0.1;

// ===== state =====
double currentLot;
int lastDirection = 0; // 1 = buy, -1 = sell, 0 = none

//+------------------------------------------------------------------+
double GetProfitPercent()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   return ((equity - balance) / balance) * 100.0;
}

//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      trade.PositionClose(ticket);
   }

   currentLot = StartLot;
   lastDirection = 0;
}

//+------------------------------------------------------------------+
int OnInit()
{
   currentLot = StartLot;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // ===== ปิดเมื่อกำไรถึง =====
   if(GetProfitPercent() >= TargetProfitPercent)
   {
      CloseAll();
      return;
   }

   double high1 = iHigh(_Symbol, _Period, 1);
   double low1  = iLow(_Symbol, _Period, 1);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ===== BUY =====
   if(ask >= high1)
   {
      // ต้องไม่ใช่ buy ล่าสุด
      if(lastDirection != 1)
      {
         if(trade.Buy(currentLot, _Symbol))
         {
            lastDirection = 1;
            currentLot *= LotMultiplier;
         }
      }
   }

   // ===== SELL =====
   if(bid <= low1)
   {
      // ต้องไม่ใช่ sell ล่าสุด
      if(lastDirection != -1)
      {
         if(trade.Sell(currentLot, _Symbol))
         {
            lastDirection = -1;
            currentLot *= LotMultiplier;
         }
      }
   }
}
//+------------------------------------------------------------------+
