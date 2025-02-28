function make_commodities_json(commodities_vec::Vector{String}, macro_case::AbstractString)
    commodities = Dict("commodities" => commodities_vec)
    open(joinpath(macro_case,"System/commodities.json"), "w") do io
        JSON3.pretty(io, commodities)
    end
    return commodities
end