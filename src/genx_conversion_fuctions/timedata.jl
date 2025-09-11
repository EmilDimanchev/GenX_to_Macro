function make_timedata_json(inputs::Dict, setup::Dict, commodities_vec::Vector{String},genx_case_path::AbstractString, macro_case::AbstractString)

    time_data = Dict("HoursPerSubperiod"=>Dict{AbstractString,Int64}(),
                "HoursPerTimeStep"=>Dict{AbstractString,Int64}(),
                "NumberOfSubperiods"=>inputs["REP_PERIOD"])

    for c in commodities_vec
        time_data["HoursPerSubperiod"][c] = inputs["H"]
        time_data["HoursPerTimeStep"][c] = 1
    end

    if setup["TimeDomainReduction"]==1
        time_data["TotalHoursModeled"] = sum(inputs["Weights"])
        time_data["SubPeriodMap"] = Dict("path"=>"system/Period_map.csv")
    end

    open(joinpath(macro_case,"System/time_data.json"), "w") do io
        JSON3.pretty(io, time_data)
    end
    return time_data
end

function make_timedata_json(inputs::Dict, setup::Dict, commodities_vec::Vector{String},genx_case_path::AbstractString, macro_case::AbstractString, genx_stage_path::AbstractString)

    stage_number = get_stage_number(genx_stage_path)

    time_data = Dict("HoursPerSubperiod"=>Dict{AbstractString,Int64}(),
                "HoursPerTimeStep"=>Dict{AbstractString,Int64}(),
                "NumberOfSubperiods"=>inputs["REP_PERIOD"])

    for c in commodities_vec
        time_data["HoursPerSubperiod"][c] = inputs["H"]
        time_data["HoursPerTimeStep"][c] = 1
    end

    if setup["TimeDomainReduction"]==1
        time_data["TotalHoursModeled"] = sum(inputs["Weights"])
        time_data["SubPeriodMap"] = Dict("path"=>string("system/Period_map",stage_number,".csv"))
    end

    open(joinpath(macro_case,string("System/time_data",stage_number,".json")), "w") do io
        JSON3.pretty(io, time_data)
    end
    return time_data
end