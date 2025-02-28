function make_vre_json(inputs::Dict, macro_case::AbstractString)
    VRE = inputs["VRE"];
    
    vre = Dict("VRE"=> Dict(
                            "type"=>"VRE",
                            "global_data"=>Dict(
                                "transforms" => Dict(
                                                    "timedata" => "Electricity",
                                                    "constraints" => Dict("BalanceConstraint" => true)
                                                ),
                                "edges" => Dict(
                                            "edge" => Dict(
                                                "type" => "Electricity",
                                                "unidirectional" => true,
                                                "has_capacity" => true,
                                                ),
                                            ),
                            ),
                            "instance_data"=>Vector{Dict{AbstractString,Any}}()
                            )
    )

    gen(y) = inputs["RESOURCES"][y];
    vre_availability = DataFrame();
    for y in VRE

        pmax = inputs["pP_Max"][y,:];

        if length(unique(pmax))==1
            gen_availability = unique(pmax)
        else
            gen_availability = Dict("timeseries" => Dict(
                                                        "path" => "system/vre_availability.csv",
                                                        "header" => gen(y).resource))

            vre_availability[!,Symbol(gen(y).resource)] = pmax;
        end

        
        constraints_dict = Dict("CapacityConstraint" => true)

        if get(gen(y),:min_capacity_mw,0)>0
            constraints_dict["MinCapacityConstraint"] = true
        end

        if get(gen(y),:max_capacity_mw,0)>0
            constraints_dict["MaxCapacityConstraint"] = true
        end

        push!(vre["VRE"]["instance_data"],
            Dict(
                "id" =>  gen(y).resource,
                "edges" => Dict(
                    "elec_edge" => Dict(
                        "end_vertex" => "elec_" * gen(y).region,
                        "type" => "Electricity",
                        "constraints" => constraints_dict,
                        "availability" => gen_availability,
                        "can_retire" => in(y,inputs["RET_CAP"]),
                        "can_expand" => in(y,inputs["NEW_CAP"]),
                        "capacity_size" => 1.0,
                        "existing_capacity" => gen(y).existing_cap_mw,
                        "fixed_om_cost" => gen(y).fixed_om_cost_per_mwyr,
                        "investment_cost" => gen(y).inv_cost_per_mwyr,
                        "max_capacity" => gen(y).max_cap_mw,
                        "min_capacity" => gen(y).min_cap_mw,
                        "variable_om_cost" => gen(y).var_om_cost_per_mwh,
                    )
                )
            )
        )
    end

    open(joinpath(macro_case,"assets/vre.json"), "w") do io
        JSON3.pretty(io, vre)
    end

    if !isempty(vre_availability)
        CSV.write(joinpath(macro_case,"system/vre_availability.csv"), vre_availability)
    end

    return vre

end