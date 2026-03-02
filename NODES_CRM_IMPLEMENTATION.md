# Nodes Capacity Reserve Margin Implementation

## Summary

Extended the nodes.jl implementation to add capacity reserve margin information to each electricity node instance.

## Changes Made

### 1. New Utility Function (`utilities.jl`)

Added `get_capacity_reserve_margin_value(zone_number::Int, genx_stage_path::AbstractString)`:
- Reads `Capacity_reserve_margin.csv` from the policies folder of each stage
- File location: `{genx_stage_path}/policies/Capacity_reserve_margin.csv`
- Returns the first non-zero value from the CapRes columns for the specified zone
- Returns 0.0 if no non-zero value is found or if there's an error
- Handles missing files and zones gracefully with warnings

### 2. Updated Exports (`GenX_to_Macro.jl`)

Exported the new function:
- `get_capacity_reserve_margin_value`

### 3. Updated Nodes Function (`nodes.jl`)

Modified the multistage version of `make_nodes_json_demands_and_fuels`:
- Added two new fields to each electricity node instance:
  - `"capacity_reserve_margin_id"`: State code (e.g., "AZ", "CA")
  - `"capacity_reserve_margin"`: Reserve margin value from CSV

## Input File Structure

The function reads from:
```
{genx_stage_path}/policies/Capacity_reserve_margin.csv
```

Example file structure:
```csv
Network_zones,CapRes_1,CapRes_2,CapRes_3
z1,0.0,0.0,0.102
z2,0.0,0.169,0.0
z3,0.161,0.0,0.0
...
```

## Output Structure

Each electricity node now includes:
```json
{
  "id": "elec_AZ",
  "capacity_reserve_margin_id": "AZ",
  "capacity_reserve_margin": 0.102,
  "demand": {
    "timeseries": {
      "path": "system/demand_1.csv",
      "header": "elec_demand_AZ"
    }
  }
}
```

## Zone to State Code Mapping

| Zone | State |
|------|-------|
| 1    | AZ    |
| 2    | CA    |
| 3    | CO    |
| 4    | ID    |
| 5    | MT    |
| 6    | NM    |
| 7    | NV    |
| 8    | OR    |
| 9    | UT    |
| 10   | WA    |
| 11   | WY    |

## Test Results

From `test_crm_value.jl`:

| Zone | State | CRM Value |
|------|-------|-----------|
| 1    | AZ    | 0.102     |
| 2    | CA    | 0.169     |
| 3    | CO    | 0.161     |
| 4    | ID    | 0.161     |
| 5    | MT    | 0.161     |
| 6    | NM    | 0.102     |
| 7    | NV    | 0.161     |
| 8    | OR    | 0.161     |
| 9    | UT    | 0.161     |
| 10   | WA    | 0.161     |
| 11   | WY    | 0.161     |

## Error Handling

The implementation handles several edge cases gracefully:

1. **Missing CSV file**: Returns 0.0 with warning
2. **Zone not found**: Returns 0.0 with warning
3. **No CapRes columns**: Returns 0.0 with warning
4. **All zeros for zone**: Returns 0.0 (no warning)
5. **Invalid zone number**: Returns 0.0 with warning

## Usage

The implementation is automatically applied when running multistage conversions:

```julia
nodes, demand, fuel_prices = make_nodes_json_demands_and_fuels(inputs, macro_case_path, genx_stage_path)
```

No changes are needed to existing conversion scripts. The new fields will automatically appear in the generated `nodes_{stage_number}.json` files.

## Testing

A test script is provided at `/test_crm_value.jl` that:
- Tests all 11 zones
- Verifies correct value retrieval from CSV
- Tests edge cases (invalid zones, missing files)
- Shows the CSV data structure

Run the test with:
```bash
julia --project=. test_crm_value.jl
```

## Notes

- Only the **multistage version** of `make_nodes_json_demands_and_fuels` was updated
- The function finds the **first non-zero** value in the CapRes columns
- If multiple CapRes columns have non-zero values, only the first is used
- The implementation uses the same zone-to-state mapping as the resource-level CRM implementation
