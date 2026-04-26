//+------------------------------------------------------------------+
//|                                                TEST_XM_FIX.mq5   |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;

bool done = false;

//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(lot, minLot);
   lot = MathFloor(lot / step) * step;

   return lot;
}
//+------------------------------------------------------------------+
void OnTick()
{
   if(done) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = NormalizeLot(LotSize);
   req.type   = ORDER_TYPE_BUY;
   req.price  = NormalizeDouble(ask, _Digits);
   req.deviation = 50;

   OrderSend(req, res);

   Print("RET: ", res.retcode);
   Print("SYMBOL: ", _Symbol);
   Print("LOT: ", req.volume);

   done = true;
}
