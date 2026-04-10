//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double StartLot = 0.01;
input double LotMultiplier = 2.0;
input int MaxRange = 300;
input double TargetProfitPercent = 0.3;

// ===== state =====
double currentLot;
int lastDirection = 0;
bool activeCycle = false;

double refHigh = 0;
double refLow  = 0;

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
   activeCycle = false;
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
   int minute = TimeMinute(TimeCurrent());

   // ===== ปิดก่อน M30 เปลี่ยน =====
   if(minute == 28 || minute == 58)
   {
      CloseAll();
      return;
   }

   // ===== ปิดเมื่อกำไรถึง =====
   if(GetProfitPercent() >= TargetProfitPercent)
   {
      CloseAll();
      return;
   }

   // ===== เริ่ม cycle ตอน 29,30,31 / 59,0,1 =====
   if(!activeCycle)
   {
      double high1 = iHigh(_Symbol, PERIOD_M1, 1);
      double low1  = iLow(_Symbol, PERIOD_M1, 1);

      double range = (high1 - low1) / _Point;

      if(range <= MaxRange)
      {
         refHigh = high1;
         refLow  = low1;

         activeCycle = true;
      }
      else
      {
         return;
      }
   }

   // ===== เทรด =====
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // BUY
   if(ask >= refHigh)
   {
      if(lastDirection != 1)
      {
         if(trade.Buy(currentLot, _Symbol))
         {
            lastDirection = 1;
            currentLot *= LotMultiplier;
         }
      }
   }

   // SELL
   if(bid <= refLow)
   {
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
