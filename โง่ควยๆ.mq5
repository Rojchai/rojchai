//+------------------------------------------------------------------+
//|                                               OpenLineEA_vRESET  |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;
input int TP_Points = 444; // สำหรับ XAUUSD

enum OrderState { NONE, BUY_STATE, SELL_STATE };

OrderState state_D1 = NONE;
OrderState state_W1 = NONE;
OrderState state_MN = NONE;

//+------------------------------------------------------------------+
double GetOpenPrice(ENUM_TIMEFRAMES tf)
{
   return iOpen(_Symbol, tf, 0);
}
//+------------------------------------------------------------------+
void OpenOrder(bool isBuy, OrderState &state)
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
   req.type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price = price;
   req.tp = tp;
   req.deviation = 20;

   OrderSend(req, res);

   if(res.retcode == 10009 || res.retcode == 10008)
   {
      if(isBuy) state = BUY_STATE;
      else state = SELL_STATE;
   }
}
//+------------------------------------------------------------------+
void CheckTouch(double line, OrderState &state)
{
   if(state != NONE) return;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double range = 10 * _Point; // กันพลาดนิดหน่อย

   if(MathAbs(bid - line) <= range)
   {
      if(bid > line)
         OpenOrder(true, state);   // อยู่บน → BUY
      else
         OpenOrder(false, state);  // อยู่ล่าง → SELL
   }
}
//+------------------------------------------------------------------+
void OnTick()
{
   double D1 = GetOpenPrice(PERIOD_D1);
   double W1 = GetOpenPrice(PERIOD_W1);
   double MN = GetOpenPrice(PERIOD_MN1);

   CheckTouch(D1, state_D1);
   CheckTouch(W1, state_W1);
   CheckTouch(MN, state_MN);
}
