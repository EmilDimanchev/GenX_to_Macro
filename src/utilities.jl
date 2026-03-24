
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

# ~~~
# Multistage version
# ~~~

function make_macro_dir(macro_case::AbstractString, stage_folders)
    if !isdir(macro_case)
        mkdir(macro_case)
        mkdir(joinpath(macro_case,"system"))
        mkdir(joinpath(macro_case,"assets"))
        mkdir(joinpath(macro_case,"settings"))

        all_stages = []
        
        sorted_folders = sort(stage_folders, by = s -> parse(Int, split(s, "p")[end]))

        for stage in sorted_folders

            stage_number = get_stage_number(stage)

            system_data = Dict("commodities" => Dict("path" => "system/commodities.json"),
                                "locations" => Dict("path" => "locations.json"),
                                "settings" => Dict("path" => "settings/macro_settings.json"),
                                "assets" => Dict("path" => string("assets/assets_",stage_number)),
                                "time_data" => Dict("path" => string("system/time_data_",stage_number,".json")),
                                "nodes" => Dict("path" => string("system/nodes_",stage_number,".json"))
                                )

            push!(all_stages, system_data)
            
        end

        all_system_data = d = Dict(
            "case" => all_stages,   
            "settings" => Dict(
                "path" => "settings/case_settings.json"
            )
        )

        open(joinpath(macro_case,"system_data.json"), "w") do io
            JSON3.pretty(io, all_system_data)
        end

        open(joinpath(macro_case,"settings/macro_settings.json"), "w") do io
            JSON3.pretty(io, Dict("ConstraintScaling"=>false))
        end

        open(joinpath(macro_case,"settings/case_settings.json"), "w") do io
            JSON3.pretty(io, Dict(["PeriodLengths"=>ones(length(stage_folders)),"DiscountRate"=> 0.045,
            "SolutionAlgorithm"=> "Monolithic"]))
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

function get_multistage_params(resource::AbstractString, genx_stage_path::AbstractString)

    df_inv_input = CSV.read(string(genx_stage_path,"/resources/Resource_multistage_data.csv"), DataFrame)
    df_inv = select(df_inv_input, [:Resource, :WACC, :Capital_Recovery_Period, :Lifetime])
    
    wacc_vec = filter(row -> row.Resource == resource, df_inv).WACC
    crp_vec = filter(row -> row.Resource == resource, df_inv).Capital_Recovery_Period
    lifetime_vec = filter(row -> row.Resource == resource, df_inv).Lifetime
    min_ret_cap_vec = filter(row -> row.Resource == resource, df_inv_input).Min_Retired_Cap_MW
    
    wacc = isempty(wacc_vec) ? missing : wacc_vec[1]
    crp = isempty(crp_vec) ? missing : crp_vec[1]
    lifetime = isempty(lifetime_vec) ? missing : lifetime_vec[1]
    min_ret_cap = isempty(min_ret_cap_vec) ? missing : min_ret_cap_vec[1]

    return wacc, crp, lifetime, min_ret_cap

end

function get_speed_limits(resource::AbstractString, genx_stage_path::AbstractString)

    folder = dirname(genx_stage_path)

    df_speed_limits = CSV.read(string(folder,"/speed_limits.csv"), DataFrame)

    # Filter the DataFrame for the specific resource
    filtered_row = filter(row -> row[1] == resource, df_speed_limits)
    
    if nrow(filtered_row) == 0
        @warn "Resource $resource not found in speed_limits.csv"
        return Dict()  # Return an empty dictionary
    end

    # Col number of main data
    col = findfirst(==("init_cumul_capacity_1"), names(df_speed_limits)) - 1
    col_max = findfirst(==("max_cumul_capacity_1"), names(df_speed_limits)) - 1

    # Convert the row to a dictionary, excluding the first column
    speed_limits_dict = Dict(col => filtered_row[1, col] for col in names(df_speed_limits)[2:col])

    # Add external capacity of the specific stage
    stage_number = get_stage_number(genx_stage_path)

    col = string("init_cumul_capacity_",stage_number)
    col_max = string("max_cumul_capacity_",stage_number)
    
    external_capacity_of_stage = Dict("init_cumul_capacity" => filtered_row[1, col])
    max_capacity_of_stage = Dict("max_cumul_capacity" => filtered_row[1, col_max])

    final_dict = merge(speed_limits_dict, external_capacity_of_stage, max_capacity_of_stage)
    
    return final_dict

