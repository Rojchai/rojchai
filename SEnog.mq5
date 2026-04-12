//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double LotSize = 0.01;
input int MaxRange = 300;
input int TP_Points = 100;

// ===== state =====
bool activeCycle = false;
bool tradedThisCycle = false;

double refHigh = 0;
double refLow  = 0;

datetime lastM1BarTime = 0;

//+------------------------------------------------------------------+
bool IsEntryWindow(int minute)
{
   return (
      minute == 30 || minute == 31 || minute == 32 ||
      minute == 0  || minute == 1  || minute == 2
   );
}

//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      trade.PositionClose(ticket);
   }

   activeCycle = false;
}

//+------------------------------------------------------------------+
int OnInit()
{
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // ===== เวลา =====
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   int minute = t.min;

   // ===== reset รอบ =====
   if(minute == 28 || minute == 58)
   {
      CloseAll();
      tradedThisCycle = false;
      return;
   }

   // ===== ตรวจแท่ง M1 ใหม่ =====
   datetime currentM1 = iTime(_Symbol, PERIOD_M1, 0);

   if(currentM1 != lastM1BarTime)
   {
      lastM1BarTime = currentM1;

      if(!IsEntryWindow(minute))
         return;

      if(tradedThisCycle)
         return;

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
      }
   }

   if(!activeCycle || tradedThisCycle) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double tp, sl;

   // ===== BUY =====
   if(ask >= refHigh)
   {
      sl = refLow;
      tp = ask + TP_Points * _Point;

      if(trade.Buy(LotSize, _Symbol, ask, sl, tp))
      {
         tradedThisCycle = true;
      }
   }

   // ===== SELL =====
   if(bid <= refLow)
   {
      sl = refHigh;
      tp = bid - TP_Points * _Point;

      if(trade.Sell(LotSize, _Symbol, bid, sl, tp))
      {
         tradedThisCycle = true;
      }
   }
}
//+------------------------------------------------------------------+
