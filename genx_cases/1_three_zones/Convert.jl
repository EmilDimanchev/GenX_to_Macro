using GenX
using GenX_to_Macro

genx_case_path = "genx_cases/1_three_zones";
commodities_vec = ["Electricity", "NaturalGas", "CO2"];
macro_case_path = joinpath(genx_case_path,"1_three_zones_macro");

genx_settings = GenX.get_settings_path(genx_case_path, "genx_settings.yml") # Settings YAML file path
writeoutput_settings = GenX.get_settings_path(genx_case_path, "output_settings.yml") # Write-output settings YAML file path
setup = GenX.configure_settings(genx_settings, writeoutput_settings) # mysetup dictionary stores settings and GenX-specific parameters
setup["ParameterScale"] = 0;
settings_path = GenX.get_settings_path(genx_case_path)
inputs = GenX.load_inputs(setup, genx_case_path)

make_macro_dir(macro_case_path);

commodities = make_commodities_json(commodities_vec, macro_case_path);
time_data = make_timedata_json(inputs, setup,commodities_vec,genx_case_path, macro_case_path);
nodes,demand,fuel_prices = make_nodes_json_demands_and_fuels(inputs, macro_case_path);

