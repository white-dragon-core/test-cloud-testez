-- Tests for StringUtils module
return function()
	local StringUtils = require(script.Parent.StringUtils)

	_G.print("📝 Starting StringUtils tests...")

	describe("StringUtils.reverse", function()
		it("should reverse a string", function()
			_G.print("Testing string reverse: hello -> olleh")
			expect(StringUtils.reverse("hello")).to.equal("olleh")
		end)

		it("should handle empty string", function()
			expect(StringUtils.reverse("")).to.equal("")
		end)

		it("should handle single character", function()
			expect(StringUtils.reverse("a")).to.equal("a")
		end)
	end)

	describe("StringUtils.startsWith", function()
		it("should return true when string starts with prefix", function()
			expect(StringUtils.startsWith("hello world", "hello")).to.equal(true)
		end)

		it("should return false when string doesn't start with prefix", function()
			expect(StringUtils.startsWith("hello world", "world")).to.equal(false)
		end)

		it("should handle empty prefix", function()
			expect(StringUtils.startsWith("hello", "")).to.equal(true)
		end)
	end)

	describe("StringUtils.endsWith", function()
		it("should return true when string ends with suffix", function()
			expect(StringUtils.endsWith("hello world", "world")).to.equal(true)
		end)

		it("should return false when string doesn't end with suffix", function()
			expect(StringUtils.endsWith("hello world", "hello")).to.equal(false)
		end)

		it("should handle empty suffix", function()
			expect(StringUtils.endsWith("hello", "")).to.equal(true)
		end)
	end)

	describe("StringUtils.split", function()
		it("should split string by delimiter", function()
			local result = StringUtils.split("a,b,c", ",")
			expect(#result).to.equal(3)
			expect(result[1]).to.equal("a")
			expect(result[2]).to.equal("b")
			expect(result[3]).to.equal("c")
		end)

		it("should handle single element", function()
			local result = StringUtils.split("hello", ",")
			expect(#result).to.equal(1)
			expect(result[1]).to.equal("hello")
		end)
	end)

	describe("StringUtils.trim", function()
		it("should trim whitespace from both ends", function()
			expect(StringUtils.trim("  hello  ")).to.equal("hello")
		end)

		it("should handle string with no whitespace", function()
			expect(StringUtils.trim("hello")).to.equal("hello")
		end)

		it("should handle empty string", function()
			expect(StringUtils.trim("")).to.equal("")
		end)
	end)

	describe("StringUtils.titleCase", function()
		it("should convert to title case", function()
			expect(StringUtils.titleCase("hello world")).to.equal("Hello World")
		end)

		it("should handle already capitalized text", function()
			expect(StringUtils.titleCase("Hello World")).to.equal("Hello World")
		end)

		it("should handle single word", function()
			expect(StringUtils.titleCase("hello")).to.equal("Hello")
		end)
	end)
end
