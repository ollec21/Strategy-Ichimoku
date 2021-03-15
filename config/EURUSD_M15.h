/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Ichimoku_Params_M15 : IchimokuParams {
  Indi_Ichimoku_Params_M15() : IchimokuParams(indi_ichi_defaults, PERIOD_M15) {
    kijun_sen = 28
    senkou_span_b = 42
    shift = 0;
    tenkan_sen = 21
  }
} indi_ichi_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Ichimoku_Params_M15 : StgParams {
  // Struct constructor.
  Stg_Ichimoku_Params_M15() : StgParams(stg_ichi_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)1;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ichi_m15;
