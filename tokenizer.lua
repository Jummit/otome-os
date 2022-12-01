---------------
-- Tokenizer --
---------------

-- Generates a list of tokens from a single line by reading it
-- character by character.

-- Characters which are used directly and act as word delimiters.
local literal = {}
for _, char in ipairs{"{", "}", "(", ")", "[", "]", "=", "$", "!"} do
	literal[char] = true
end

return function(line)
	local stack = {}
	local word = ""
	local inString = false
	-- True if the word was prefixed with a '.
	local nextIsString = false

	local function push(v, val)
		table.insert(stack, { type = v, value = val })
	end

	local function finishWord()
		if word == "" then
			return
		end
		if nextIsString then
			push("string", word)
			nextIsString = false
		elseif tonumber(word) then
			push("number", tonumber(word))
		else
			push("word", word)
		end
		word = ""
	end

	for i = 1, #line do
		local char = line:sub(i, i)
		if char == '"' then
			if word:sub(-1, -1) == "\\" then
				-- Add an escaped parenthesis.
				word = word:gsub("\\$", '"')
			elseif inString then
				push("string", word)
				word = ""
				inString = false
			else
				inString = true
			end
		elseif inString then
			word = word..char
		elseif literal[char] then
			finishWord()
			push(char)
		elseif char == " " then
			finishWord()
		elseif char == "'" then
			nextIsString = true
		else
			word = word..char
		end
	end
	finishWord()

	return stack
end
