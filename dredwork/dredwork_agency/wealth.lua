-- dredwork Agency — Personal Wealth
-- Separate from realm treasury. A character's own money.
-- Earned from roles, stolen from crime, received as gifts, spent on personal choices.

local Math = require("dredwork_core.math")

local Wealth = {}

--- Create a fresh personal wealth component.
function Wealth.create(starting_gold)
    return {
        gold = starting_gold or 10,
        income_sources = {},  -- { source, amount_per_month }
        expenses = {},        -- { reason, amount_per_month }
        transactions = {},    -- recent { day, delta, reason } (last 10)
    }
end

--- Add or remove personal gold.
function Wealth.change(pw, delta, reason, day)
    pw.gold = Math.clamp(pw.gold + delta, 0, 99999)
    table.insert(pw.transactions, { day = day or 0, delta = delta, reason = reason or "unknown" })
    while #pw.transactions > 10 do table.remove(pw.transactions, 1) end
    return pw.gold
end

--- Add an income source (e.g., salary from a role).
function Wealth.add_income(pw, source, amount)
    table.insert(pw.income_sources, { source = source, amount = amount })
end

--- Remove an income source.
function Wealth.remove_income(pw, source)
    for i, inc in ipairs(pw.income_sources) do
        if inc.source == source then table.remove(pw.income_sources, i); return end
    end
end

--- Tick monthly: collect income, pay expenses.
function Wealth.tick_monthly(pw, day)
    for _, inc in ipairs(pw.income_sources) do
        Wealth.change(pw, inc.amount, "income: " .. inc.source, day)
    end
    for _, exp in ipairs(pw.expenses) do
        Wealth.change(pw, -exp.amount, "expense: " .. exp.reason, day)
    end
end

--- Can afford a purchase?
function Wealth.can_afford(pw, cost)
    return pw.gold >= cost
end

--- Get total monthly income.
function Wealth.get_monthly_income(pw)
    local total = 0
    for _, inc in ipairs(pw.income_sources) do total = total + inc.amount end
    return total
end

--- Get total monthly expenses.
function Wealth.get_monthly_expenses(pw)
    local total = 0
    for _, exp in ipairs(pw.expenses) do total = total + exp.amount end
    return total
end

--- Add a recurring expense.
function Wealth.add_expense(pw, reason, amount)
    table.insert(pw.expenses, { reason = reason, amount = amount })
end

--- Remove an expense by reason.
function Wealth.remove_expense(pw, reason)
    for i, exp in ipairs(pw.expenses) do
        if exp.reason == reason then table.remove(pw.expenses, i); return end
    end
end

--- Setup survival expenses (rent + food). Called at game start.
function Wealth.setup_survival(pw)
    -- Check if already set up
    for _, exp in ipairs(pw.expenses) do
        if exp.reason == "rent" then return end
    end
    Wealth.add_expense(pw, "rent", 8)
    Wealth.add_expense(pw, "food", 5)
end

--- Tick monthly with unpaid expense tracking. Returns list of unpaid expenses.
function Wealth.tick_monthly_survival(pw, day)
    local unpaid = {}
    local gold_before = pw.gold

    -- Collect income first
    for _, inc in ipairs(pw.income_sources) do
        Wealth.change(pw, inc.amount, "income: " .. inc.source, day)
    end

    -- Pay expenses — track which ones can't be paid
    for _, exp in ipairs(pw.expenses) do
        if pw.gold >= exp.amount then
            Wealth.change(pw, -exp.amount, "expense: " .. exp.reason, day)
        else
            -- Partial payment or nothing
            local paid = pw.gold
            if paid > 0 then
                Wealth.change(pw, -paid, "partial: " .. exp.reason, day)
            end
            table.insert(unpaid, { reason = exp.reason, amount = exp.amount, shortfall = exp.amount - paid })
        end
    end

    return unpaid, gold_before
end

return Wealth
