//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double BaseBalance = 3000.0;
input double BaseLot = 0.5;
input double MinLot = 0.01;
input double MaxLot = 2.0;

input int MaxRange = 300;
input int BE_Points = 100;
input double CloseProfitPercent = 50.0;

// ===== state =====
bool activeCycle = false;

double refHigh = 0;
double refLow  = 0;

datetime lastM1BarTime = 0;
datetime cycleStartTime = 0;

//+------------------------------------------------------------------+
double GetProfitPercent()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   return ((equity - balance) / balance) * 100.0;
}

//+------------------------------------------------------------------+
double GetDynamicLot()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lot = (balance / BaseBalance) * BaseLot;

   lot = MathMax(lot, MinLot);
   lot = MathMin(lot, MaxLot);

   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      trade.PositionClose(ticket);
   }
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
bool IsWithinTradeWindow()
{
   return (TimeCurrent() - cycleStartTime) <= 8 * 60;
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

   // ===== ปิดทั้งหมดเมื่อ +50% =====
   if(GetProfitPercent() >= CloseProfitPercent)
   {
      CloseAll();
      return;
   }

   // ===== reset เฉย ๆ =====
   if(minute == 28 || minute == 58)
   {
      activeCycle = false;
   }

   // ===== ตรวจแท่งใหม่ =====
   datetime currentM1 = iTime(_Symbol, PERIOD_M1, 0);

   if(currentM1 != lastM1BarTime)
   {
      lastM1BarTime = currentM1;

      if(!IsEntryWindow(minute))
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
            cycleStartTime = TimeCurrent();
         }
      }
   }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double lot = GetDynamicLot();

   // ===== เข้าออเดอร์แรก =====
   if(PositionsTotal() == 0 && activeCycle && IsWithinTradeWindow())
   {
      if(ask >= refHigh)
      {
         trade.Buy(lot, _Symbol, ask, refLow, 0);
      }

      if(bid <= refLow)
      {
         trade.Sell(lot, _Symbol, bid, refHigh, 0);
      }
   }

   // ===== จัดการ position =====
   if(PositionsTotal() > 0)
   {
      ulong ticket = PositionGetTicket(0);

      if(PositionSelectByTicket(ticket))
      {
         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         int type         = PositionGetInteger(POSITION_TYPE);

         // ===== Breakeven =====
         if(type == POSITION_TYPE_BUY)
         {
            if(bid - openPrice >= BE_Points * _Point)
            {
               trade.PositionModify(ticket, openPrice, 0);
            }

            // ===== Reverse =====
            if(IsWithinTradeWindow() && bid <= refLow)
            {
               trade.PositionClose(ticket);
               trade.Sell(lot, _Symbol, bid, refHigh, 0);
            }
         }

         if(type == POSITION_TYPE_SELL)
         {
            if(openPrice - ask >= BE_Points * _Point)
            {
               trade.PositionModify(ticket, openPrice, 0);
            }

            // ===== Reverse =====
            if(IsWithinTradeWindow() && ask >= refHigh)
            {
               trade.PositionClose(ticket);
               trade.Buy(lot, _Symbol, ask, refLow, 0);
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
