//+------------------------------------------------------------------+
//|                                     OpenLineEA_StatePerLine.mq5  |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;
input int TP_Points = 444;

//--- state
enum OrderState { NONE, BUY_STATE, SELL_STATE };

OrderState state_D1 = NONE;
OrderState state_W1 = NONE;
OrderState state_MN = NONE;

//--- last prices
double lastBid = 0;
double lastAsk = 0;

//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFilling()
{
   int fill = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);

   if(fill & SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   if(fill & SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;

   return ORDER_FILLING_RETURN;
}
//+------------------------------------------------------------------+
double GetOpenPrice(ENUM_TIMEFRAMES tf)
{
   return iOpen(_Symbol, tf, 0);
}
//+------------------------------------------------------------------+
// 🔥 เช็คว่า “เส้นนี้ยังมี position อยู่ไหม”
bool HasPositionByComment(string comment)
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetString(POSITION_COMMENT) == comment)
            return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
void OpenOrder(bool isBuy, OrderState &state, string comment)
{
   if(state != NONE) return;

   double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                        : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double tp = isBuy ? price + TP_Points * _Point
                     : price - TP_Points * _Point;

   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.type   = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price  = NormalizeDouble(price, _Digits);
   req.tp     = NormalizeDouble(tp, _Digits);
   req.deviation = 50;
   req.type_filling = GetFilling();
   req.comment = comment;

   OrderSend(req, res);

   if(res.retcode == 10009 || res.retcode == 10008)
   {
      state = isBuy ? BUY_STATE : SELL_STATE;
   }
}
//+------------------------------------------------------------------+
// 🔥 ENTRY (tick cross + แยก bid/ask)
void CheckEntry(double line, OrderState &state, string comment)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // ถ้า position ของเส้นนี้หาย → reset state
   if(!HasPositionByComment(comment))
      state = NONE;

   if(state != NONE) return;

   // BUY → ใช้ ASK
   if(lastAsk > line && ask <= line)
   {
      OpenOrder(true, state, comment);
   }

   // SELL → ใช้ BID
   if(lastBid < line && bid >= line)
   {
      OpenOrder(false, state, comment);
   }
}
//+------------------------------------------------------------------+
void OnTick()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // init
   if(lastBid == 0)
   {
      lastBid = bid;
      lastAsk = ask;
      return;
   }

   double D1 = GetOpenPrice(PERIOD_D1);
   double W1 = GetOpenPrice(PERIOD_W1);
   double MN = GetOpenPrice(PERIOD_MN1);

   // ENTRY แยกเส้น
   CheckEntry(D1, state_D1, "D1");
   CheckEntry(W1, state_W1, "W1");
   CheckEntry(MN, state_MN, "MN");

   // update last
   lastBid = bid;
   lastAsk = ask;
}
