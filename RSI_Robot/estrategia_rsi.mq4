//+------------------------------------------------------------------+
//|                                               estrategia_rsi.mq4 |
//|                                             Steven Parra Giraldo |
//|                 https://github.com/StraigenDaigen/Trading_Robots |
//|                                      Agradecimientos a Ramón Ruiz|
//|                                       https://www.hobbiecode.com/|
//+------------------------------------------------------------------+



#property copyright "Steven Parra Giraldo"
#property link      "https://github.com/StraigenDaigen/Trading_Robots"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Declaración de Variable y Clases                                   |
//+------------------------------------------------------------------+


//VARIABLES INPUT 
input int media_movil_tendencia = 100;

input int velas_ultimo_min_max=15; 

input double parametro_atr=0.0006;

input bool lotes_fijos=false;

input double valor_lote_fijo=0.1;

//input int media_movil_sl=20;




input double ratio_take_profit=5;


//Delay asumible mientras se envia la orden en servidor
input double slippage=100;

//Identificador de Robot o Estrategia
input double magic =1;

input double cotizacion=1.0;

input double riesgo=0.01;

input int trailing_stop=1;

input double sl_margen=0.0003;




//VARIABLES GLOBALES 

double stop_loss=0;

double lotes=0;

datetime fecha = 0;

double entry=0;

double lot_entry=0;

double tp = 0;

double sl=0;

double ticket_buy=0;

double ticket_sell=0;

bool in_operation = false;

double spread=0;

double precio_por_pip=0;









//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //Inicialización del ROBOT
   
   precio_por_pip=(1/(MathPow(10,(Digits-1))))*100000/cotizacion;
  
//---
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      //INICIALIZACION DE VARIABLES CADA TICK
   //Para Operar a vela cerrada
   if(Time[0]!=fecha){
  
      spread= Ask - Bid;
      
      //CONDICION DE COMPRA
      
      if (entradaCompra() && !(in_operation)){
      
         entry=Ask;
         sl= NormalizeDouble(ultimoMinimo()-sl_margen,Digits);
         //sl = NormalizeDouble(Low[1]-Point,Digits);
         
         if (lotes_fijos==true){
            lot_entry=valor_lote_fijo;
         }
         else{
            lot_entry= NormalizeDouble(AccountBalance()*riesgo/(precio_por_pip*((entry-sl)*(MathPow(10,(Digits-1))))),2);
         }
         
         
         tp= NormalizeDouble(entry+((entry-sl-spread)*ratio_take_profit),Digits);
         
         Print("Entrada en Buy a precio: " + entry + " SL: " + sl + " TP: " + tp + " Lot: " + lot_entry);
         
         ticket_buy= OrderSend(Symbol(), OP_BUY, lot_entry, entry, slippage, sl, tp, NULL, magic, 0, Blue);
         
         if (ticket_buy==-1){
            Print("Error en compra BUY");
         }
         
         if (ticket_buy>0){
            
            in_operation=true;
         }
         
         
         
      }
      
      //CONDICION DE VENTA
      
      if (entradaVenta() && !(in_operation)){
      
         entry=Bid;
         sl= NormalizeDouble(ultimoMaximo()+sl_margen+spread,Digits);
         //sl = NormalizeDouble(High[1]+Point+spread,Digits);
         
         if (lotes_fijos==true){
            lot_entry=valor_lote_fijo;
         }
         else{
            lot_entry=NormalizeDouble(AccountBalance()*riesgo/(precio_por_pip*((sl-entry)*(MathPow(10,(Digits-1))))),2);
         }
      
         
         tp= NormalizeDouble(entry-((sl-entry)*ratio_take_profit)+spread,Digits);
         
         Print("Entrada en Sell a precio: " + entry + " SL: " + sl + " TP: " + tp + " Lot: " + lot_entry);
         
         ticket_sell= OrderSend(Symbol(), OP_SELL, lot_entry, entry, slippage, sl, tp, NULL, magic, 0, Blue);
         
         if (ticket_sell==-1){
            Print("Error en venta SELL");
         }
         
         if (ticket_sell>0){
            
            in_operation=true;
         }
         
         
         
      }
      
      //¿ESTAMOS DENTRO DE OPERACION?
      
      //TRAILING STOP
      
      if(in_operation){
      
         trailingStop();
      }
      
      fecha=Time[0];
      
   }
   
  }
//+------------------------------------------------------------------+


//Funcion para iniciar compra
bool entradaCompra(){

   
  
   if (atr_senal()==true && rsi_compra()==true && ma_alcista()==true){
   
         
      return true;
       
   }
   
   else{
      return false;
   }
   
}


