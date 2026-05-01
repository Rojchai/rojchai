//+------------------------------------------------------------------+
//|                 Reverse Trailing Grid EA (XM READY)              |
//+------------------------------------------------------------------+
#property strict

input double LotSize = 0.1;
input int Distance_Open = 150;     // point
input int Trail_Distance = 100;    // point
input int MagicNumber = 202604;

//+------------------------------------------------------------------+
double buy_price = 0;
double sell_price = 0;

//+------------------------------------------------------------------+
int OnInit()
{
   Print("EA STARTED");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
   Print("RUNNING | BID: ", SymbolInfoDouble(_Symbol, SYMBOL_BID));

   if(PositionsTotal() == 0)
   {
      OpenBuy();
      return;
   }

   ManagePositions();
}

//+------------------------------------------------------------------+
void ManagePositions()
{
   bool hasBuy = false;
   bool hasSell = false;

   for(int i=0;i<PositionsTotal();i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

         int type = PositionGetInteger(POSITION_TYPE);

         if(type == POSITION_TYPE_BUY)
         {
            hasBuy = true;
            buy_price = PositionGetDouble(POSITION_PRICE_OPEN);
         }
         else if(type == POSITION_TYPE_SELL)
         {
            hasSell = true;
            sell_price = PositionGetDouble(POSITION_PRICE_OPEN);
         }
      }
   }

   if(hasBuy) ManageBuy();
   if(hasSell) ManageSell();
}

//+------------------------------------------------------------------+
void ManageBuy()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double trigger = buy_price + Distance_Open * _Point;
   double new_price = bid - Trail_Distance * _Point;

   ulong ticket = FindPending(ORDER_TYPE_SELL_STOP);

   if(ticket == 0)
   {
      double price = buy_price - Distance_Open * _Point;
      PlaceSellStop(price);
      return;
   }

   if(bid >= trigger)
   {
      double old_price = GetOrderPrice(ticket);

      if(new_price > old_price)
         ModifyOrder(ticket, new_price);
   }
}

//+------------------------------------------------------------------+
void ManageSell()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   double trigger = sell_price - Distance_Open * _Point;
   double new_price = ask + Trail_Distance * _Point;

   ulong ticket = FindPending(ORDER_TYPE_BUY_STOP);

   if(ticket == 0)
   {
      double price = sell_price + Distance_Open * _Point;
      PlaceBuyStop(price);
      return;
   }

   if(ask <= trigger)
   {
      double old_price = GetOrderPrice(ticket);

      if(new_price < old_price)
         ModifyOrder(ticket, new_price);
   }
}

//+------------------------------------------------------------------+
// จับ event ตอน pending ถูก activate
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;

   if(!HistoryDealSelect(trans.deal)) return;

   if(HistoryDealGetInteger(trans.deal, DEAL_ENTRY) != DEAL_ENTRY_IN) return;

   int type = HistoryDealGetInteger(trans.deal, DEAL_TYPE);
   long magic = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);

   if(magic != MagicNumber) return;

   if(type == DEAL_TYPE_SELL)
      CloseAll(POSITION_TYPE_BUY);

   if(type == DEAL_TYPE_BUY)
      CloseAll(POSITION_TYPE_SELL);
}

//+------------------------------------------------------------------+
void CloseAll(int position_type)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;

         if(PositionGetInteger(POSITION_TYPE) == position_type)
         {
            ulong ticket = PositionGetInteger(POSITION_TICKET);

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
            req.type_filling = ORDER_FILLING_IOC;

            if(position_type == POSITION_TYPE_BUY)
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
   req.type_filling = ORDER_FILLING_IOC;

   if(!OrderSend(req, res))
      Print("Buy failed: ", res.retcode);
   else
      Print("Buy opened");
}

//+------------------------------------------------------------------+
void PlaceSellStop(double price)
{
   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_PENDING;
   req.type = ORDER_TYPE_SELL_STOP;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.price = price;
   req.magic = MagicNumber;
   req.type_filling = ORDER_FILLING_IOC;

   OrderSend(req, res);
}

//+------------------------------------------------------------------+
void PlaceBuyStop(double price)
{
   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_PENDING;
   req.type = ORDER_TYPE_BUY_STOP;
   req.symbol = _Symbol;
   req.volume = LotSize;
   req.price = price;
   req.magic = MagicNumber;
   req.type_filling = ORDER_FILLING_IOC;

   OrderSend(req, res);
}

//+------------------------------------------------------------------+
ulong FindPending(int type)
{
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderGetTicket(i))
      {
         if(OrderGetInteger(ORDER_MAGIC) != MagicNumber) continue;

         if(OrderGetInteger(ORDER_TYPE) == type)
            return OrderGetTicket(i);
      }
   }
   return 0;
}

//+------------------------------------------------------------------+
double GetOrderPrice(ulong ticket)
{
   if(OrderSelect(ticket))
      return OrderGetDouble(ORDER_PRICE_OPEN);

   return 0;
}

//+------------------------------------------------------------------+
void ModifyOrder(ulong ticket, double price)
{
   MqlTradeRequest req;
   MqlTradeResult res;

   ZeroMemory(req);
   ZeroMemory(res);

   req.action = TRADE_ACTION_MODIFY;
   req.order = ticket;
   req.price = price;

   OrderSend(req, res);
}
//+------------------------------------------------------------------+
