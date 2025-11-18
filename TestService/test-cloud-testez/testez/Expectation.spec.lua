-- Tests for Expectation extended matchers
-- Following TDD: Write tests first, watch them fail, then implement
-- Extended matchers are auto-loaded by ExpectationContext

return function()
	describe("Extended Matchers", function()

		describe("deepEqual", function()
			it("should compare simple tables with same values", function()
				local t1 = {x = 1, y = 2}
				local t2 = {x = 1, y = 2}
				expect(t1).to.deepEqual(t2)
			end)

			it("should fail for tables with different values", function()
				local t1 = {x = 1, y = 2}
				local t2 = {x = 1, y = 3}
				expect(function()
					expect(t1).to.deepEqual(t2)
				end).to.throw()
			end)

			it("should compare nested tables", function()
				local t1 = {
					player = {name = "Alice", level = 10},
					items = {1, 2, 3}
				}
				local t2 = {
					player = {name = "Alice", level = 10},
					items = {1, 2, 3}
				}
				expect(t1).to.deepEqual(t2)
			end)

			it("should fail for nested tables with different values", function()
				local t1 = {player = {name = "Alice"}}
				local t2 = {player = {name = "Bob"}}
				expect(function()
					expect(t1).to.deepEqual(t2)
				end).to.throw()
			end)

			it("should compare arrays in order", function()
				expect({1, 2, 3}).to.deepEqual({1, 2, 3})
			end)

			it("should fail for arrays with different order", function()
				expect(function()
					expect({1, 2, 3}).to.deepEqual({3, 2, 1})
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect({x = 1}).never.to.deepEqual({x = 2})
			end)

			it("should handle empty tables", function()
				expect({}).to.deepEqual({})
			end)

			it("should fail when comparing table to non-table", function()
				expect(function()
					expect({x = 1}).to.deepEqual("not a table")
				end).to.throw()
			end)
		end)

		describe("include / contain", function()
			-- RED phase: These tests will fail because include/contain don't exist yet
			it("should check if string contains substring", function()
				expect("hello world").to.include("world")
			end)

			it("should fail when string doesn't contain substring", function()
				expect(function()
					expect("hello world").to.include("goodbye")
				end).to.throw()
			end)

			it("should check if array contains element", function()
				expect({1, 2, 3, 4}).to.include(3)
			end)

			it("should fail when array doesn't contain element", function()
				expect(function()
					expect({1, 2, 3}).to.include(10)
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect("hello").never.to.include("world")
				expect({1, 2, 3}).never.to.include(10)
			end)

			it("should work with contain alias", function()
				expect("hello world").to.contain("world")
				expect({1, 2, 3}).to.contain(2)
			end)

			it("should handle empty string", function()
				expect("hello").to.include("")
			end)

			it("should handle empty arrays", function()
				expect(function()
					expect({}).to.include(1)
				end).to.throw()
			end)
		end)

		describe("lengthOf", function()
			-- RED phase: These tests will fail because lengthOf doesn't exist yet
			it("should check array length", function()
				expect({1, 2, 3}).to.have.lengthOf(3)
			end)

			it("should check string length", function()
				expect("hello").to.have.lengthOf(5)
			end)

			it("should fail for incorrect array length", function()
				expect(function()
					expect({1, 2, 3}).to.have.lengthOf(5)
				end).to.throw()
			end)

			it("should fail for incorrect string length", function()
				expect(function()
					expect("hello").to.have.lengthOf(10)
				end).to.throw()
			end)

			it("should work with empty arrays", function()
				expect({}).to.have.lengthOf(0)
			end)

			it("should work with empty strings", function()
				expect("").to.have.lengthOf(0)
			end)

			it("should work with never modifier", function()
				expect({1, 2}).never.to.have.lengthOf(5)
				expect("hello").never.to.have.lengthOf(10)
			end)

			it("should fail for non-table, non-string types", function()
				expect(function()
					expect(123).to.have.lengthOf(3)
				end).to.throw()
			end)
		end)

		describe("Numeric comparison matchers", function()
			-- RED phase: These tests will fail because matchers don't exist yet

			describe("greaterThan / above", function()
				it("should check if number is greater than", function()
					expect(10).to.be.greaterThan(5)
					expect(100).to.be.above(50)
				end)

				it("should fail when number is not greater", function()
					expect(function()
						expect(5).to.be.greaterThan(10)
					end).to.throw()
				end)

				it("should fail when numbers are equal", function()
					expect(function()
						expect(10).to.be.greaterThan(10)
					end).to.throw()
				end)

				it("should work with never modifier", function()
					expect(5).never.to.be.greaterThan(10)
					expect(10).never.to.be.above(10)
				end)
			end)

			describe("lessThan / below", function()
				it("should check if number is less than", function()
					expect(5).to.be.lessThan(10)
					expect(50).to.be.below(100)
				end)

				it("should fail when number is not less", function()
					expect(function()
						expect(10).to.be.lessThan(5)
					end).to.throw()
				end)

				it("should fail when numbers are equal", function()
					expect(function()
						expect(10).to.be.lessThan(10)
					end).to.throw()
				end)

				it("should work with never modifier", function()
					expect(10).never.to.be.lessThan(5)
					expect(100).never.to.be.below(50)
				end)
			end)

			describe("greaterThanOrEqual / atLeast", function()
				it("should check if number is greater than or equal", function()
					expect(10).to.be.greaterThanOrEqual(10)
					expect(10).to.be.greaterThanOrEqual(5)
					expect(10).to.be.atLeast(10)
				end)

				it("should fail when number is less", function()
					expect(function()
						expect(5).to.be.greaterThanOrEqual(10)
					end).to.throw()
				end)

				it("should work with never modifier", function()
					expect(5).never.to.be.greaterThanOrEqual(10)
				end)
			end)

			describe("lessThanOrEqual / atMost", function()
				it("should check if number is less than or equal", function()
					expect(10).to.be.lessThanOrEqual(10)
					expect(5).to.be.lessThanOrEqual(10)
					expect(10).to.be.atMost(10)
				end)

				it("should fail when number is greater", function()
					expect(function()
						expect(10).to.be.lessThanOrEqual(5)
					end).to.throw()
				end)

				it("should work with never modifier", function()
					expect(10).never.to.be.lessThanOrEqual(5)
				end)
			end)
		end)

		describe("empty", function()
			it("should check if table is empty", function()
				expect({}).to.be.empty()
			end)

			it("should check if string is empty", function()
				expect("").to.be.empty()
			end)

			it("should fail for non-empty table", function()
				expect(function()
					expect({1, 2, 3}).to.be.empty()
				end).to.throw()
			end)

			it("should fail for non-empty string", function()
				expect(function()
					expect("hello").to.be.empty()
				end).to.throw()
			end)

			it("should work with never modifier for non-empty table", function()
				expect({1, 2, 3}).never.to.be.empty()
			end)

			it("should work with never modifier for non-empty string", function()
				expect("hello").never.to.be.empty()
			end)

			it("should handle table with only nil values as empty", function()
				local t = {}
				t[1] = nil
				expect(t).to.be.empty()
			end)

			it("should fail for non-table and non-string values", function()
				expect(function()
					expect(123).to.be.empty()
				end).to.throw()
			end)
		end)

		describe("match", function()
			it("should match simple pattern", function()
				expect("hello123").to.match("%d+")
			end)

			it("should match email pattern", function()
				expect("user@example.com").to.match("%w+@%w+%.%w+")
			end)

			it("should fail when pattern doesn't match", function()
				expect(function()
					expect("hello").to.match("%d+")
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect("hello").never.to.match("%d+")
			end)

			it("should match beginning of string with ^", function()
				expect("hello world").to.match("^hello")
			end)

			it("should match end of string with $", function()
				expect("hello world").to.match("world$")
			end)

			it("should fail for non-string values", function()
				expect(function()
					expect(123).to.match("%d+")
				end).to.throw()
			end)

			it("should handle special characters in pattern", function()
				expect("test.file").to.match("%.file")
			end)
		end)

		describe("property", function()
			it("should check if object has property", function()
				local player = {name = "Alice", level = 10}
				expect(player).to.have.property("name")
			end)

			it("should check property with specific value", function()
				local player = {name = "Alice", level = 10}
				expect(player).to.have.property("level", 10)
			end)

			it("should fail when property doesn't exist", function()
				local player = {name = "Alice"}
				expect(function()
					expect(player).to.have.property("level")
				end).to.throw()
			end)

			it("should fail when property has wrong value", function()
				local player = {name = "Alice", level = 10}
				expect(function()
					expect(player).to.have.property("level", 20)
				end).to.throw()
			end)

			it("should work with never modifier", function()
				local player = {name = "Alice"}
				expect(player).never.to.have.property("level")
			end)

			it("should work with nested properties", function()
				local data = {player = {name = "Alice"}}
				expect(data).to.have.property("player")
			end)

			it("should fail for non-table values", function()
				expect(function()
					expect("not a table").to.have.property("name")
				end).to.throw()
			end)

			it("should handle nil property values", function()
				local obj = {key = nil}
				-- Property with nil value is considered as not existing
				expect(function()
					expect(obj).to.have.property("key")
				end).to.throw()
			end)
		end)

		describe("within", function()
			it("should check if number is within range", function()
				expect(5).to.be.within(1, 10)
			end)

			it("should include boundaries", function()
				expect(1).to.be.within(1, 10)
				expect(10).to.be.within(1, 10)
			end)

			it("should fail when number is below range", function()
				expect(function()
					expect(0).to.be.within(1, 10)
				end).to.throw()
			end)

			it("should fail when number is above range", function()
				expect(function()
					expect(11).to.be.within(1, 10)
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect(0).never.to.be.within(1, 10)
				expect(11).never.to.be.within(1, 10)
			end)

			it("should work with negative ranges", function()
				expect(-5).to.be.within(-10, -1)
			end)

			it("should work with decimal numbers", function()
				expect(2.5).to.be.within(1.0, 3.0)
			end)

			it("should fail for non-number values", function()
				expect(function()
					expect("5").to.be.within(1, 10)
				end).to.throw()
			end)

			it("should fail when min or max are not numbers", function()
				expect(function()
					expect(5).to.be.within("1", 10)
				end).to.throw()
			end)
		end)

		describe("oneOf", function()
			it("should check if value is in list", function()
				expect("active").to.be.oneOf({"active", "pending", "inactive"})
			end)

			it("should work with numbers", function()
				expect(2).to.be.oneOf({1, 2, 3, 4, 5})
			end)

			it("should fail when value not in list", function()
				expect(function()
					expect("unknown").to.be.oneOf({"active", "pending"})
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect("unknown").never.to.be.oneOf({"active", "pending"})
			end)

			it("should work with single item list", function()
				expect("only").to.be.oneOf({"only"})
			end)

			it("should work with mixed types in list", function()
				expect(1).to.be.oneOf({1, "two", true})
			end)

			it("should fail for empty list", function()
				expect(function()
					expect("value").to.be.oneOf({})
				end).to.throw()
			end)

			it("should fail when list is not a table", function()
				expect(function()
					expect("value").to.be.oneOf("not a table")
				end).to.throw()
			end)

			it("should use equality comparison", function()
				expect("hello").to.be.oneOf({"hello", "world"})
				expect(function()
					expect("HELLO").to.be.oneOf({"hello", "world"})
				end).to.throw()
			end)
		end)

		describe("startWith", function()
			it("should check if string starts with prefix", function()
				expect("hello world").to.startWith("hello")
			end)

			it("should fail when string doesn't start with prefix", function()
				expect(function()
					expect("hello world").to.startWith("world")
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect("hello world").never.to.startWith("world")
			end)

			it("should be case sensitive", function()
				expect("Hello World").to.startWith("Hello")
				expect(function()
					expect("Hello World").to.startWith("hello")
				end).to.throw()
			end)

			it("should work with empty prefix", function()
				expect("hello").to.startWith("")
			end)

			it("should fail for non-string values", function()
				expect(function()
					expect(123).to.startWith("1")
				end).to.throw()
			end)

			it("should fail when prefix is not a string", function()
				expect(function()
					expect("hello").to.startWith(123)
				end).to.throw()
			end)
		end)

		describe("endWith", function()
			it("should check if string ends with suffix", function()
				expect("hello world").to.endWith("world")
			end)

			it("should fail when string doesn't end with suffix", function()
				expect(function()
					expect("hello world").to.endWith("hello")
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect("hello world").never.to.endWith("hello")
			end)

			it("should be case sensitive", function()
				expect("Hello World").to.endWith("World")
				expect(function()
					expect("Hello World").to.endWith("world")
				end).to.throw()
			end)

			it("should work with empty suffix", function()
				expect("hello").to.endWith("")
			end)

			it("should fail for non-string values", function()
				expect(function()
					expect(123).to.endWith("3")
				end).to.throw()
			end)

			it("should fail when suffix is not a string", function()
				expect(function()
					expect("hello").to.endWith(123)
				end).to.throw()
			end)
		end)

		describe("nilValue", function()
			it("should check if value is nil", function()
				expect(nil).to.be.nilValue()
			end)

			it("should fail for non-nil values", function()
				expect(function()
					expect(0).to.be.nilValue()
				end).to.throw()

				expect(function()
					expect(false).to.be.nilValue()
				end).to.throw()

				expect(function()
					expect("").to.be.nilValue()
				end).to.throw()
			end)

			it("should work with never modifier", function()
				expect(0).never.to.be.nilValue()
				expect(false).never.to.be.nilValue()
				expect("").never.to.be.nilValue()
				expect({}).never.to.be.nilValue()
			end)

			it("should detect nil in table properties", function()
				local obj = {key = nil}
				expect(obj.key).to.be.nilValue()
			end)

			it("should detect undefined variables", function()
				local undefinedVar
				expect(undefinedVar).to.be.nilValue()
			end)
		end)
	end)
end