end

function get_capacity_reserve_margin_params(resource::AbstractString, genx_stage_path::AbstractString)
    """
    Get capacity reserve margin derating factor and ID for a resource.
    
    Maps the first two characters of the resource name (state code) to a zone number,
    then determines which CapRes constraint the zone participates in from Capacity_reserve_margin.csv,
    and retrieves the derating factor for that constraint from Resource_capacity_reserve_margin.csv.
    
    Returns a Dict with:
    - "capacity_reserve_margin_derate_factor": the derating factor for the resource's CapRes constraint
    - "capacity_reserve_margin_id": the state code
    
    Returns an empty Dict if the resource is not found or if there's no matching derating factor.
    """
    
    # Extract state code (first 2 characters) for region mapping
    if length(resource) < 2
        @warn "Resource name '$resource' is too short to extract state code"
        return Dict()
    end
    
    state_code = uppercase(resource[1:2])
    
    # Validate state code is in our mapping
    STATE_TO_ZONE = Dict(
        "WA" => 10,
        "CA" => 2,
        "NV" => 7,
        "ID" => 4,
        "MT" => 5,
        "WY" => 11,
        "UT" => 9,
        "AZ" => 1,
        "OR" => 8,
        "CO" => 3,
        "NM" => 6
    )
    if !haskey(STATE_TO_ZONE, state_code)
        @warn "State code '$state_code' from resource '$resource' not found in mapping"
        return Dict()
    end
    
    # Read Resource_capacity_reserve_margin.csv and get the derating factor for this resource.
    # The file has two columns: "derating_factor_1" and "Resource".
    crm_file_path = string(genx_stage_path, "/resources/policy_assignments/Resource_capacity_reserve_margin.csv")
    
    if !isfile(crm_file_path)
        @warn "Resource_capacity_reserve_margin.csv file not found: $crm_file_path"
        return Dict()
    end
    
    df_crm = CSV.read(crm_file_path, DataFrame)
    
    # Filter for the specific resource
    filtered_row = filter(row -> row.Resource == resource, df_crm)
    
    if nrow(filtered_row) == 0
        @warn "Resource $resource not found in Resource_capacity_reserve_margin.csv"
        return Dict()
    end
    
    if !hasproperty(df_crm, :derating_factor_1)
        @warn "Column 'derating_factor_1' not found in Resource_capacity_reserve_margin.csv"
        return Dict()
    end
    
    derating_factor = filtered_row[1, :derating_factor_1]

    # Map state code to region id. Regions are named so that they contain
    # the two-letter state codes for the states they include. We iterate
    # through the region names and pick the first region that contains the
    # state code as a substring. If no region contains the state code we
    # fall back to the state code itself and emit a warning.
    regions = crm_regions
    # regions = ["OR_WA", "ID_UT_NV_MT", "CA", "AZ_NM", "WY_CO"]
    region_id = get_region_id(regions, state_code)

    if region_id === nothing
        @warn "State code '$state_code' not found in predefined regions; using state code as capacity_reserve_margin_id"
        region_id = state_code
    end

    # Return the parameters as a dictionary
    return Dict(
        "capacity_reserve_margin_derate_factor" => derating_factor,
        "capacity_reserve_margin_id" => region_id
    )
end

