module GenX_to_Macro

using JSON3
using DataFrames
using CSV

export make_macro_dir
export make_commodities_json
export make_timedata_json
export make_nodes_json_demands_and_fuels

include("convert_genx_to_macro.jl")

end # module GenX_to_Macro
