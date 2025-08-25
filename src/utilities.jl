
####### UTILS #######

function load_genx_case(genx_case_path::AbstractString)

    genx_settings = GenX.get_settings_path(genx_case_path, "genx_settings.yml")
    writeoutput_settings = GenX.get_settings_path(genx_case_path, "output_settings.yml")
    setup = GenX.configure_settings(genx_settings, writeoutput_settings) 
    setup["ParameterScale"] = 0;
    settings_path = GenX.get_settings_path(genx_case_path)
    inputs = GenX.load_inputs(setup, genx_case_path)
    return setup, inputs

end

function load_genx_case(genx_case_path::AbstractString, genx_stage_path::AbstractString)

    genx_settings = GenX.get_settings_path(genx_case_path, "genx_settings.yml")
    writeoutput_settings = GenX.get_settings_path(genx_case_path, "output_settings.yml")
    setup = GenX.configure_settings(genx_settings, writeoutput_settings) 
    setup["ParameterScale"] = 0;
    settings_path = GenX.get_settings_path(genx_case_path)
    inputs = GenX.load_inputs(setup, genx_stage_path)
    return setup, inputs

end

function make_macro_dir(macro_case::AbstractString)
    if !isdir(macro_case)
        mkdir(macro_case)
        mkdir(joinpath(macro_case,"system"))
        mkdir(joinpath(macro_case,"assets"))
        mkdir(joinpath(macro_case,"settings"))
        system_data = Dict("commodities" => Dict("path" => "system/commodities.json"),
                            "locations" => Dict("path" => "locations"),
                            "settings" => Dict("path" => "settings/macro_settings.json"),
                            "assets" => Dict("path" => "assets"),
                            "time_data" => Dict("path" => "system/time_data.json"),
                            "nodes" => Dict("path" => "system/nodes.json")
                            )
        open(joinpath(macro_case,"system_data.json"), "w") do io
            JSON3.pretty(io, system_data)
        end

        open(joinpath(macro_case,"settings/macro_settings.json"), "w") do io
            JSON3.pretty(io, Dict("ConstraintScaling"=>false))
        end
    end
end

function get_stage_number(stage_folder::AbstractString)
    
    m = match(r"\d+$", stage_folder)  # match digits at the end
    if m !== nothing
        num_str = m.match  # this is still a String
    end

    return num_str
end