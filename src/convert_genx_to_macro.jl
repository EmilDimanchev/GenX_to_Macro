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
    end
end

function make_commodities_json(commodities_vec::Vector{String}, macro_case::AbstractString)
    commodities = Dict("commodities" => commodities_vec)
    open(joinpath(macro_case,"System/commodities.json"), "w") do io
        JSON3.pretty(io, commodities)
    end
    return commodities
end

function make_timedata_json(inputs::Dict, setup::Dict, commodities_vec::Vector{String},genx_case_path::AbstractString, macro_case::AbstractString)

    time_data = Dict("HoursPerSubperiod"=>Dict{AbstractString,Int64}(),
                "HoursPerTimeStep"=>Dict{AbstractString,Int64}(),
                "PeriodLength"=>inputs["T"])

    for c in commodities_vec
        time_data["HoursPerSubperiod"][c] = inputs["H"]
        time_data["HoursPerTimeStep"][c] = 1
    end

    if setup["TimeDomainReduction"]==1
        time_data["TotalHoursModeled"] = sum(inputs["Weights"])
        time_data["PeriodMap"] = Dict("path"=>joinpath(genx_case_path,setup["TimeDomainReductionFolder"]))
    end

    open(joinpath(macro_case,"System/time_data.json"), "w") do io
        JSON3.pretty(io, time_data)
    end
    return time_data
end

function make_nodes_json_demands_and_fuels(inputs::Dict, macro_case::AbstractString)
    gen = inputs["RESOURCES"];
    nodes = Dict("nodes"=> [ Dict(
        "type" => "Electricity",
        "global_data"=> Dict("time_interval" => "Electricity",
                            "constraints" => Dict("BalanceConstraint" => true,
                                                    "MaxNonServedDemandConstraint" => true,
                                                    "MaxNonServedDemandPerSegmentConstraint" => true),
                            "max_nsd" => inputs["pMax_D_Curtail"],
                            "price_nsd" => inputs["pC_D_Curtail"],
                            ),
        "instance_data" => Vector{Dict{AbstractString,Any}}()
        ),
    ])

    demand_headers = Vector{AbstractString}();

    for z in 1:inputs["Z"]
        z_name = gen[findfirst(g.zone==z for g in gen)].region;
        node_instance = Dict(
            "id" => "elec_"*z_name,
            "demand" => Dict("timeseries" => Dict("path" => "system/demand.csv",
                                                "header" => "elec_demand_"*z_name))
        )
        push!(nodes["nodes"][1]["instance_data"], node_instance)
        push!(demand_headers,"elec_demand_"*z_name)
    end
    demand = DataFrame(inputs["pD"], demand_headers);
    CSV.write(joinpath(macro_case,"System/demand.csv"), demand)

    fuel_names = inputs["fuels"];

    #### Here we assume NG is the only fuel but can be extended to other fuels adding more nodes to vector node["nodes"]
    push!(nodes["nodes"], Dict(
        "type" => "NaturalGas",
        "global_data"=> Dict("time_interval" => "NaturalGas"),
        "instance_data" => Vector{Dict{AbstractString,Any}}()
        )
    )
    for f in fuel_names
        node_instance = Dict(
            "id" => f,
            "price" => Dict("timeseries" => Dict("path" => "system/fuel_prices.csv",
                                                "header" => f))
        )
        push!(nodes["nodes"][2]["instance_data"], node_instance)
    end
    fuel_prices = DataFrame([inputs["fuel_costs"][f] for f in fuel_names], fuel_names);
    CSV.write(joinpath(macro_case,"System/fuel_prices.csv"), fuel_prices)

    push!(nodes["nodes"], Dict(
        "type" => "CO2",
        "global_data"=> Dict("time_interval" => "CO2"),
        "instance_data" => [
            Dict("id" => "co2_sink_$cap",
                "constraints" => Dict("CO2CapConstraint" => true),
                "rhs_policy" => Dict("CO2CapConstraint" => sum(inputs["dfMaxCO2"][z, cap]
                for z in findall(x -> x == 1, inputs["dfCO2CapZones"][:, cap])))
            )
            for cap in 1:inputs["NCO2Cap"]
        ]
        )
    )

    open(joinpath(macro_case,"System/nodes.json"), "w") do io
        JSON3.pretty(io, nodes)
    end
    return nodes, demand, fuel_prices
end
