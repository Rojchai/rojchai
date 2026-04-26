//+------------------------------------------------------------------+
//|                                              TEST_XM_FIX_v2.mq5  |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;

bool done = false;

//+------------------------------------------------------------------+
double FixLot(double lot)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   Print("MIN LOT: ", minLot);
   Print("STEP LOT: ", stepLot);

   // ปรับให้อยู่ใน range
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);

   // ปรับให้ตรง step เป๊ะ
   lot = MathRound(lot / stepLot) * stepLot;

   return NormalizeDouble(lot, 2);
}
//+------------------------------------------------------------------+
void OnTick()
{
   if(done) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double fixedLot = FixLot(LotSize);

   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = fixedLot;
   req.type   = ORDER_TYPE_BUY;
   req.price  = NormalizeDouble(ask, _Digits);
   req.deviation = 50;

   OrderSend(req, res);

   Print("RET: ", res.retcode);
   Print("LOT USED: ", fixedLot);

   done = true;
}
