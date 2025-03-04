using GenX_to_Macro

genx_case_path = "genx_cases/64zones_genx_0_4";
commodities_vec = ["Electricity", "NaturalGas", "CO2", "Uranium"];
macro_case_path = joinpath(genx_case_path,"macro_inputs");

setup,inputs = load_genx_case(genx_case_path);

make_macro_dir(macro_case_path);

commodities = make_commodities_json(commodities_vec, macro_case_path);
time_data = make_timedata_json(inputs, setup,commodities_vec,genx_case_path, macro_case_path);
nodes,demand,fuel_prices = make_nodes_json_demands_and_fuels(inputs, macro_case_path);

thermal = make_thermal_json(inputs, macro_case_path);
vre = make_vre_json(inputs, macro_case_path);
storage = make_storage_json(inputs, setup, macro_case_path);
transmission = make_transmission_json(inputs, macro_case_path);
mustrun = make_mustrun_json(inputs,macro_case_path);
hydro = make_hydro_json(inputs, setup, macro_case_path);
