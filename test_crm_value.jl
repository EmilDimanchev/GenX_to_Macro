# Test script for capacity reserve margin value retrieval
using GenX_to_Macro
using CSV
using DataFrames

println("="^60)
println("Testing get_capacity_reserve_margin_value function")
println("="^60)

# Test path
genx_stage_path = "./genx_cases/wecc_11z_30p/inputs/inputs_p1"

println("\nReading Capacity_reserve_margin.csv:")
crm_file = joinpath(genx_stage_path, "policies/Capacity_reserve_margin.csv")
df = CSV.read(crm_file, DataFrame)
println(df)

println("\n" * "="^60)
println("Testing zone to capacity reserve margin value:")
println("="^60)

for z in 1:11
    value = get_capacity_reserve_margin_value(z, genx_stage_path)
    state_code = get_state_code_from_zone(z)
    println("  Zone $z ($state_code): $value")
end

println("\n" * "="^60)
println("Testing edge cases:")
println("="^60)

# Test invalid zone
println("\nTesting invalid zone (zone 99):")
result = get_capacity_reserve_margin_value(99, genx_stage_path)
println("  Result: $result (should be 0.0)")

# Test invalid path
println("\nTesting invalid path:")
result = get_capacity_reserve_margin_value(1, "./nonexistent/path")
println("  Result: $result (should be 0.0 with warning)")

println("\n" * "="^60)
println("Testing complete!")
println("="^60)
