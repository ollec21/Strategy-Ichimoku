//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Ichimoku_EURUSD_M30_Params : Stg_Ichimoku_Params {
  Stg_Ichimoku_EURUSD_M30_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M30;
    Ichimoku_Period = 2;
    Ichimoku_Applied_Price = 3;
    Ichimoku_Shift = 0;
    Ichimoku_TrailingStopMethod = 6;
    Ichimoku_TrailingProfitMethod = 11;
    Ichimoku_SignalOpenLevel = 36;
    Ichimoku_SignalBaseMethod = 0;
    Ichimoku_SignalOpenMethod1 = 195;
    Ichimoku_SignalOpenMethod2 = 0;
    Ichimoku_SignalCloseLevel = 36;
    Ichimoku_SignalCloseMethod1 = 1;
    Ichimoku_SignalCloseMethod2 = 0;
    Ichimoku_MaxSpread = 5;
  }
};
