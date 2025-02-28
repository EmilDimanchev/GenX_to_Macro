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
        time_data["PeriodMap"] = Dict("path"=>"../"*setup["TimeDomainReductionFolder"]*"/Period_map.csv")
    end

    open(joinpath(macro_case,"System/time_data.json"), "w") do io
        JSON3.pretty(io, time_data)
    end
    return time_data
end