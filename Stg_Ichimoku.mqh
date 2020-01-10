//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Ichimoku strategy based on the Ichimoku Kinko Hyo indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Ichimoku.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Ichimoku_Parameters__ = "-- Ichimoku strategy params --";  // >>> ICHIMOKU <<<
INPUT int Ichimoku_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT ENUM_TRAIL_TYPE Ichimoku_TrailingStopMethod = 22;                  // Trail stop method
INPUT ENUM_TRAIL_TYPE Ichimoku_TrailingProfitMethod = 1;                 // Trail profit method
INPUT int Ichimoku_Period_Tenkan_Sen = 9;                                // Period Tenkan Sen
INPUT int Ichimoku_Period_Kijun_Sen = 26;                                // Period Kijun Sen
INPUT int Ichimoku_Period_Senkou_Span_B = 52;                            // Period Senkou Span B
INPUT double Ichimoku_SignalOpenLevel = 0.00000000;                      // Signal open level
INPUT int Ichimoku1_SignalBaseMethod = 0;                                // Signal base method (0-
INPUT int Ichimoku1_OpenCondition1 = 0;                                  // Open condition 1 (0-1023)
INPUT int Ichimoku1_OpenCondition2 = 0;                                  // Open condition 2 (0-)
INPUT ENUM_MARKET_EVENT Ichimoku1_CloseCondition = C_ICHIMOKU_BUY_SELL;  // Close condition for M1
INPUT double Ichimoku_MaxSpread = 6.0;                                   // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Ichimoku_Params : Stg_Params {
  unsigned int Ichimoku_Period;
  ENUM_APPLIED_PRICE Ichimoku_Applied_Price;
  int Ichimoku_Shift;
  ENUM_TRAIL_TYPE Ichimoku_TrailingStopMethod;
  ENUM_TRAIL_TYPE Ichimoku_TrailingProfitMethod;
  double Ichimoku_SignalOpenLevel;
  long Ichimoku_SignalBaseMethod;
  long Ichimoku_SignalOpenMethod1;
  long Ichimoku_SignalOpenMethod2;
  double Ichimoku_SignalCloseLevel;
  ENUM_MARKET_EVENT Ichimoku_SignalCloseMethod1;
  ENUM_MARKET_EVENT Ichimoku_SignalCloseMethod2;
  double Ichimoku_MaxSpread;

  // Constructor: Set default param values.
  Stg_Ichimoku_Params()
      : Ichimoku_Period(::Ichimoku_Period),
        Ichimoku_Applied_Price(::Ichimoku_Applied_Price),
        Ichimoku_Shift(::Ichimoku_Shift),
        Ichimoku_TrailingStopMethod(::Ichimoku_TrailingStopMethod),
        Ichimoku_TrailingProfitMethod(::Ichimoku_TrailingProfitMethod),
        Ichimoku_SignalOpenLevel(::Ichimoku_SignalOpenLevel),
        Ichimoku_SignalBaseMethod(::Ichimoku_SignalBaseMethod),
        Ichimoku_SignalOpenMethod1(::Ichimoku_SignalOpenMethod1),
        Ichimoku_SignalOpenMethod2(::Ichimoku_SignalOpenMethod2),
        Ichimoku_SignalCloseLevel(::Ichimoku_SignalCloseLevel),
        Ichimoku_SignalCloseMethod1(::Ichimoku_SignalCloseMethod1),
        Ichimoku_SignalCloseMethod2(::Ichimoku_SignalCloseMethod2),
        Ichimoku_MaxSpread(::Ichimoku_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Ichimoku : public Strategy {
 public:
  Stg_Ichimoku(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Ichimoku *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Ichimoku_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Ichimoku_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Ichimoku_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Ichimoku_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Ichimoku_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Ichimoku_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Ichimoku_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    Ichimoku_Params adx_params(_params.Ichimoku_Period, _params.Ichimoku_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_Ichimoku);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Ichimoku(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Ichimoku_SignalBaseMethod, _params.Ichimoku_SignalOpenMethod1,
                       _params.Ichimoku_SignalOpenMethod2, _params.Ichimoku_SignalCloseMethod1,
                       _params.Ichimoku_SignalCloseMethod2, _params.Ichimoku_SignalOpenLevel,
                       _params.Ichimoku_SignalCloseLevel);
    sparams.SetStops(_params.Ichimoku_TrailingProfitMethod, _params.Ichimoku_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Ichimoku_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Ichimoku(sparams, "Ichimoku");
    return _strat;
  }

  /**
   * Check if Ichimoku indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double ichimoku_0_tenkan_sen = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_TENKANSEN, 0);
    double ichimoku_0_kijun_sen = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_KIJUNSEN, 0);
    double ichimoku_0_senkou_span_a = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_SENKOUSPANA, 0);
    double ichimoku_0_senkou_span_b = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_SENKOUSPANB, 0);
    double ichimoku_0_chikou_span = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_CHIKOUSPAN, 0);
    double ichimoku_1_tenkan_sen = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_TENKANSEN, 1);
    double ichimoku_1_kijun_sen = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_KIJUNSEN, 1);
    double ichimoku_1_senkou_span_a = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_SENKOUSPANA, 1);
    double ichimoku_1_senkou_span_b = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_SENKOUSPANB, 1);
    double ichimoku_1_chikou_span = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_CHIKOUSPAN, 1);
    double ichimoku_2_tenkan_sen = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_TENKANSEN, 2);
    double ichimoku_2_kijun_sen = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_KIJUNSEN, 2);
    double ichimoku_2_senkou_span_a = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_SENKOUSPANA, 2);
    double ichimoku_2_senkou_span_b = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_SENKOUSPANB, 2);
    double ichimoku_2_chikou_span = ((Indi_Ichimoku *)this.Data()).GetValue(LINE_CHIKOUSPAN, 2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      /*
        //15. Ichimoku Kinko Hyo (1)
        //Buy: Price crosses Senkou Span-B upwards; price is outside Senkou Span cloud
        //Sell: Price crosses Senkou Span-B downwards; price is outside Senkou Span cloud
        if
        (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)>iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)<=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)<iClose(NULL,pich2,0))
        {f15=1;}
        if
        (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)<iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)>=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)>iClose(NULL,pich2,0))
        {f15=-1;}
      */
      /*
        //16. Ichimoku Kinko Hyo (2)
        //Buy: Tenkan-sen crosses Kijun-sen upwards
        //Sell: Tenkan-sen crosses Kijun-sen downwards
        //VERSION EXISTS, IN THIS CASE PRICE MUSTN'T BE IN THE CLOUD!
        if
        (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,1)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,0)>=iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,0))
        {f16=1;}
        if
        (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,1)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_TENKANSEN,0)<=iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_KIJUNSEN,0))
        {f16=-1;}
      */

      /*
        //17. Ichimoku Kinko Hyo (3)
        //Buy: Chinkou Span crosses chart upwards; price is ib the cloud
        //Sell: Chinkou Span crosses chart downwards; price is ib the cloud
        if
        ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)<iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)>=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
        {f17=1;}
        if
        ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)>iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)<=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
        {f17=-1;}
      */
      case ORDER_TYPE_BUY:
        break;
      case ORDER_TYPE_SELL:
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