//Funcion para iniciar compra
bool entradaVenta(){


 

  if ( atr_senal()==true && rsi_venta()==true && ma_bajista()==true){
      
      
      return true;
  
   }
   
   else{
      return false;
   }
  
   
   return false;
   
}



//Indica si ya entro en la operacion
bool entered(){

   return true;

}


//funcion que mueve el stop 
void trailingStop(){

   int num_ops=0;
   double trailing=0;
   
   for (int i=OrdersTotal()-1; i>=0; i--){
   
      if(OrderSelect(i, SELECT_BY_POS)){
      
         if(OrderTicket()==ticket_buy && Close[0]>(OrderOpenPrice()+(0.5*(OrderOpenPrice()-OrderStopLoss())))&& trailing_stop==1){
      
            trailing = Low[1]; /*iMA(Symbol(),Period(),media_movil_sl,0,MODE_EMA, PRICE_CLOSE, 1);  */   //OrderOpenPrice();
            
            if(NormalizeDouble(trailing,Digits)!= OrderStopLoss()){
    
               OrderModify(ticket_buy, OrderOpenPrice(), NormalizeDouble(trailing,Digits), OrderTakeProfit(), OrderExpiration(),0);
     
            
            }
         }
         
         
         if(OrderTicket()==ticket_sell && Close[0]<(OrderOpenPrice()-(0.5*(OrderStopLoss()-OrderOpenPrice())))&& trailing_stop==1){
      
            trailing= High[1]; /*iMA(Symbol(),Period(),media_movil_sl,0,MODE_EMA, PRICE_CLOSE, 1);*/          //  //OrderClosePrice();
            
            if(NormalizeDouble(trailing,Digits)!= OrderStopLoss()){
               //OrderClosePrice()
               OrderModify(ticket_sell,  OrderOpenPrice(), NormalizeDouble(trailing,Digits), OrderTakeProfit(), OrderExpiration(),0);
     
            
            }
         }
         
         if(OrderType() == OP_SELL || OrderType() == OP_BUY){
            
            num_ops=num_ops+1;
         
         }
      
      
      
      }
   
   
   
   }
   
   if(num_ops==0){
   
      Print("Reseteamos por cierre de operacion");
      closeAll();
   
   }

}




double ultimoMinimo (){

   double min=99999;
   
   for (int i=1; i<=velas_ultimo_min_max; i++){
      
      if (Low[i]<min){
         min=Low[i];
      }
      
   }
   
   return min;
}


double ultimoMaximo (){

   double max=-99999;
   
   for (int i=1; i<=velas_ultimo_min_max; i++){
      
      if (High[i]>max){
         max=High[i];
      }
      
   }
   
   return max;
}



void closeAll(){
   
   Print("Close ALL");
   
   
   
   for (int i=OrdersTotal()-1;i>=0; i--){
      
      if(OrderSelect(i, SELECT_BY_POS)){
         
         if(OrderType()== OP_BUYSTOP || OrderType()== OP_SELLSTOP){
         
            OrderDelete(OrderTicket(), Red);
         }
      
      }
   
   }
   
   
   in_operation=false;
   ticket_buy=0;
   ticket_sell=0;


}













bool atr_senal(){


   double atr=0;
   
   atr= iATR(Symbol(),Period(),7,1);
   
   if(atr>parametro_atr){
   
      return true;
   }
   
   else{
      
      return false;
   
   }


}



bool rsi_compra(){


   double rsi=0;
   
   rsi= iRSI(Symbol(),Period(),2,PRICE_CLOSE,1);
   
   if(rsi<5){
   
      return true;
   }
   
   else{
   
      return false;
   
   }


}


bool rsi_venta(){


   double rsi=0;
   
   rsi= iRSI(Symbol(),Period(),2,PRICE_CLOSE,1);
   
   if(rsi>95){
   
      return true;
   }
   
   else{
   
      return false;
   
   }


}

bool ma_alcista(){

   double ma=0;
   
   ma= iMA(Symbol(),Period(),media_movil_tendencia,0,MODE_EMA,PRICE_CLOSE,1);
   
   if(Low[1]>ma){
   
      return true;
   }
   
   else{
   
      return false;
   }

}

bool ma_bajista(){

   double ma=0;
   
   ma= iMA(Symbol(),Period(),media_movil_tendencia,0,MODE_EMA,PRICE_CLOSE,1);
   
   if(High[1]<ma){
   
      return true;
   }
   
   else{
   
      return false;
   }

}


