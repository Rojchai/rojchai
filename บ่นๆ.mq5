//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>
CTrade trade;

//================ INPUT =================//
input string tradeTimes = "01:00,02:00,02:30,07:00";
input double riskDivider = 200.0;     // lot = balance / 200
input double dailyProfitPercent = 3.5;
input double dailyLossPercent = -40.0;
input int resetHour = 0;              // reset เวลา (00:00)

//================ VARIABLES =================//
double prevHigh, prevLow, halfRange;
bool ready = false;
bool tradeDone = false;

datetime lastBar = 0;
datetime lastDay = 0;

double startBalance = 0;
bool dailyStop = false;

//+------------------------------------------------------------------+
bool IsTradeTime()
{
   string arr[];
   int n = StringSplit(tradeTimes, ',', arr);
   string now = TimeToString(TimeCurrent(), TIME_MINUTES);

   for(int i=0;i<n;i++)
      if(now == arr[i])
         return true;

   return false;
}
//+------------------------------------------------------------------+
double GetLot()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   return NormalizeDouble(balance / riskDivider, 2);
}
//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(PositionGetTicket(i))
         trade.PositionClose(PositionGetTicket(i));
   }
}
//+------------------------------------------------------------------+
bool IsNewDay()
{
   datetime now = TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now, t);

   if(t.hour == resetHour && (now - lastDay) > 3600)
   {
      lastDay = now;
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
void CheckDailyLimit()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   double percent = (equity - startBalance) / startBalance * 100.0;

   if(percent >= dailyProfitPercent || percent <= dailyLossPercent)
   {
      CloseAll();
      dailyStop = true;
   }
}
//+------------------------------------------------------------------+
void CheckTouchClose()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double d1 = iOpen(_Symbol, PERIOD_D1, 0);
   double w1 = iOpen(_Symbol, PERIOD_W1, 0);
   double mn = iOpen(_Symbol, PERIOD_MN1, 0);

   static double prevPrice = 0;

   // check cross (แตะเส้นจริง)
   if((prevPrice < d1 && bid >= d1) || (prevPrice > d1 && bid <= d1) ||
      (prevPrice < w1 && bid >= w1) || (prevPrice > w1 && bid <= w1) ||
      (prevPrice < mn && bid >= mn) || (prevPrice > mn && bid <= mn))
   {
      CloseAll();
   }

   prevPrice = bid;
}
//+------------------------------------------------------------------+
void OnTick()
{
   // reset วันใหม่
   if(IsNewDay())
   {
      startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      dailyStop = false;
   }

   // เช็ค daily limit
   if(!dailyStop)
      CheckDailyLimit();

   // ปิดเมื่อแตะเส้น
   CheckTouchClose();

   if(dailyStop)
      return;

   datetime currentBar = iTime(_Symbol, PERIOD_M5, 0);

   // trigger เวลา
   if(IsTradeTime())
   {
      ready = true;
      tradeDone = false;
   }

   // รอแท่ง M5 ปิด
   if(ready && currentBar != lastBar)
   {
      prevHigh = iHigh(_Symbol, PERIOD_M5, 1);
      prevLow  = iLow(_Symbol, PERIOD_M5, 1);
      halfRange = (prevHigh - prevLow) / 2.0;

      ready = false;
   }

   lastBar = currentBar;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // เข้า 1 ไม้
   if(!tradeDone && PositionsTotal() == 0)
   {
      double lot = GetLot();

      // BUY
      if(bid > prevHigh)
      {
         trade.Buy(lot, _Symbol, 0, prevLow, 0);
         tradeDone = true;
      }

      // SELL
      if(bid < prevLow)
      {
         trade.Sell(lot, _Symbol, 0, prevHigh, 0);
         tradeDone = true;
      }
   }

   // Break Even
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i))
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            if(bid - open >= halfRange)
               trade.PositionModify(PositionGetTicket(i), open, 0);
         }

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            if(open - bid >= halfRange)
               trade.PositionModify(PositionGetTicket(i), open, 0);
         }
      }
   }
}
//+------------------------------------------------------------------+
