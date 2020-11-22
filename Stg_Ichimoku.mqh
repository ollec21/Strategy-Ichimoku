/**
 * @file
 * Implements Ichimoku strategy based on the Ichimoku Kinko Hyo indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Ichimoku.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float Ichimoku_LotSize = 0;                        // Lot size
INPUT int Ichimoku_SignalOpenMethod = 0;                 // Signal open method (0-
INPUT float Ichimoku_SignalOpenLevel = 0.00000000;       // Signal open level
INPUT int Ichimoku_SignalOpenFilterMethod = 0.00000000;  // Signal open filter method
INPUT int Ichimoku_SignalOpenBoostMethod = 0.00000000;   // Signal open boost method
INPUT int Ichimoku_SignalCloseMethod = 0;                // Signal close method (0-
INPUT float Ichimoku_SignalCloseLevel = 0.00000000;      // Signal close level
INPUT int Ichimoku_PriceStopMethod = 0;                  // Price stop method
INPUT float Ichimoku_PriceStopLevel = 0;                 // Price stop level
INPUT int Ichimoku_TickFilterMethod = 0;                 // Tick filter method
INPUT float Ichimoku_MaxSpread = 6.0;                    // Max spread to trade (pips)
INPUT int Ichimoku_Shift = 0;                            // Shift
INPUT string __Ichimoku_Indi_Ichimoku_Parameters__ =
    "-- Ichimoku strategy: Ichimoku indicator params --";  // >>> Ichimoku strategy: Ichimoku indicator <<<
INPUT int Indi_Ichimoku_Period_Tenkan_Sen = 9;             // Period Tenkan Sen
INPUT int Indi_Ichimoku_Period_Kijun_Sen = 26;             // Period Kijun Sen
INPUT int Indi_Ichimoku_Period_Senkou_Span_B = 52;         // Period Senkou Span B

// Structs.

// Defines struct with default user indicator values.
struct Indi_Ichimoku_Params_Defaults : IchimokuParams {
  Indi_Ichimoku_Params_Defaults()
      : IchimokuParams(::Indi_Ichimoku_Period_Tenkan_Sen, ::Indi_Ichimoku_Period_Kijun_Sen,
                       ::Indi_Ichimoku_Period_Senkou_Span_B) {}
} indi_ichi_defaults;

// Defines struct to store indicator parameter values.
struct Indi_Ichimoku_Params : public IchimokuParams {
  // Struct constructors.
  void Indi_Ichimoku_Params(IchimokuParams &_params, ENUM_TIMEFRAMES _tf) : IchimokuParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_Ichimoku_Params_Defaults : StgParams {
  Stg_Ichimoku_Params_Defaults()
      : StgParams(::Ichimoku_SignalOpenMethod, ::Ichimoku_SignalOpenFilterMethod, ::Ichimoku_SignalOpenLevel,
                  ::Ichimoku_SignalOpenBoostMethod, ::Ichimoku_SignalCloseMethod, ::Ichimoku_SignalCloseLevel,
                  ::Ichimoku_PriceStopMethod, ::Ichimoku_PriceStopLevel, ::Ichimoku_TickFilterMethod,
                  ::Ichimoku_MaxSpread, ::Ichimoku_Shift) {}
} stg_ichi_defaults;

// Struct to define strategy parameters to override.
struct Stg_Ichimoku_Params : StgParams {
  Indi_Ichimoku_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_Ichimoku_Params(Indi_Ichimoku_Params &_iparams, StgParams &_sparams)
      : iparams(indi_ichi_defaults, _iparams.tf), sparams(stg_ichi_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Ichimoku : public Strategy {
 public:
  Stg_Ichimoku(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Ichimoku *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_Ichimoku_Params _indi_params(indi_ichi_defaults, _tf);
    StgParams _stg_params(stg_ichi_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_Ichimoku_Params>(_indi_params, _tf, indi_ichi_m1, indi_ichi_m5, indi_ichi_m15, indi_ichi_m30,
                                          indi_ichi_h1, indi_ichi_h4, indi_ichi_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_ichi_m1, stg_ichi_m5, stg_ichi_m15, stg_ichi_m30, stg_ichi_h1,
                               stg_ichi_h4, stg_ichi_h8);
    }
    // Initialize indicator.
    IchimokuParams ichi_params(_indi_params);
    _stg_params.SetIndicator(new Indi_Ichimoku(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Ichimoku(_stg_params, "Ichimoku");
    _stg_params.SetStops(_strat, _strat);
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
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
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
          int _bar_count1 = (int)_level * (int)_indi.GetTenkanSen();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count1))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count1));
          break;
        }
        case 9: {
          int _bar_count2 = (int)_level * (int)_indi.GetKijunSen();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count2))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count2));
          break;
        }
        case 10: {
          int _bar_count3 = (int)_level * (int)_indi.GetSenkouSpanB();
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count3))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count3));
          break;
        }
      }
    }
    return (float)_result;
  }
};
