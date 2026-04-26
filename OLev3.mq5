//+------------------------------------------------------------------+
//|                                               OpenLineEA_v3.mq5  |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 1;
input int TP_Points = 444;   // XAU ใช้แบบนี้ก่อน
input ENUM_TIMEFRAMES SmallTF = PERIOD_M5;

//--- state
enum OrderState { NONE, BUY_STATE, SELL_STATE };

OrderState state_D1 = NONE;
OrderState state_W1 = NONE;
OrderState state_MN = NONE;

// จำว่า “ก่อนหน้านี้ราคาอยู่ฝั่งไหน”
bool wasAbove_D1 = false;
bool wasAbove_W1 = false;
bool wasAbove_MN = false;

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
void CheckEntry(double line, OrderState &state, bool &wasAbove)
{
   if(state != NONE) return;

   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // อยู่เหนือ
   if(price > line)
   {
      // ถ้าเคยอยู่ล่าง → แปลว่าขึ้นมาแตะ → SELL
      if(!wasAbove)
      {
         OpenOrder(false, state);
      }
      wasAbove = true;
   }
   // อยู่ใต้
   else if(price < line)
   {
      // ถ้าเคยอยู่บน → ลงมาแตะ → BUY
      if(wasAbove)
      {
         OpenOrder(true, state);
      }
      wasAbove = false;
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

   // ENTRY
   CheckEntry(D1, state_D1, wasAbove_D1);
   CheckEntry(W1, state_W1, wasAbove_W1);
   CheckEntry(MN, state_MN, wasAbove_MN);

   // EXIT
   CheckExit(D1, state_D1);
   CheckExit(W1, state_W1);
   CheckExit(MN, state_MN);

   // CUT
   CheckEquityCut();
}