function get_state_code_from_zone(zone_number::Int)
    """
    Get the two-letter state code corresponding to a zone number.
    
    Returns the state code as a string, or an empty string if zone not found.
    """
    
    ZONE_TO_STATE = Dict(
        1 => "AZ",
        2 => "CA",
        3 => "CO",
        4 => "ID",
        5 => "MT",
        6 => "NM",
        7 => "NV",
        8 => "OR",
        9 => "UT",
        10 => "WA",
        11 => "WY"
    )
    
    return get(ZONE_TO_STATE, zone_number, "")
end

function get_region_id(regions::Vector{String}, state_code::AbstractString)
    
    region_id = nothing
    for r in regions
        if occursin(state_code, r)
            region_id = r
            break
        end
    end
    return region_id
end

function get_capacity_reserve_margin_value(zone_number::Int, genx_stage_path::AbstractString)
    """
    Get the capacity reserve margin value for a given zone from the Capacity_reserve_margin.csv file.
    
    Reads the CSV file and finds the non-zero value in the CapRes columns for the specified zone.
    Returns the non-zero value, or 0.0 if no non-zero value is found or if there's an error.
    
    Parameters:
    - zone_number: The zone number (1-11)
    - genx_stage_path: Path to the stage input folder
    
    Returns:
    - Float64: The capacity reserve margin value
    """
    
    # Construct the path to the Capacity_reserve_margin.csv file
    crm_file_path = string(genx_stage_path, "/policies/Capacity_reserve_margin.csv")
    
    if !isfile(crm_file_path)
        @warn "Capacity reserve margin file not found: $crm_file_path"
        return 0.0
    end
    
    # Read the CSV file
    df_crm = CSV.read(crm_file_path, DataFrame)
    
    # Find the row for this zone (format is "z1", "z2", etc.)
    zone_str = string("z", zone_number)
    filtered_row = filter(row -> row.Network_zones == zone_str, df_crm)
    
    if nrow(filtered_row) == 0
        @warn "Zone $zone_str not found in Capacity_reserve_margin.csv"
        return 0.0
    end
    
    # Get all CapRes columns
    capres_cols = filter(name -> startswith(string(name), "CapRes_"), names(df_crm))
    
    if isempty(capres_cols)
        @warn "No CapRes columns found in Capacity_reserve_margin.csv"
        return 0.0
    end
    
    # Find the first non-zero value
    for col in capres_cols
        value = filtered_row[1, col]
        if value != 0.0
            return value
        end
    end
    
    # If all values are zero, return 0.0
    return 0.0
end

function get_interconnection_cost_nonvre(resource::AbstractString, spur_miles::Int64)
    
    # Costs from power genome
    capex_mw_mile = Dict(
        "WA" => 1797.75,
        "OR" => 1798.0,
        "CA" => 1979.25,
        "NV" => 1806.5,
        "ID" => 1774.333333,
        "MT" => 1687.75,
        "WY" => 1703.5,
        "UT" => 1768.5,
        "AZ" => 1753.0,
        "NM" => 1722.0,
        "CO" => 1705.0
    )

    state_code = uppercase(resource[1:2])

    capex_cost = capex_mw_mile[state_code] * spur_miles

    wacc = 0.044
    CRP = 60
    annualized = capex_cost * (wacc / (1 - (1 + wacc)^(-CRP))) # Assuming 20 year CRP and 4.5% WACC

    return annualized
end

function get_interconnect_annuity(resource::AbstractString, genx_case_path::AbstractString)

    vre_file_path = joinpath(genx_case_path, "resources", "Vre.csv")

    if !isfile(vre_file_path)
        @warn "Vre.csv not found at: $vre_file_path"
        return missing
    end

    df_vre = CSV.read(vre_file_path, DataFrame)

    filtered_row = filter(row -> row.Resource == resource, df_vre)

    if nrow(filtered_row) == 0
        @warn "Resource '$resource' not found in Vre.csv"
        return missing
    end

    return filtered_row[1, :interconnect_annuity]
end
