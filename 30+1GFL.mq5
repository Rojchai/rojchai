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
int lastDirection = 0;   // 1 = buy, -1 = sell, 0 = none
bool activeCycle = false;
bool tradedThisCycle = false; // 🔥 ตัวล็อครอบ

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

   // ===== รีเซ็ตรอบใหม่ (ก่อน M30 เปลี่ยน) =====
   if(minute == 28 || minute == 58)
   {
      CloseAll();
      tradedThisCycle = false; // 🔓 ปลดล็อก
      return;
   }

   // ===== ปิดเมื่อกำไรถึง =====
   if(GetProfitPercent() >= TargetProfitPercent)
   {
      CloseAll();
      tradedThisCycle = true; // 🔒 ล็อครอบนี้
      return;
   }

   // ===== ตรวจแท่ง M1 ใหม่ =====
   datetime currentM1 = iTime(_Symbol, PERIOD_M1, 0);

   if(currentM1 != lastM1BarTime)
   {
      lastM1BarTime = currentM1;

      // ❗ จำกัดช่วงเวลา
      if(!IsEntryWindow(minute))
         return;

      // ❗ ถ้าเคยเทรดรอบนี้แล้ว = ห้ามเข้าใหม่
      if(tradedThisCycle)
         return;

      // ===== หาแท่งที่ใช้ =====
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

   // ===== ถ้ายังไม่มี cycle = ไม่เทรด =====
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
