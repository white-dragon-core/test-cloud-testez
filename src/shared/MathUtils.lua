-- Math utility functions
local MathUtils = {}

-- Add two numbers
function MathUtils.add(a, b)
	return a + b
end

-- Subtract b from a
function MathUtils.subtract(a, b)
	return a - b
end

-- Multiply two numbers
function MathUtils.multiply(a, b)
	return a * b
end

-- Divide a by b
function MathUtils.divide(a, b)
	if b == 0 then
		error("Division by zero")
	end
	return a / b
end

-- Check if a number is even
function MathUtils.isEven(n)
	return n % 2 == 0
end

-- Check if a number is prime
function MathUtils.isPrime(n)
	if n < 2 then
		return false
	end

	for i = 2, math.sqrt(n) do
		if n % i == 0 then
			return false
		end
	end

	return true
end

-- Calculate factorial
function MathUtils.factorial(n)
	if n < 0 then
		error("Factorial of negative number")
	end

	if n == 0 or n == 1 then
		return 1
	end

	local result = 1
	for i = 2, n do
		result = result * i
	end

	return result
end

return MathUtils
