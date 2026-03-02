# Test script for capacity reserve margin implementation
using GenX_to_Macro
using CSV
using DataFrames

# Test the utility function
println("="^60)
println("Testing get_capacity_reserve_margin_params function")
println("="^60)

# Test path
genx_stage_path = "./genx_cases/wecc_11z_30p/inputs/inputs_p1"

# Test resources from different states
test_resources = [
    "AZ_solar_photovoltaic_1",      # Arizona -> Zone 1
    "CA_natural_gas_fired_combined_cycle_1",  # California -> Zone 2
    "CO_onshore_wind_turbine_1",    # Colorado -> Zone 3
    "ID_conventional_hydroelectric_1", # Idaho -> Zone 4
    "WA_onshore_wind_turbine_1"     # Washington -> Zone 10
]

println("\nTesting various resources:")
for resource in test_resources
    println("\n  Testing resource: $resource")
    result = get_capacity_reserve_margin_params(resource, genx_stage_path)
    
    if isempty(result)
        println("    ❌ No result returned")
    else
        println("    ✓ Derating factor: $(result["capacity_reserve_margin_derate_factor"])")
        println("    ✓ Zone ID: $(result["capacity_reserve_margin_id"])")
    end
end

# Test edge cases
println("\n" * "="^60)
println("Testing edge cases:")
println("="^60)

# Test with non-existent resource
println("\n  Testing non-existent resource:")
result = get_capacity_reserve_margin_params("XX_nonexistent_resource", genx_stage_path)
if isempty(result)
    println("    ✓ Correctly returns empty Dict for non-existent resource")
else
    println("    ❌ Should return empty Dict")
end

# Test with short resource name
println("\n  Testing short resource name:")
result = get_capacity_reserve_margin_params("X", genx_stage_path)
if isempty(result)
    println("    ✓ Correctly returns empty Dict for short resource name")
else
    println("    ❌ Should return empty Dict")
end

# Test with invalid state code
println("\n  Testing invalid state code:")
result = get_capacity_reserve_margin_params("ZZ_invalid_state", genx_stage_path)
if isempty(result)
    println("    ✓ Correctly returns empty Dict for invalid state")
else
    println("    ❌ Should return empty Dict")
end

println("\n" * "="^60)
println("Testing complete!")
println("="^60)

# Show a sample of what the CSV looks like
println("\nSample of Resource_capacity_reserve_margin.csv:")
crm_file = joinpath(genx_stage_path, "resources/policy_assignments/Resource_capacity_reserve_margin.csv")
df = CSV.read(crm_file, DataFrame)
println("  Columns: ", names(df))
println("  First 5 rows:")
println(first(df, 5))
