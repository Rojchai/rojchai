//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

//--- input
input double LotSize = 0.1;
input int TP_Points = 100;
input double MaxLossPercent = 10.0;
input double MaxDDPercent = 50.0;

// TF ทั้งหมด
ENUM_TIMEFRAMES TFs[] = {
   PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_M30,
   PERIOD_H1, PERIOD_H4,
   PERIOD_D1, PERIOD_W1, PERIOD_MN1
};

// state
datetime lastBarTime[20];
bool tradedThisSetup[20];

//+------------------------------------------------------------------+
int GetMagic(int index)
{
   return 1000 + index;
}

//+------------------------------------------------------------------+
bool HasPosition(int magic)
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) == magic)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
void CheckEquityProtection()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   double dd = (balance - equity) / balance * 100.0;

   if(dd >= MaxDDPercent)
   {
      for(int i=PositionsTotal()-1; i>=0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         trade.PositionClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
void CheckPositionLoss()
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         double profit = PositionGetDouble(POSITION_PROFIT);
         double balance = AccountInfoDouble(ACCOUNT_BALANCE);

         double lossPercent = (-profit / balance) * 100.0;

         if(lossPercent >= MaxLossPercent)
         {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            trade.PositionClose(ticket);
         }
      }
   }
}

//+------------------------------------------------------------------+
void TradeTF(int index)
{
   ENUM_TIMEFRAMES tf = TFs[index];
   int magic = GetMagic(index);

   datetime currentBar = iTime(_Symbol, tf, 0);

   // ถ้าเกิดแท่งใหม่ → reset สิทธิ์
   if(currentBar != lastBarTime[index])
   {
      lastBarTime[index] = currentBar;
      tradedThisSetup[index] = false;
   }

   // ถ้าใช้ setup นี้ไปแล้ว → ห้ามเข้า
   if(tradedThisSetup[index]) return;

   // ถ้ามีออเดอร์ TF นี้อยู่ → ข้าม
   if(HasPosition(magic)) return;

   // --- ข้อมูล ---
   double high2 = iHigh(_Symbol, tf, 2);
   double low2  = iLow(_Symbol, tf, 2);

   double high1 = iHigh(_Symbol, tf, 1);
   double low1  = iLow(_Symbol, tf, 1);
   double close1 = iClose(_Symbol, tf, 1);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   trade.SetExpertMagicNumber(magic);

   // BUY
   if(close1 > high2 && bid <= high2)
   {
      double sl = low1;
      double tp = ask + TP_Points * _Point;

      if(trade.Buy(LotSize, _Symbol, 0, sl, tp))
      {
         tradedThisSetup[index] = true;
      }
   }

   // SELL
   if(close1 < low2 && ask >= low2)
   {
      double sl = high1;
      double tp = bid - TP_Points * _Point;

      if(trade.Sell(LotSize, _Symbol, 0, sl, tp))
      {
         tradedThisSetup[index] = true;
      }
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   CheckEquityProtection();
   CheckPositionLoss();

   for(int i=0; i<ArraySize(TFs); i++)
   {
      TradeTF(i);
   }
}
//+------------------------------------------------------------------+
