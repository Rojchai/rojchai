//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double StartLot = 0.01;
input double LotMultiplier = 2.0;
input int MaxRange = 300;
input double TargetProfitPercent = 0.3;
input double MaxLotLimit = 1.6;   // 🔥 kill switch lot
input int CutMinute1 = 10;        // 🔥 ปรับได้ (เช่น 10)
input int CutMinute2 = 40;        // 🔥 ปรับได้ (เช่น 40)

// ===== state =====
double currentLot;
int lastDirection = 0;
bool activeCycle = false;
bool tradedThisCycle = false;

double refHigh = 0;
double refLow  = 0;

datetime lastM1BarTime = 0;

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
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      trade.PositionClose(ticket);
   }

   currentLot = StartLot;
   lastDirection = 0;
   activeCycle = false;
}

//+------------------------------------------------------------------+
// 🔥 กันตลาดเปิด (gap วันจันทร์)
bool IsMarketSafe()
{
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);

   // วันจันทร์ช่วงแรก (2 ชั่วโมงแรก)
   if(t.day_of_week == 1 && t.hour < 2)
      return false;

   return true;
}

//+------------------------------------------------------------------+
bool IsEntryWindow(int minute)
{
   return (
      minute == 30 || minute == 31 || minute == 32 ||
      minute == 0  || minute == 1  || minute == 2
   );
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
   // ===== เวลา =====
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   int minute = timeStruct.min;

   // 🔥 กันตลาดเปิด
   if(!IsMarketSafe())
      return;

   // ===== ตัดรอบ =====
   if(minute == CutMinute1 || minute == CutMinute2)
   {
      CloseAll();
      tradedThisCycle = false;
      return;
   }

   // ===== ปิดกำไร =====
   if(GetProfitPercent() >= TargetProfitPercent)
   {
      CloseAll();
      tradedThisCycle = true;
      return;
   }

   // ===== 🔥 kill switch lot =====
   if(currentLot >= MaxLotLimit)
   {
      CloseAll();
      tradedThisCycle = true;
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

   // ===== BUY =====
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

   // ===== SELL =====
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
