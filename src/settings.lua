local common = require("common")

data:extend({{
    type = "int-setting",
    name = common.PERMUTATION_THRESHOLD_SETTING,
    setting_type = "startup",
    default_value = 120,
    minimum_value = 4,
    maximum_value = 10000,
  },
  {
    type = "bool-setting",
    name = common.SIMPLE_MODE_SETTING,
    setting_type = "startup",
    default_value = false
  }})
