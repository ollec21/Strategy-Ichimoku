/**
 * @file
 * Implements Ichimoku strategy based on the Ichimoku Kinko Hyo indicator.
 */

// User input params.
INPUT int Ichimoku_Period_Tenkan_Sen = 9;                // Period Tenkan Sen
INPUT int Ichimoku_Period_Kijun_Sen = 26;                // Period Kijun Sen
INPUT int Ichimoku_Period_Senkou_Span_B = 52;            // Period Senkou Span B
INPUT int Ichimoku_Shift = 0;                            // Shift
INPUT int Ichimoku_SignalOpenMethod = 0;                 // Signal open method (0-
INPUT float Ichimoku_SignalOpenLevel = 0.00000000;      // Signal open level
INPUT int Ichimoku_SignalOpenFilterMethod = 0.00000000;  // Signal open filter method
INPUT int Ichimoku_SignalOpenBoostMethod = 0.00000000;   // Signal open boost method
INPUT int Ichimoku_SignalCloseMethod = 0;                // Signal close method (0-
INPUT float Ichimoku_SignalCloseLevel = 0.00000000;     // Signal close level
INPUT int Ichimoku_PriceLimitMethod = 0;                 // Price limit method
INPUT float Ichimoku_PriceLimitLevel = 0;               // Price limit level
INPUT float Ichimoku_MaxSpread = 6.0;                   // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_Ichimoku.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_Ichimoku_Params : StgParams {
  int Ichimoku_Period_Tenkan_Sen;
  int Ichimoku_Period_Kijun_Sen;
  int Ichimoku_Period_Senkou_Span_B;
  int Ichimoku_Shift;
  int Ichimoku_SignalOpenMethod;
  double Ichimoku_SignalOpenLevel;
  int Ichimoku_SignalOpenFilterMethod;
  int Ichimoku_SignalOpenBoostMethod;
  int Ichimoku_SignalCloseMethod;
  double Ichimoku_SignalCloseLevel;
  int Ichimoku_PriceLimitMethod;
  double Ichimoku_PriceLimitLevel;
  double Ichimoku_MaxSpread;

  // Constructor: Set default param values.
  Stg_Ichimoku_Params()
      : Ichimoku_Period_Tenkan_Sen(::Ichimoku_Period_Tenkan_Sen),
        Ichimoku_Period_Kijun_Sen(::Ichimoku_Period_Kijun_Sen),
        Ichimoku_Period_Senkou_Span_B(::Ichimoku_Period_Senkou_Span_B),
        Ichimoku_Shift(::Ichimoku_Shift),
        Ichimoku_SignalOpenMethod(::Ichimoku_SignalOpenMethod),
        Ichimoku_SignalOpenLevel(::Ichimoku_SignalOpenLevel),
        Ichimoku_SignalOpenFilterMethod(::Ichimoku_SignalOpenFilterMethod),
        Ichimoku_SignalOpenBoostMethod(::Ichimoku_SignalOpenBoostMethod),
        Ichimoku_SignalCloseMethod(::Ichimoku_SignalCloseMethod),
        Ichimoku_SignalCloseLevel(::Ichimoku_SignalCloseLevel),
        Ichimoku_PriceLimitMethod(::Ichimoku_PriceLimitMethod),
        Ichimoku_PriceLimitLevel(::Ichimoku_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_Ichimoku_Params>(_params, _tf, stg_ichi_m1, stg_ichi_m5, stg_ichi_m15, stg_ichi_m30,
                                         stg_ichi_h1, stg_ichi_h4, stg_ichi_h4);
    }
    // Initialize strategy parameters.
    IchimokuParams ichi_params(_params.Ichimoku_Period_Tenkan_Sen, _params.Ichimoku_Period_Kijun_Sen,
                               _params.Ichimoku_Period_Senkou_Span_B);
    ichi_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Ichimoku(ichi_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Ichimoku_SignalOpenMethod, _params.Ichimoku_SignalOpenMethod,
                       _params.Ichimoku_SignalOpenFilterMethod, _params.Ichimoku_SignalOpenBoostMethod,
                       _params.Ichimoku_SignalCloseMethod, _params.Ichimoku_SignalCloseMethod);
    sparams.SetPriceLimits(_params.Ichimoku_PriceLimitMethod, _params.Ichimoku_PriceLimitLevel);
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
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_Ichimoku *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double _level_pips = _level * Chart().GetPipSize();
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          // Buy 1: Tenkan-sen crosses Kijun-sen upwards.
          _result = _indi[CURR].value[LINE_TENKANSEN] >= _indi[CURR].value[LINE_CHIKOUSPAN] &&
                    _indi[PREV].value[LINE_TENKANSEN] < _indi[PREV].value[LINE_CHIKOUSPAN];
          // Buy 2: Chinkou Span crosses chart upwards; price is ib the cloud.
          // @todo: if
          // ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)<iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)>=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
          // Buy 3: Price crosses Senkou Span-B upwards; price is outside Senkou Span cloud.
          // @todo:
          // (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)>iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)<=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)<iClose(NULL,pich2,0))
          break;
        case ORDER_TYPE_SELL:
          // Sell 1: Tenkan-sen crosses Kijun-sen downwards.
          _result = _indi[CURR].value[LINE_TENKANSEN] <= _indi[CURR].value[LINE_CHIKOUSPAN] &&
                    _indi[PREV].value[LINE_TENKANSEN] > _indi[PREV].value[LINE_CHIKOUSPAN];
          // Sell 2: Chinkou Span crosses chart downwards; price is ib the cloud.
          // @todo:
          // ((iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+1)>iClose(NULL,pich2,pkijun+1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_CHINKOUSPAN,pkijun+0)<=iClose(NULL,pich2,pkijun+0))&&((iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))||(iClose(NULL,pich2,0)<iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)&&iClose(NULL,pich2,0)>iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0))))
          // Sell 3: Price crosses Senkou Span-B downwards; price is outside Senkou Span cloud.
          // @todo:
          // (iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,1)<iClose(NULL,pich2,1)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANB,0)>=iClose(NULL,pich2,0)&&iIchimoku(NULL,pich,ptenkan,pkijun,psenkou,MODE_SENKOUSPANA,0)>iClose(NULL,pich2,0))
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_Ichimoku *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0:
          _result = _indi[CURR].value[LINE_TENKANSEN] + _trail * _direction;
          break;
        case 1:
          _result = _indi[CURR].value[LINE_KIJUNSEN] + _trail * _direction;
          break;
        case 2:
          _result = _indi[CURR].value[LINE_SENKOUSPANA] + _trail * _direction;
          break;
        case 3:
          _result = _indi[CURR].value[LINE_SENKOUSPANB] + _trail * _direction;
          break;
        case 4:
          _result = _indi[CURR].value[LINE_CHIKOUSPAN] + _trail * _direction;
          break;
        case 5:
          _result = _indi[CURR].value[LINE_CHIKOUSPAN] + _trail * _direction;
          break;
        case 6:
          _result = _indi[CURR].value.GetMinDbl(_indi.GetIDataType()) + _trail * _direction;
          break;
        case 7:
          _result = _indi[PREV].value.GetMinDbl(_indi.GetIDataType()) + _trail * _direction;
          break;
        case 8: {
          int _bar_count = (int)_level * (int)_indi.GetTenkanSen();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 9: {
          int _bar_count = (int)_level * (int)_indi.GetKijunSen();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
        case 10: {
          int _bar_count = (int)_level * (int)_indi.GetSenkouSpanB();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
      }
    }
    return _result;
  }
};
