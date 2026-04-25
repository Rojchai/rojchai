//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

// ===== INPUT =====
input double LotSize = 0.01;
input int    BlockSizePoints = 480;
input int    MaxPOCStored = 50;

// ===== STRUCT =====
struct POCZone
{
   double high;
   double low;
   double close;
   int    state; // 0=WAIT, 1=ACTIVE, 2=DONE
   bool   entry1;
   bool   entry2;
   int    mode; // 1=buy, -1=sell, 0=ignore
};

POCZone pocList[100];

datetime lastH1 = 0;

//+------------------------------------------------------------------+
void AddPOC(double high, double low, double close)
{
   for(int i = MaxPOCStored-1; i > 0; i--)
      pocList[i] = pocList[i-1];

   pocList[0].high = high;
   pocList[0].low  = low;
   pocList[0].close = close;
   pocList[0].state = 0;
   pocList[0].entry1 = false;
   pocList[0].entry2 = false;
   pocList[0].mode = 0;
}

//+------------------------------------------------------------------+
void CheckNewH1()
{
   datetime t = iTime(_Symbol, PERIOD_H1, 0);

   if(t != lastH1)
   {
      lastH1 = t;

      double high = iHigh(_Symbol, PERIOD_H1, 1);
      double low  = iLow(_Symbol, PERIOD_H1, 1);
      double close= iClose(_Symbol, PERIOD_H1, 1);

      double mid = MathFloor((high+low)/2 / (BlockSizePoints*_Point)) * (BlockSizePoints*_Point);

      double pocHigh = mid + (BlockSizePoints*_Point/2);
      double pocLow  = mid - (BlockSizePoints*_Point/2);

      AddPOC(pocHigh, pocLow, close);
   }
}

//+------------------------------------------------------------------+
double GetUpper(double price)
{
   return price + BlockSizePoints*_Point;
}

double GetLower(double price)
{
   return price - BlockSizePoints*_Point;
}

//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket = PositionGetTicket(i);
      trade.PositionClose(ticket);
   }
}

//+------------------------------------------------------------------+
void HandlePOC(POCZone &p)
{
   if(p.state == 2) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ===== Activate =====
   if(p.state == 0)
   {
      if(bid <= p.high && ask >= p.low)
      {
         p.state = 1;

         if(p.close > p.high)
            p.mode = 1;
         else if(p.close < p.low)
            p.mode = -1;
         else
         {
            p.state = 2; // ❌ ตัดทิ้งเลยถ้า close อยู่ใน POC
            return;
         }
      }
      else return;
   }

   // ===== BUY MODE =====
   if(p.mode == 1)
   {
      if(!p.entry1 && ask >= p.high)
      {
         if(trade.Buy(LotSize))
            p.entry1 = true;
      }

      if(!p.entry2 && bid <= p.low)
      {
         if(trade.Buy(LotSize))
            p.entry2 = true;
      }

      double tp = GetUpper(p.high);
      double sl = GetLower(p.low);

      if(bid >= tp || bid <= sl)
      {
         CloseAll();
         p.state = 2;
      }
   }

   // ===== SELL MODE =====
   if(p.mode == -1)
   {
      if(!p.entry1 && bid <= p.low)
      {
         if(trade.Sell(LotSize))
            p.entry1 = true;
      }

      if(!p.entry2 && ask >= p.high)
      {
         if(trade.Sell(LotSize))
            p.entry2 = true;
      }

      double tp = GetLower(p.low);
      double sl = GetUpper(p.high);

      if(bid <= tp || bid >= sl)
      {
         CloseAll();
         p.state = 2;
      }
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   CheckNewH1();

   for(int i=0;i<MaxPOCStored;i++)
   {
      HandlePOC(pocList[i]);
   }
}
//+------------------------------------------------------------------+
