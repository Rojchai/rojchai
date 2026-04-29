//+------------------------------------------------------------------+
//|                                      TimeCandleEA.mq5            |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;
input int TP_RR = 1; // RR (1 = SL เท่ากับ TP)
input int TimeOffset = 0; // ชดเชยเวลา (ชั่วโมง)

// ตั้งเวลา (รูปแบบ HH:MM)
input string TradeTimes = "07:00,08:00,08:30,10:30,13:00,14:00,15:00,20:00";

// กรองโดจิ
input double MinBodyPercent = 0.3; // 0.3 = 30%

//--- เก็บเวลาที่เข้าไปแล้ว
string usedTimes[];

//+------------------------------------------------------------------+
bool IsTimeMatch(string t1, string t2)
{
   return (t1 == t2);
}
//+------------------------------------------------------------------+
bool IsUsed(string timeStr)
{
   for(int i=0;i<ArraySize(usedTimes);i++)
   {
      if(usedTimes[i] == timeStr)
         return true;
   }
   return false;
}
//+------------------------------------------------------------------+
void MarkUsed(string timeStr)
{
   int size = ArraySize(usedTimes);
   ArrayResize(usedTimes, size+1);
   usedTimes[size] = timeStr;
}
//+------------------------------------------------------------------+
void ResetUsedDaily(datetime now)
{
   static int lastDay = -1;

   MqlDateTime t;
   TimeToStruct(now, t);

   if(t.day != lastDay)
   {
      ArrayResize(usedTimes, 0);
      lastDay = t.day;
   }
}
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFilling()
{
   int fill = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);

   if(fill & SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   if(fill & SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;

   return ORDER_FILLING_RETURN;
}
//+------------------------------------------------------------------+
void OpenTrade(bool isBuy, double sl, double tp)
{
   double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                        : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.type   = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price  = NormalizeDouble(price, _Digits);
   req.sl     = NormalizeDouble(sl, _Digits);
   req.tp     = NormalizeDouble(tp, _Digits);
   req.deviation = 50;
   req.type_filling = GetFilling();

   OrderSend(req, res);
}
//+------------------------------------------------------------------+
void OnTick()
{
   datetime now = TimeCurrent() + TimeOffset * 3600;

   ResetUsedDaily(now);

   MqlDateTime t;
   TimeToStruct(now, t);

   // เวลาแบบ HH:MM
   string currentTime = StringFormat("%02d:%02d", t.hour, t.min);

   // เช็คว่าเป็นนาทีถัดจากเวลาเป้าหมาย
   string times[];
   int count = StringSplit(TradeTimes, ',', times);

   for(int i=0;i<count;i++)
   {
      string target = times[i];

      // แยก HH:MM
      int th = StringToInteger(StringSubstr(target,0,2));
      int tm = StringToInteger(StringSubstr(target,3,2));

      // เราจะเข้า "ตอนนาทีถัดไป"
      int entry_h = th;
      int entry_m = tm + 1;

      if(entry_m >= 60)
      {
         entry_m = 0;
         entry_h++;
      }

      string entryTime = StringFormat("%02d:%02d", entry_h, entry_m);

      // เวลาเข้า
      if(currentTime == entryTime && !IsUsed(target))
      {
         // แท่งก่อนหน้า (shift=1)
         double open  = iOpen(_Symbol, PERIOD_M1, 1);
         double close = iClose(_Symbol, PERIOD_M1, 1);
         double high  = iHigh(_Symbol, PERIOD_M1, 1);
         double low   = iLow(_Symbol, PERIOD_M1, 1);

         double body = MathAbs(close - open);
         double range = high - low;

         // กันโดจิ
         if(range == 0) return;
         if(body < range * MinBodyPercent) return;

         bool isBuy = (close > open);
         bool isSell = (close < open);

         double sl, tp;

         if(isBuy)
         {
            sl = low;
            double risk = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - sl);
            tp = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + risk * TP_RR;

            OpenTrade(true, sl, tp);
         }
         else if(isSell)
         {
            sl = high;
            double risk = (sl - SymbolInfoDouble(_Symbol, SYMBOL_BID));
            tp = SymbolInfoDouble(_Symbol, SYMBOL_BID) - risk * TP_RR;

            OpenTrade(false, sl, tp);
         }

         MarkUsed(target);
      }
   }
}
