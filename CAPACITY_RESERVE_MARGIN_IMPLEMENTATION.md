# Capacity Reserve Margin Implementation

## Overview

This implementation adds support for capacity reserve margin (CRM) parameters to the GenX to Macro conversion functions. The feature adds two fields to each resource edge in the generated JSON files:
- `capacity_reserve_margin_derate_factor`: The derating factor for the resource's zone
- `capacity_reserve_margin_id`: The zone number (integer)

## Files Modified

### 1. `/src/utilities.jl`
Added new utility function:
- `get_capacity_reserve_margin_params(resource::AbstractString, genx_stage_path::AbstractString)`
  - Maps resource state codes to zone numbers
  - Reads `Resource_capacity_reserve_margin.csv` from the policy_assignments folder
  - Returns a Dict with the derating factor and zone ID
  - Handles errors gracefully with warnings and empty Dict returns

### 2. `/src/GenX_to_Macro.jl`
- Exported the new `get_capacity_reserve_margin_params` function
- Also exported `get_speed_limits` for consistency

### 3. `/src/genx_conversion_fuctions/vre.jl`
Updated multistage function `make_vre_json`:
- Added call to `get_capacity_reserve_margin_params`
- Merged CRM parameters into the edge Dict

### 4. `/src/genx_conversion_fuctions/thermal.jl`
Updated two multistage functions:
- `make_thermal_json`: Added CRM parameters to elec_edge
- `make_thermal_ccs_json`: Added CRM parameters to elec_edge

### 5. `/src/genx_conversion_fuctions/mustrun.jl`
Updated multistage function `make_mustrun_json`:
- Added CRM parameters to elec_edge

### 6. `/src/genx_conversion_fuctions/hydro.jl`
Updated multistage function `make_hydro_json`:
- Added CRM parameters to discharge_edge

## State to Zone Mapping

The following mapping is used to convert state codes (first 2 characters of resource names) to zone numbers:

| State | Zone |
|-------|------|
| WA    | 10   |
| CA    | 2    |
| NV    | 7    |
| ID    | 4    |
| MT    | 5    |
| WY    | 11   |
| UT    | 9    |
| AZ    | 1    |
| OR    | 8    |
| CO    | 3    |
| NM    | 6    |

## Input File Structure

The function reads from:
```
{genx_stage_path}/resources/policy_assignments/Resource_capacity_reserve_margin.csv
```

Expected CSV columns:
- `Resource`: Resource name (must match the resource ID)
- `Derating_factor_1` through `Derating_factor_10`: Derating factors for each zone

Example:
```csv
Resource,Derating_factor_1,Derating_factor_2,Derating_factor_3,...
AZ_solar_photovoltaic_1,0.8,0.9,0.9,...
CA_natural_gas_fired_combined_cycle_1,0.9,0.9,0.9,...
```

## Output Structure

The function adds these fields to each resource edge:
```json
{
  "capacity_reserve_margin_derate_factor": 0.8,
  "capacity_reserve_margin_id": 1
}
```

## Error Handling

The implementation handles several edge cases gracefully:

1. **Resource not found in CSV**: Returns empty Dict with warning
2. **Invalid state code**: Returns empty Dict with warning
3. **Short resource name**: Returns empty Dict with warning
4. **Missing CSV file**: Returns empty Dict with warning
5. **Missing derating factor column**: Returns empty Dict with warning

All warnings are logged using Julia's `@warn` macro, allowing the conversion to continue even if some resources lack CRM data.

## Testing

A test script is provided at `/test_crm_implementation.jl` that:
- Tests various resources from different states
- Verifies correct zone mapping
- Tests edge cases
- Shows sample CSV data

Run the test with:
```bash
julia --project=. test_crm_implementation.jl
```

## Usage

The implementation is automatically applied when running multistage conversions. No changes are needed to existing conversion scripts.

Example from `Multistage_convert.jl`:
```julia
thermal = make_thermal_json(inputs, macro_case_path, genx_stage_path)
vre = make_vre_json(inputs, macro_case_path, genx_stage_path)
mustrun = make_mustrun_json(inputs, macro_case_path, genx_stage_path)
hydro = make_hydro_json(inputs, setup, macro_case_path, genx_stage_path)
```

## Notes

- Only **multistage versions** of the conversion functions are modified
- Single-stage versions remain unchanged
- The CRM parameters are merged alongside speed_limits parameters
- Empty Dicts are merged without adding any fields to the output
- The implementation follows the same pattern as the existing `get_speed_limits` function
