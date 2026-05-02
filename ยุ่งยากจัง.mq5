//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>
CTrade trade;

//================ INPUT =================//
input string tradeTimes = "03:00,04:00,04:30,06:30,09:00,10:00,11:00,16:00";
input double riskDivider = 200.0;
input double dailyProfitPercent = 3.5;
input double dailyLossPercent = -40.0;
input int resetHour = 2; // ✅ reset 02:00

//================ VARIABLES =================//
double prevHigh=0, prevLow=0, halfRange=0;

int state = 0; // 0=idle,1=waiting close,2=ready trade
bool tradeDone=false;

datetime triggerBarTime=0;
datetime lastDay=0;

double startBalance=0;
bool dailyStop=false;

//+------------------------------------------------------------------+
int OnInit()
{
   startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   return(INIT_SUCCEEDED);
}
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
   if(startBalance <= 0) return;

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

   if(prevPrice!=0)
   {
      if((prevPrice < d1 && bid >= d1) || (prevPrice > d1 && bid <= d1) ||
         (prevPrice < w1 && bid >= w1) || (prevPrice > w1 && bid <= w1) ||
         (prevPrice < mn && bid >= mn) || (prevPrice > mn && bid <= mn))
      {
         CloseAll();
      }
   }

   prevPrice = bid;
}
//+------------------------------------------------------------------+
void OnTick()
{
   // ===== Reset วัน =====
   if(IsNewDay())
   {
      startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      dailyStop = false;
   }

   if(!dailyStop)
      CheckDailyLimit();

   CheckTouchClose();

   if(dailyStop)
      return;

   datetime currentBar = iTime(_Symbol, PERIOD_M5, 0);

   // ================== STEP 1: ถึงเวลา ==================
   if(IsTradeTime() && state == 0)
   {
      state = 1;
      tradeDone = false;
      triggerBarTime = currentBar; // จำแท่งที่เริ่ม
   }

   // ================== STEP 2: รอ M5 เปลี่ยนจริง ==================
   if(state == 1 && currentBar != triggerBarTime)
   {
      prevHigh = iHigh(_Symbol, PERIOD_M5, 1);
      prevLow  = iLow(_Symbol, PERIOD_M5, 1);
      halfRange = (prevHigh - prevLow) / 2.0;

      state = 2; // พร้อมเข้าแล้ว
   }

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // ================== STEP 3: เข้าออเดอร์ ==================
   if(state == 2 && !tradeDone && PositionsTotal()==0 && prevHigh>0 && prevLow>0)
   {
      double lot = GetLot();

      // BUY
      if(bid > prevHigh)
      {
         trade.Buy(lot, _Symbol, 0, prevLow, 0);
         tradeDone = true;
         state = 0;
      }

      // SELL
      if(bid < prevLow)
      {
         trade.Sell(lot, _Symbol, 0, prevHigh, 0);
         tradeDone = true;
         state = 0;
      }
   }

   // ================== BREAK EVEN ==================
   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i))
      {
         double open = PositionGetDouble(POSITION_PRICE_OPEN);

         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
         {
            if(bid - open >= halfRange)
               trade.PositionModify(PositionGetTicket(i), open, 0);
         }

         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
         {
            if(open - bid >= halfRange)
               trade.PositionModify(PositionGetTicket(i), open, 0);
         }
      }
   }
}
//+------------------------------------------------------------------+
