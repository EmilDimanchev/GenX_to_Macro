# Debug test for capacity reserve margin params - FIXED VERSION
using GenX_to_Macro
using CSV
using DataFrames

genx_stage_path = "./genx_cases/wecc_20p_11z/inputs/inputs_p1"

println("="^70)
println("First, let's see the Capacity_reserve_margin.csv mapping:")
println("="^70)
cap_margin_file = joinpath(genx_stage_path, "policies/Capacity_reserve_margin.csv")
df_cap = CSV.read(cap_margin_file, DataFrame)
println(df_cap)

println("\n" * "="^70)
println("Testing get_capacity_reserve_margin_params with the fix:")
println("="^70)

test_resources = [
    "AZ_conventional_hydroelectric_1",   # Zone 1 -> CapRes_3
    "CA_conventional_hydroelectric_1",  # Zone 2 -> CapRes_2
    "CO_conventional_hydroelectric_1",  # Zone 3 -> CapRes_1
    "ID_conventional_hydroelectric_1",  # Zone 4 -> CapRes_1
    "MT_conventional_hydroelectric_1",  # Zone 5 -> CapRes_1
    "WA_conventional_hydroelectric_1"   # Zone 10 -> CapRes_1
]

for resource in test_resources
    println("\nResource: $resource")
    result = get_capacity_reserve_margin_params(resource, genx_stage_path)
    if !isempty(result)
        println("  ✓ Derating factor: $(result["capacity_reserve_margin_derate_factor"])")
        println("  ✓ State code: $(result["capacity_reserve_margin_id"])")
    else
        println("  ❌ No result returned")
    end
end

println("\n" * "="^70)
println("Checking the CSV values for ID hydro:")
println("="^70)
crm_file = joinpath(genx_stage_path, "resources/policy_assignments/Resource_capacity_reserve_margin.csv")
df_crm = CSV.read(crm_file, DataFrame)
id_row = filter(row -> row.Resource == "ID_conventional_hydroelectric_1", df_crm)
println(id_row)
