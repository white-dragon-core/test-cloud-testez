--[[
    Lifecycle Hooks Example

    This example demonstrates:
    - beforeEach / afterEach hooks
    - beforeAll / afterAll hooks
    - Setup and teardown patterns
    - Resource management in tests
]]

return function()
    describe("Lifecycle Hooks - beforeEach/afterEach", function()
        local testData

        beforeEach(function()
            -- This runs before EACH test
            print("Setting up test data...")
            testData = {
                name = "Player1",
                score = 0,
                level = 1
            }
        end)

        afterEach(function()
            -- This runs after EACH test
            print("Cleaning up test data...")
            testData = nil
        end)

        it("should start with initial values", function()
            expect(testData.name).to.equal("Player1")
            expect(testData.score).to.equal(0)
            expect(testData.level).to.equal(1)
        end)

        it("should allow modifying data without affecting other tests", function()
            testData.score = 100
            testData.level = 5

            expect(testData.score).to.equal(100)
            expect(testData.level).to.equal(5)
        end)

        it("should have fresh data again", function()
            -- Each test gets fresh data from beforeEach
            expect(testData.score).to.equal(0)
            expect(testData.level).to.equal(1)
        end)
    end)

    describe("Lifecycle Hooks - beforeAll/afterAll", function()
        local expensiveResource

        beforeAll(function()
            -- This runs ONCE before all tests in this describe block
            print("Creating expensive resource...")
            expensiveResource = {
                connection = "database-connection",
                initialized = true,
                data = {}
            }
        end)

        afterAll(function()
            -- This runs ONCE after all tests in this describe block
            print("Destroying expensive resource...")
            expensiveResource = nil
        end)

        it("should have access to the resource", function()
            expect(expensiveResource).to.be.ok()
            expect(expensiveResource.initialized).to.equal(true)
        end)

        it("should share the same resource instance", function()
            expensiveResource.data.testValue = "shared"
            expect(expensiveResource.data.testValue).to.equal("shared")
        end)

        it("should still have the shared modification", function()
            -- Unlike beforeEach, the resource persists between tests
            expect(expensiveResource.data.testValue).to.equal("shared")
        end)
    end)

    describe("Player Inventory System", function()
        local inventory

        beforeEach(function()
            -- Create fresh inventory for each test
            inventory = {
                items = {},
                maxSlots = 10,
                gold = 100
            }
        end)

        afterEach(function()
            -- Clean up inventory
            inventory = nil
        end)

        it("should start with empty inventory", function()
            expect(#inventory.items).to.equal(0)
        end)

        it("should add items to inventory", function()
            table.insert(inventory.items, "Sword")
            table.insert(inventory.items, "Shield")

            expect(#inventory.items).to.equal(2)
            expect(inventory.items[1]).to.equal("Sword")
        end)

        it("should not exceed max slots", function()
            for i = 1, 12 do
                if #inventory.items < inventory.maxSlots then
                    table.insert(inventory.items, "Item" .. i)
                end
            end

            expect(#inventory.items).to.equal(10)
        end)

        it("should deduct gold when buying items", function()
            local itemCost = 50
            inventory.gold = inventory.gold - itemCost

            expect(inventory.gold).to.equal(50)
        end)
    end)

    describe("Nested Lifecycle Hooks", function()
        local outerValue
        local innerValue

        beforeEach(function()
            print("Outer beforeEach")
            outerValue = "outer"
        end)

        afterEach(function()
            print("Outer afterEach")
            outerValue = nil
        end)

        it("should have outer value", function()
            expect(outerValue).to.equal("outer")
            expect(innerValue).to.equal(nil)
        end)

        describe("Inner describe block", function()
            beforeEach(function()
                print("Inner beforeEach")
                innerValue = "inner"
            end)

            afterEach(function()
                print("Inner afterEach")
                innerValue = nil
            end)

            it("should have both outer and inner values", function()
                -- Inner beforeEach runs AFTER outer beforeEach
                expect(outerValue).to.equal("outer")
                expect(innerValue).to.equal("inner")
            end)

            it("should get fresh values from both hooks", function()
                expect(outerValue).to.equal("outer")
                expect(innerValue).to.equal("inner")
            end)
        end)
    end)

    describe("Roblox Instance Cleanup", function()
        local part

        beforeEach(function()
            -- Create a new part for each test
            part = Instance.new("Part")
            part.Name = "TestPart"
            part.Size = Vector3.new(4, 1, 2)
            part.Position = Vector3.new(0, 10, 0)
        end)

        afterEach(function()
            -- Always clean up instances to avoid memory leaks
            if part then
                part:Destroy()
                part = nil
            end
        end)

        it("should create a part with correct properties", function()
            expect(part.Name).to.equal("TestPart")
            expect(part.Size).to.equal(Vector3.new(4, 1, 2))
        end)

        it("should be able to modify part properties", function()
            part.BrickColor = BrickColor.new("Bright red")
            expect(part.BrickColor.Name).to.equal("Bright red")
        end)

        it("should handle part with children", function()
            local attachment = Instance.new("Attachment")
            attachment.Parent = part

            expect(#part:GetChildren()).to.equal(1)
        end)
    end)
end
