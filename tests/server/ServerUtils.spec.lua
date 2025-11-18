-- ServerUtils 测试套件

return function()
	local ServerUtils = require(script.Parent.ServerUtils)

	print("🖥️ Starting ServerUtils tests...")

	describe("ServerUtils.hasPermission", function()
		it("should grant admin permission to userId 1", function()
			expect(ServerUtils.hasPermission(1, "admin")).to.equal(true)
		end)

		it("should grant admin permission to userId 2", function()
			expect(ServerUtils.hasPermission(2, "admin")).to.equal(true)
		end)

		it("should deny admin permission to userId 100", function()
			expect(ServerUtils.hasPermission(100, "admin")).to.equal(false)
		end)

		it("should grant moderator permission to userId 5", function()
			expect(ServerUtils.hasPermission(5, "moderator")).to.equal(true)
		end)

		it("should deny moderator permission to userId 20", function()
			expect(ServerUtils.hasPermission(20, "moderator")).to.equal(false)
		end)

		it("should grant default permission to any valid userId", function()
			expect(ServerUtils.hasPermission(999, "user")).to.equal(true)
		end)

		it("should deny permission to invalid userId", function()
			expect(ServerUtils.hasPermission(0, "admin")).to.equal(false)
			expect(ServerUtils.hasPermission(-1, "admin")).to.equal(false)
		end)
	end)

	describe("ServerUtils.getServerTimestamp", function()
		it("should return a number", function()
			local timestamp = ServerUtils.getServerTimestamp()
			expect(typeof(timestamp)).to.equal("number")
		end)

		it("should return a positive timestamp", function()
			local timestamp = ServerUtils.getServerTimestamp()
			expect(timestamp).to.be.ok()
			expect(timestamp > 0).to.equal(true)
		end)
	end)

	describe("ServerUtils.validateData", function()
		it("should validate correct data", function()
			local data = {
				userId = 123,
				action = "jump"
			}
			local valid, message = ServerUtils.validateData(data)
			expect(valid).to.equal(true)
			expect(message).to.equal("Data is valid")
		end)

		it("should reject non-table data", function()
			local valid, message = ServerUtils.validateData("not a table")
			expect(valid).to.equal(false)
			expect(message).to.equal("Data must be a table")
		end)

		it("should reject data without userId", function()
			local data = {
				action = "jump"
			}
			local valid, message = ServerUtils.validateData(data)
			expect(valid).to.equal(false)
			expect(message).to.equal("Missing or invalid userId")
		end)

		it("should reject data without action", function()
			local data = {
				userId = 123
			}
			local valid, message = ServerUtils.validateData(data)
			expect(valid).to.equal(false)
			expect(message).to.equal("Missing or invalid action")
		end)

		it("should reject data with invalid userId type", function()
			local data = {
				userId = "not a number",
				action = "jump"
			}
			local valid, message = ServerUtils.validateData(data)
			expect(valid).to.equal(false)
		end)
	end)

	describe("ServerUtils.calculateLevel", function()
		it("should return level 1 for 0 experience", function()
			expect(ServerUtils.calculateLevel(0)).to.equal(1)
		end)

		it("should return level 1 for 999 experience", function()
			expect(ServerUtils.calculateLevel(999)).to.equal(1)
		end)

		it("should return level 2 for 1000 experience", function()
			expect(ServerUtils.calculateLevel(1000)).to.equal(2)
		end)

		it("should return level 5 for 4500 experience", function()
			expect(ServerUtils.calculateLevel(4500)).to.equal(5)
		end)

		it("should return level 1 for negative experience", function()
			expect(ServerUtils.calculateLevel(-100)).to.equal(1)
		end)

		it("should return level 1 for invalid input", function()
			expect(ServerUtils.calculateLevel("not a number")).to.equal(1)
		end)
	end)

	print("✅ ServerUtils tests completed")
end
