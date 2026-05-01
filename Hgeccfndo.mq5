//+------------------------------------------------------------------+
//|   Hedge Grid EA - Continue Cycle (FIXED NO DOUBLE ORDER)         |
//+------------------------------------------------------------------+
#property strict

#include <Trade/Trade.mqh>
CTrade trade;

input double LotSize = 0.1;
input int GridStep = 50;
input double TargetProfit = 0.5;
input int MagicNumber = 555888;

double lastBuyPrice = 0;
double lastSellPrice = 0;

datetime lastBarTime = 0;

// 🔥 ตัวกันยิงซ้ำ
bool isOpening = false;

//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   Print("EA STARTED (FIXED)");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // 💰 ปิดกำไร
   if(GetTotalProfit() >= TargetProfit && CountPositions() > 0)
   {
      Print("💰 CLOSE ALL");
      CloseAll();
      ResetGrid();
      return;
   }

   // 🔰 เริ่มรอบใหม่
   if(CountPositions() == 0 && !isOpening)
   {
      datetime currentBar = iTime(_Symbol, PERIOD_M5, 0);

      if(currentBar != lastBarTime)
      {
         lastBarTime = currentBar;
         isOpening = true;
         StartNewCycle();
      }
      return;
   }

   // 🔁 ทำกริดต่อ
   if(CountPositions() > 0)
      ManageGrid();
}

//+------------------------------------------------------------------+
void StartNewCycle()
{
   // 🔥 กันซ้ำชั้นที่ 2
   if(PositionSelect(_Symbol))
   {
      Print("Already has position → skip");
      isOpening = false;
      return;
   }

   ResetGrid();

   double open = iOpen(_Symbol, PERIOD_M5, 1);
   double close = iClose(_Symbol, PERIOD_M5, 1);

   bool result = false;

   if(close > open)
   {
      result = trade.Buy(LotSize);
      if(result)
      {
         lastBuyPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         Print("🔄 Start BUY Cycle");
      }
   }
   else
   {
      result = trade.Sell(LotSize);
      if(result)
      {
         lastSellPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         Print("🔄 Start SELL Cycle");
      }
   }

   if(!result)
      Print("❌ First order failed");

   isOpening = false; // 🔥 ปลดล็อก
}

//+------------------------------------------------------------------+
void ManageGrid()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // BUY grid
   if(lastBuyPrice > 0 && ask >= lastBuyPrice + GridStep * _Point)
   {
      if(trade.Buy(LotSize))
      {
         lastBuyPrice = ask;
         Print("BUY grid");
      }
   }

   // SELL grid
   if(lastSellPrice > 0 && bid <= lastSellPrice - GridStep * _Point)
   {
      if(trade.Sell(LotSize))
      {
         lastSellPrice = bid;
         Print("SELL grid");
      }
   }
}

//+------------------------------------------------------------------+
double GetTotalProfit()
{
   double total = 0;

   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         total += PositionGetDouble(POSITION_PROFIT);
      }
   }

   return total;
}

//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

         ulong ticket = PositionGetInteger(POSITION_TICKET);
         trade.PositionClose(ticket);
      }
   }
}

//+------------------------------------------------------------------+
int CountPositions()
{
   int count = 0;

   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            count++;
      }
   }

   return count;
}

//+------------------------------------------------------------------+
void ResetGrid()
{
   lastBuyPrice = 0;
   lastSellPrice = 0;
}
//+------------------------------------------------------------------+
