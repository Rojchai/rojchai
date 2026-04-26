//+------------------------------------------------------------------+
//|                                             OpenLineEA_FINAL.mq5 |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;
input int TP_Points = 444;
input ENUM_TIMEFRAMES SmallTF = PERIOD_M5;

//--- state
enum OrderState { NONE, BUY_STATE, SELL_STATE };

OrderState state_D1 = NONE;
OrderState state_W1 = NONE;
OrderState state_MN = NONE;

bool wasAbove_D1 = false;
bool wasAbove_W1 = false;
bool wasAbove_MN = false;

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
   req.type   = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price  = NormalizeDouble(price, _Digits);
   req.tp     = NormalizeDouble(tp, _Digits);
   req.deviation = 50;
   req.type_filling = GetFilling();

   OrderSend(req, res);

   if(res.retcode == 10009 || res.retcode == 10008)
   {
      if(isBuy) state = BUY_STATE;
      else state = SELL_STATE;
   }
}
//+------------------------------------------------------------------+
void CheckEntry(double line, OrderState &state, bool &wasAbove)
{
   if(state != NONE) return;

   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double buffer = 5 * _Point;

   // อยู่เหนือ
   if(price > line + buffer)
   {
      wasAbove = true;
   }
   // อยู่ใต้
   else if(price < line - buffer)
   {
      wasAbove = false;
   }
   // แตะเส้น
   else
   {
      if(wasAbove)
         OpenOrder(true, state);   // BUY
      else
         OpenOrder(false, state);  // SELL
   }
}
//+------------------------------------------------------------------+
bool BodyCrossDown(double open, double close, double line)
{
   return (open > line && close < line);
}
//+------------------------------------------------------------------+
bool BodyCrossUp(double open, double close, double line)
{
   return (open < line && close > line);
}
//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         MqlTradeRequest req;
         MqlTradeResult res;

         ZeroMemory(req);
         ZeroMemory(res);

         req.action = TRADE_ACTION_DEAL;
         req.position = ticket;
         req.symbol = _Symbol;
         req.volume = PositionGetDouble(POSITION_VOLUME);

         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            req.type = ORDER_TYPE_SELL;
            req.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         }
         else
         {
            req.type = ORDER_TYPE_BUY;
            req.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         }

         req.type_filling = GetFilling();

         OrderSend(req, res);
      }
   }
}
//+------------------------------------------------------------------+
void CheckExit(double line, OrderState &state)
{
   if(state == NONE) return;

   double open = iOpen(_Symbol, SmallTF, 1);
   double close = iClose(_Symbol, SmallTF, 1);

   if(state == BUY_STATE && BodyCrossDown(open, close, line))
   {
      CloseAll();
      state = NONE;
   }

   if(state == SELL_STATE && BodyCrossUp(open, close, line))
   {
      CloseAll();
      state = NONE;
   }
}
//+------------------------------------------------------------------+
void CheckEquityCut()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);

   if(equity <= balance * 0.5)
      CloseAll();
}
//+------------------------------------------------------------------+
void OnTick()
{
   double D1 = GetOpenPrice(PERIOD_D1);
   double W1 = GetOpenPrice(PERIOD_W1);
   double MN = GetOpenPrice(PERIOD_MN1);

   CheckEntry(D1, state_D1, wasAbove_D1);
   CheckEntry(W1, state_W1, wasAbove_W1);
   CheckEntry(MN, state_MN, wasAbove_MN);

   CheckExit(D1, state_D1);
   CheckExit(W1, state_W1);
   CheckExit(MN, state_MN);

   CheckEquityCut();
}
