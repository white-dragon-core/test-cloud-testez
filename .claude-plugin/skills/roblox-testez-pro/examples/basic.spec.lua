--[[
    Basic TestEZ Example

    This example demonstrates:
    - Basic describe/it structure
    - Common assertions
    - Simple test organization
]]

return function()
    describe("Basic Math Operations", function()
        it("should add two numbers correctly", function()
            local result = 2 + 2
            expect(result).to.equal(4)
        end)

        it("should subtract two numbers correctly", function()
            local result = 10 - 5
            expect(result).to.equal(5)
        end)

        it("should multiply two numbers correctly", function()
            local result = 3 * 4
            expect(result).to.equal(12)
        end)

        it("should divide two numbers correctly", function()
            local result = 20 / 4
            expect(result).to.equal(5)
        end)

        it("should handle decimal arithmetic", function()
            local result = 0.1 + 0.2
            expect(result).to.be.near(0.3, 0.0001)
        end)
    end)

    describe("String Operations", function()
        it("should concatenate strings", function()
            local result = "Hello" .. " " .. "World"
            expect(result).to.equal("Hello World")
        end)

        it("should get string length", function()
            local str = "TestEZ"
            expect(#str).to.equal(6)
        end)

        it("should convert to uppercase", function()
            local result = string.upper("hello")
            expect(result).to.equal("HELLO")
        end)
    end)

    describe("Table Operations", function()
        it("should create an empty table", function()
            local tbl = {}
            expect(type(tbl)).to.equal("table")
            expect(#tbl).to.equal(0)
        end)

        it("should add elements to a table", function()
            local tbl = {}
            table.insert(tbl, "first")
            table.insert(tbl, "second")

            expect(#tbl).to.equal(2)
            expect(tbl[1]).to.equal("first")
            expect(tbl[2]).to.equal("second")
        end)

        it("should remove elements from a table", function()
            local tbl = {1, 2, 3, 4, 5}
            table.remove(tbl, 3)

            expect(#tbl).to.equal(4)
            expect(tbl[3]).to.equal(4)
        end)
    end)

    describe("Type Checking", function()
        it("should identify number types", function()
            expect(42).to.be.a("number")
            expect(3.14).to.be.a("number")
        end)

        it("should identify string types", function()
            expect("Hello").to.be.a("string")
        end)

        it("should identify boolean types", function()
            expect(true).to.be.a("boolean")
            expect(false).to.be.a("boolean")
        end)

        it("should identify table types", function()
            expect({}).to.be.a("table")
            expect({1, 2, 3}).to.be.a("table")
        end)

        it("should identify function types", function()
            local fn = function() end
            expect(fn).to.be.a("function")
        end)
    end)

    describe("Truthiness", function()
        it("should recognize truthy values", function()
            expect(true).to.be.ok()
            expect(1).to.be.ok()
            expect("string").to.be.ok()
            expect({}).to.be.ok()
        end)

        it("should recognize falsy values", function()
            expect(false).never.to.be.ok()
            expect(nil).never.to.be.ok()
        end)
    end)

    describe("Error Handling", function()
        it("should catch errors when functions throw", function()
            expect(function()
                error("Something went wrong")
            end).to.throw()
        end)

        it("should match specific error messages", function()
            expect(function()
                error("Division by zero")
            end).to.throw("Division by zero")
        end)

        it("should not throw when function succeeds", function()
            expect(function()
                return 1 + 1
            end).never.to.throw()
        end)
    end)
end
