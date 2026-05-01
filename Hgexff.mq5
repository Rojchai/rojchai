//+------------------------------------------------------------------+
//|                 Hedge Grid EA (XM FIXED FULL)                   |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;
input int GridStep = 50; // point
input double TargetProfit = 0.5; // $
input int MagicNumber = 555888;

// เก็บราคาล่าสุด
double lastBuyPrice = 0;
double lastSellPrice = 0;

//+------------------------------------------------------------------+
// 🔥 ดึง filling mode จากโบรก (แก้ error XM)
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
   long mode;
   if(SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE, mode))
      return (ENUM_ORDER_TYPE_FILLING)mode;

   return ORDER_FILLING_RETURN; // fallback
}

//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA STARTED");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   // debug
   Print("RUNNING | Orders: ", CountPositions());

   // ปิดเมื่อกำไรถึง
   if(GetTotalProfit() >= TargetProfit)
   {
      Print("TARGET HIT → CLOSE ALL");
      CloseAll();
      ResetGrid();
      return;
   }

   // ไม่มีออเดอร์ → เปิดแรก
   if(CountPositions() == 0)
   {
      OpenFirstOrder();
      return;
   }

   ManageGrid();
}

//+------------------------------------------------------------------+
void OpenFirstOrder()
{
   double open = iOpen(_Symbol, PERIOD_M5, 0);
   double close = iClose(_Symbol, PERIOD_M5, 0);

   if(close > open)
   {
      OpenBuy();
      lastBuyPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }
   else
   {
      OpenSell();
      lastSellPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }
}

//+------------------------------------------------------------------+
void ManageGrid()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // BUY grid
   if(lastBuyPrice == 0 || ask >= lastBuyPrice + GridStep * _Point)
   {
      Print("Open BUY grid");
      OpenBuy();
      lastBuyPrice = ask;
   }

   // SELL grid
   if(lastSellPrice == 0 || bid <= lastSellPrice - GridStep * _Point)
   {
      Print("Open SELL grid");
      OpenSell();
      lastSellPrice = bid;
   }
}

//+------------------------------------------------------------------+
void OpenBuy()
{
   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.type = ORDER_TYPE_BUY;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   req.magic = MagicNumber;
   req.deviation = 20;
   req.type_filling = GetFillingMode();

   if(!OrderSend(req, res))
      Print("❌ Buy failed: ", res.retcode);
   else
      Print("✅ Buy opened");
}

//+------------------------------------------------------------------+
void OpenSell()
{
   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.type = ORDER_TYPE_SELL;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   req.magic = MagicNumber;
   req.deviation = 20;
   req.type_filling = GetFillingMode();

   if(!OrderSend(req, res))
      Print("❌ Sell failed: ", res.retcode);
   else
      Print("✅ Sell opened");
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
         int type = PositionGetInteger(POSITION_TYPE);

         MqlTradeRequest req;
         MqlTradeResult res;

         ZeroMemory(req);
         ZeroMemory(res);

         req.action = TRADE_ACTION_DEAL;
         req.position = ticket;
         req.symbol = _Symbol;
         req.volume = PositionGetDouble(POSITION_VOLUME);
         req.magic = MagicNumber;
         req.deviation = 20;
         req.type_filling = GetFillingMode();

         if(type == POSITION_TYPE_BUY)
         {
            req.type = ORDER_TYPE_SELL;
            req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         }
         else
         {
            req.type = ORDER_TYPE_BUY;
            req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         }

         OrderSend(req, res);
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
