# Test script for nodes capacity_reserve_margin_id implementation
using GenX_to_Macro

println("="^60)
println("Testing get_state_code_from_zone function")
println("="^60)

# Test all zone mappings
test_zones = [
    (1, "AZ"),
    (2, "CA"),
    (3, "CO"),
    (4, "ID"),
    (5, "MT"),
    (6, "NM"),
    (7, "NV"),
    (8, "OR"),
    (9, "UT"),
    (10, "WA"),
    (11, "WY")
]

println("\nTesting zone to state code mappings:")
all_passed = true
for (zone, expected_state) in test_zones
    result = get_state_code_from_zone(zone)
    if result == expected_state
        println("  ✓ Zone $zone → $result")
    else
        println("  ❌ Zone $zone → $result (expected $expected_state)")
        all_passed = false
    end
end

# Test invalid zone
println("\nTesting invalid zone:")
result = get_state_code_from_zone(99)
if result == ""
    println("  ✓ Zone 99 → \"\" (empty string as expected)")
else
    println("  ❌ Zone 99 → \"$result\" (expected empty string)")
    all_passed = false
end

println("\n" * "="^60)
if all_passed
    println("✅ All tests passed!")
else
    println("❌ Some tests failed")
end
println("="^60)
