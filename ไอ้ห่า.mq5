//+------------------------------------------------------------------+
//|                                            TEST_XM_FINAL.mq5     |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;

bool done = false;

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
   req.volume = LotSize;
   req.type   = ORDER_TYPE_BUY;
   req.price  = NormalizeDouble(ask, _Digits);
   req.deviation = 50;

   // 🔥 ตัวนี้แหละปัญหา
   req.type_filling = ORDER_FILLING_IOC;

   OrderSend(req, res);

   Print("RET: ", res.retcode);

   done = true;
}
