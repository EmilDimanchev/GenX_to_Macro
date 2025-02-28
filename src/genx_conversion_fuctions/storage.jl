function make_storage_json(inputs::Dict, setup::Dict, macro_case::AbstractString)
    STOR_ALL = inputs["STOR_ALL"]
    storage = Dict("elec_stor"=> Dict(
                                        "type"=>"Battery",
                                        "global_data"=>Dict(
                                            "storage" => Dict(
                                                                "commodity" => "Electricity",
                                                            ),
                                            "edges" => Dict(
                                                        "discharge_edge" => Dict(
                                                                            "type" => "Electricity",
                                                                            "unidirectional" => true,
                                                                            ),
                                                        "charge_edge" => Dict(
                                                                            "type" => "Electricity",
                                                                            "unidirectional" => true,
                                                                            )
                                            ),
                                        ),
                                        "instance_data"=>Vector{Dict{AbstractString,Any}}()
                                        )
    )

    gen(y) = inputs["RESOURCES"][y];
    for y in STOR_ALL

        discharge_constraints_dict = Dict("CapacityConstraint" => true,"StorageDischargeLimitConstraint" => true)
        storage_constraints_dict = Dict("BalanceConstraint" => true, "StorageCapacityConstraint" => true)
        charge_constraints_dict  = Dict();

        if setup["LDSAdditionalConstraints"]== 1 && gen(y).lds==1
            storage_constraints_dict["LongDurationStorageImplicitMinMaxConstraint"] = true
        end

        if get(gen(y),:min_cap_mw,0)>0
            discharge_constraints_dict["MinCapacityConstraint"] = true
        end

        if get(gen(y),:max_cap_mw,0)>0
            discharge_constraints_dict["MaxCapacityConstraint"] = true
        end

        if get(gen(y),:min_cap_mwh,0)>0
            storage_constraints_dict["MinCapacityConstraint"] = true
        end

        if get(gen(y),:max_cap_mwh,0)>0
            storage_constraints_dict["MaxCapacityConstraint"] = true
        end

        if get(gen(y), :min_duration, 0) > 0
            storage_constraints_dict["StorageMinDurationConstraint"] = true
        end

        if get(gen(y), :max_duration, 0) >= 0
            storage_constraints_dict["StorageMaxDurationConstraint"] = true
        end

        if y in inputs["STOR_ASYMMETRIC"]
            charge_constraints_dict["CapacityConstraint"] = true
            if get(gen(y),:min_charge_capacity_mw,0)>0
                charge_constraints_dict["MinCapacityConstraint"] = true
            end
    
            if get(gen(y),:max_charge_capacity_mw,0)>0
                charge_constraints_dict["MaxCapacityConstraint"] = true
            end
        else
            storage_constraints_dict["StorageSymmetricCapacityConstraint"] = true
        end

        
        push!(storage["elec_stor"]["instance_data"],
            Dict(
                "id" =>  gen(y).resource,
                "storage"=> Dict(
                    "can_expand" => in(y,inputs["NEW_CAP_ENERGY"]),
                    "capacity_size" => 1.0,
                    "can_retire" => in(y,inputs["RET_CAP_ENERGY"]),
                    "charge_discharge_ratio" => 1.0,
                    "constraints" => storage_constraints_dict,
                    "existing_capacity" => gen(y).existing_cap_mwh,
                    "fixed_om_cost" => gen(y).fixed_om_cost_per_mwhyr,
                    "investment_cost" => gen(y).inv_cost_per_mwhyr,
                    "long_duration" => gen(y).lds==1,
                    "loss_fraction" => gen(y).self_disch,
                    "max_capacity" => gen(y).max_cap_mwh,
                    "max_duration" => gen(y).max_duration,
                    "max_storage_level" => 1.0,
                    "min_capacity" => gen(y).min_cap_mwh,
                    "min_duration" => gen(y).min_duration,
                    "min_storage_level" => 0.0,
                ),
                "edges"=> Dict(
                    "discharge_edge" => Dict(
                        "end_vertex" => "elec_" * gen(y).region,
                        "can_expand" => in(y,inputs["NEW_CAP"]),
                        "can_retire" => in(y,inputs["RET_CAP"]),
                        "capacity_size" => 1.0,
                        "constraints" => discharge_constraints_dict,
                        "efficiency" => gen(y).eff_down,
                        "existing_capacity" => gen(y).existing_cap_mw,
                        "fixed_om_cost" => gen(y).fixed_om_cost_per_mwyr,
                        "has_capacity" => true,
                        "investment_cost" => gen(y).inv_cost_per_mwyr,
                        "max_capacity" => gen(y).max_cap_mw,
                        "min_capacity" => gen(y).min_cap_mw,
                        "variable_om_cost" => gen(y).var_om_cost_per_mwh
                    ),
                    "charge_edge" => Dict(
                        "start_vertex" => "elec_" * gen(y).region,
                        "can_expand" => in(y,inputs["NEW_CAP_CHARGE"]),
                        "can_retire" => in(y,inputs["RET_CAP_CHARGE"]),
                        "capacity_size" => 1.0,
                        "constraints" => charge_constraints_dict,
                        "efficiency" => gen(y).eff_down,
                        "existing_capacity" => get(gen(y), :existing_charge_cap_mw, 0.0),
                        "fixed_om_cost" => get(gen(y), :fixed_om_cost_charge_per_mwyr,0.0),
                        "has_capacity" => in(y,inputs["STOR_ASYMMETRIC"]),
                        "investment_cost" => get(gen(y), :inv_cost_charge_per_mwyr,0.0),
                        "max_capacity" => get(gen(y), :max_charge_cap_mw,0.0),
                        "min_capacity" => get(gen(y), :min_charge_cap_mw,0.0),
                        "variable_om_cost" => get(gen(y), :var_om_cost_per_mwh_in,0.0)
                    ),
                )
            )
        )

    end

    open(joinpath(macro_case,"assets/storage.json"), "w") do io
        JSON3.pretty(io, storage)
    end
end