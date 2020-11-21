/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Ichimoku_Params_M15 : Indi_Ichimoku_Params {
  Indi_Ichimoku_Params_M15() : Indi_Ichimoku_Params(indi_ichi_defaults, PERIOD_M15) { shift = 0; }
} indi_ichi_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Ichimoku_Params_M15 : StgParams {
  // Struct constructor.
  Stg_Ichimoku_Params_M15() : StgParams(stg_ichi_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = 0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = 0;
    price_limit_method = 0;
    price_limit_level = 2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_ichi_m15;
