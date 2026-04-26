//+------------------------------------------------------------------+
//|                                                   OpenLineEA.mq5 |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 10;
input int TP_Points = 444; // 444 จุด (5 digit = 4440)
input ENUM_TIMEFRAMES SmallTF = PERIOD_M5;

//--- state
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
bool IsTouch(double price, double high, double low)
{
   return (low <= price && high >= price);
}
//+------------------------------------------------------------------+
void OpenOrder(bool isBuy, double price, OrderState &state)
{
   if(state != NONE) return;

   double tp;
   if(isBuy)
      tp = price + TP_Points * _Point;
   else
      tp = price - TP_Points * _Point;

   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_DEAL;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                     : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   req.tp = tp;
   req.deviation = 20;

   if(OrderSend(req, res))
   {
      if(isBuy) state = BUY_STATE;
      else state = SELL_STATE;
   }
}
//+------------------------------------------------------------------+
void CheckEntry(double line, OrderState &state)
{
   double high = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double low  = iLow(_Symbol, PERIOD_CURRENT, 0);
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(state != NONE) return;

   if(price > line && IsTouch(line, high, low))
      OpenOrder(true, price, state);

   if(price < line && IsTouch(line, high, low))
      OpenOrder(false, price, state);
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

         OrderSend(req, res);
      }
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

   // ENTRY
   CheckEntry(D1, state_D1);
   CheckEntry(W1, state_W1);
   CheckEntry(MN, state_MN);

   // EXIT (smart cut)
   CheckExit(D1, state_D1);
   CheckExit(W1, state_W1);
   CheckExit(MN, state_MN);

   // equity protection
   CheckEquityCut();
}
