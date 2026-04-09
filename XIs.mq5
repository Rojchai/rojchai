//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== input =====
input double LotSize = 0.01;
input int MinImpulse = 200;   // สำหรับทอง
input int TP = 150;

//+------------------------------------------------------------------+
void OnTick()
{
   if(PositionsTotal() > 0) return;

   double open1  = iOpen(_Symbol, _Period, 1);
   double close1 = iClose(_Symbol, _Period, 1);
   double high1  = iHigh(_Symbol, _Period, 1);
   double low1   = iLow(_Symbol, _Period, 1);

   double open0  = iOpen(_Symbol, _Period, 0);
   double close0 = iClose(_Symbol, _Period, 0);

   double body = MathAbs(close1 - open1) / _Point;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ===== BUY =====
   if(close1 > open1 && body >= MinImpulse)
   {
      // ย่อแต่ไม่หลุด low
      if(bid > low1)
      {
         // เริ่มกลับขึ้น
         if(close0 > open0)
         {
            double sl = low1;
            double tp = ask + TP * _Point;

            trade.Buy(LotSize, _Symbol, 0, sl, tp);
         }
      }
   }

   // ===== SELL =====
   if(close1 < open1 && body >= MinImpulse)
   {
      if(ask < high1)
      {
         if(close0 < open0)
         {
            double sl = high1;
            double tp = bid - TP * _Point;

            trade.Sell(LotSize, _Symbol, 0, sl, tp);
         }
      }
   }
}
//+------------------------------------------------------------------+
