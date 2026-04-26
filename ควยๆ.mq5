#property strict

input double LotSize = 0.1;

bool done = false;

//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
   int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);

   if(filling & SYMBOL_FILLING_FOK)
      return ORDER_FILLING_FOK;

   if(filling & SYMBOL_FILLING_IOC)
      return ORDER_FILLING_IOC;

   return ORDER_FILLING_RETURN;
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
   req.volume = LotSize;
   req.type   = ORDER_TYPE_BUY;
   req.price  = NormalizeDouble(ask, _Digits);
   req.deviation = 50;

   // 🔥 ใช้ค่าจริงจากโบรก
   req.type_filling = GetFillingMode();

   OrderSend(req, res);

   Print("RET: ", res.retcode);
   Print("FILLING USED: ", req.type_filling);

   done = true;
}
