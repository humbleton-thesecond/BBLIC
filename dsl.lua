-- BBILICLaL
local dsl = {}
local state = {}

-- --- Utility function for string splitting ---
-- This function is crucial for parsing the new syntax
function split(str, delimiter)
  local result = {}
  local from = 1
  local delim_start, delim_end = string.find(str, delimiter, from)
  while delim_start do
    table.insert(result, string.sub(str, from, delim_start - 1))
    from = delim_end + 1
    delim_start, delim_end = string.find(str, delimiter, from)
  end
  table.insert(result, string.sub(str, from))
  return result
end
-- --- End of Utility ---

-- Language Commands
function cook(product, amount)
  state[product] = (state[product] or 0) + amount
  print("Cooked " .. amount .. " units of " .. product .. ". Current amount: " .. (state[product] or 0))
end

function sell(product, amount)
  if state[product] and state[product] >= amount then
    state[product] = state[product] - amount
    print("Sold " .. amount .. " units of " .. product .. ". Remaining: " .. (state[product] or 0))
  else
    print("Not enough " .. product .. " to sell!")
  end
end

function check_stash(product)
  if state[product] then
    print("Amount of " .. product .. " in the stash: " .. (state[product] or 0))
  else
    print("No " .. product .. " in the stash yet.")
  end
end

function say_my_name(name)
  print(name)
end

-- Function to evaluate the IF condition
function evaluate_condition(product, operator_str, value)
  local current_amount = state[product] or 0
  local operator = string.lower(operator_str) -- Convert operator string to lowercase

  if operator == "less_than" then
    return current_amount < value
  elseif operator == "greater_than" then
    return current_amount > value
  elseif operator == "equals" then
    return current_amount == value
  else
    print("Yo, that's not a valid operator: " .. operator_str)
    return false
  end
end

function cleanLab(target)
  if not target then
    -- No argument, do nothing (as per spec)
    print("Lab cleaning skipped: No product specified.")
  elseif string.lower(target) == "all" then
    -- Argument is "all", clear everything
    state = {}
    print("Lab cleaned. All products removed from stash.")
  else
    -- Argument is a specific product name
    if state[target] then
      -- Product exists, remove it
      state[target] = nil -- Setting to nil effectively removes a key from a Lua table
      print("Cleaned " .. target .. " from the lab.")
    else
      -- Product does not exist (as per spec, do nothing)
      print("Lab cleaning skipped: '" .. target .. "' not found in stash.")
    end
  end
end

local valid_commands = {
  "cook",
  "sell",
  "check_stash",
  "say_my_name",
  "if",
  "end_if",
  "ding",
  "end_ding",
  "clean_lab"
}
-- Core interpreter function
function dsl:execute(code_lines)
  print"-- Starting BB Code --"
  
  -- Split the entire code string into lines for processing
  local code = split(bb_code, "\n")
  
  -- These flags are local to each call of execute_bb_lang, enabling recursion for blocks
  local in_if_block = false
  local if_condition_met = false
  local if_block_lines = {}

  local in_ding_block = false
  local ding_count = 0
  local ding_block_lines = {}

  for i, line in ipairs(code) do
    line = string.trim(line)
    if line == "" or line:sub(1,1) == "#" then
        goto continue_loop
    end

    local parts = split(line, " ")
    local command = string.lower(parts[1])

    -- Handle DING block logic
    if command == "ding" then
      -- REMOVED THE RESTRICTION HERE: if in_if_block or in_ding_block then ...
      -- We rely on the recursive call to handle nesting correctly.

      local count_str = parts[2]
      local times_keyword = string.lower(parts[3])
      local then_keyword = string.lower(parts[4])

      if not (count_str and tonumber(count_str) and times_keyword == "times" and then_keyword == "then") then
        print("Syntax error in DING statement: " .. line)
        return
      end

      in_ding_block = true
      ding_count = tonumber(count_str)
      ding_block_lines = {}
    elseif command == "end_ding" then
      if not in_ding_block then
        print("Error: END_DING without matching DING.")
        return
      end

      for _ = 1, ding_count do
        execute_bb_lang(ding_block_lines)
      end

      in_ding_block = false
      ding_count = 0
      ding_block_lines = {}
    elseif in_ding_block then
      table.insert(ding_block_lines, line)
    -- End DING block logic

    -- Handle IF block logic (existing)
    elseif command == "if" then
      -- REMOVED THE RESTRICTION HERE: if in_if_block or in_ding_block then ...
      -- We rely on the recursive call to handle nesting correctly.

      local product = parts[2]
      local operator = parts[3]
      local value = tonumber(parts[4])
      local then_keyword = string.lower(parts[5])

      if not (product and operator and value and then_keyword == "then") then
        print("Syntax error in IF statement: " .. line)
        return
      end

      in_if_block = true
      if_condition_met = evaluate_condition(product, operator, value)
      if_block_lines = {}
    elseif command == "end_if" then
      if not in_if_block then
        print("Error: END_IF without matching IF.")
        return
      end

      if if_condition_met then
        execute_bb_lang(if_block_lines)
      end
      in_if_block = false
      if_condition_met = false
      if_block_lines = {}
    elseif in_if_block then
      table.insert(if_block_lines, line)
    -- End IF block logic

    -- Regular command execution (only if not inside any block)
    else
      -- This 'else' block executes top-level commands.
      -- Commands inside IF/DING blocks are handled by the recursive calls
      -- to `execute_bb_lang` when their respective `END_IF` or `END_DING` is hit.
      local arg1 = parts[2]
      local arg2 = tonumber(parts[3])
      local found = false
      for _, element in pairs(valid_commands) do
        if element == command then
          found = true
          break -- Optional: Stop iterating once found
        end
      end
      if not found then
        print("Yo, that's not a valid command:", command, "; at line", i)
        return
      end

      if command == "cook" then
        if not arg1 then
          print("What do you want to cook jesse?")
          return
        elseif arg1 and not arg2 then
          print("how many should we cook",arg1,"jesse?")
          return
        end
        cook(arg1, arg2)
      elseif command == "sell" then
        if not arg1 then
          print("What do you want to sell jesse?")
          return
        elseif arg1 and not arg2 then
          if state[arg1] < 10 then
            print("how much of '",arg1,"' should we sell jesse?")
            return
          elseif state[arg1] >= 10 then
            print("how much of '",arg1,"' should we sell heisenberg?")
            return
          end
        end
        sell(arg1, arg2)
      elseif command == "check_stash" then
        check_stash(arg1)
      elseif command == "say_my_name" then
        say_my_name(arg1)
      elseif command == "clean_lab" then
        cleanLab(arg1)
      end
    end
    ::continue_loop::
  end
  print"-- Ending BB Code --"
end

-- Extend string library for trimming (useful for parsing)
function string.trim(s)
   return s:match("^%s*(.*%S)%s*$") or ""
end

return dsl
