-- dredwork Chronology — Calendar Definitions
-- The source of truth for temporal structures.

local Calendar = {
    days_per_month = 30,
    months_per_year = 12,
    years_per_generation = 25,
    
    month_names = {
        "First Dawn", "Deep Frost", "High Bloom", "Mist Rise", 
        "Sun Peak", "Gold Harvest", "Leaf Fall", "Red Dusk", 
        "Pale Wind", "Iron Shadow", "Star Night", "Final Cold"
    }
}

--- Format a raw tick count into a readable string.
function Calendar.format(state)
    local month_idx = state.month or 1
    local month_name = Calendar.month_names[month_idx] or "Unknown"
    
    return string.format("Day %d of %s, Year %d (Era: %s)", 
        state.day or 1, 
        month_name, 
        state.year or 0,
        state.era_label or "Foundation")
end

return Calendar
