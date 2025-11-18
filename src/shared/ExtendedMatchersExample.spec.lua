-- Example: Using Extended Matchers
-- No need to require or extend anything - matchers are auto-loaded!

return function()
	describe("Extended Matchers Example", function()
		describe("deepEqual matcher", function()
			it("should compare nested player data", function()
				local player1 = {
					name = "Alice",
					stats = {
						level = 10,
						health = 100,
						mana = 50
					},
					inventory = {"sword", "shield", "potion"}
				}

				local player2 = {
					name = "Alice",
					stats = {
						level = 10,
						health = 100,
						mana = 50
					},
					inventory = {"sword", "shield", "potion"}
				}

				-- ✅ Just use it directly!
				expect(player1).to.deepEqual(player2)
			end)

			it("should detect differences in nested data", function()
				local config1 = {settings = {volume = 100}}
				local config2 = {settings = {volume = 50}}

				expect(function()
					expect(config1).to.deepEqual(config2)
				end).to.throw()
			end)
		end)

		describe("include/contain matcher", function()
			it("should check if error message contains text", function()
				local errorMsg = "Invalid input: expected number, got string"

				-- ✅ Check if string contains substring
				expect(errorMsg).to.include("Invalid input")
				expect(errorMsg).to.contain("expected number")
			end)

			it("should check if inventory contains item", function()
				local inventory = {"sword", "shield", "potion", "armor"}

				-- ✅ Check if array contains element
				expect(inventory).to.include("potion")
				expect(inventory).to.contain("shield")
			end)

			it("should verify item is not in inventory", function()
				local inventory = {"sword", "shield"}

				-- ✅ Use never modifier
				expect(inventory).never.to.include("legendary_sword")
			end)
		end)

		describe("lengthOf matcher", function()
			it("should check array length", function()
				local inventory = {"sword", "shield", "potion"}

				-- ✅ Check array length
				expect(inventory).to.have.lengthOf(3)
			end)

			it("should check string length", function()
				local playerName = "Alice"

				-- ✅ Check string length
				expect(playerName).to.have.lengthOf(5)
			end)

			it("should verify empty collections", function()
				-- ✅ Empty array and string
				expect({}).to.have.lengthOf(0)
				expect("").to.have.lengthOf(0)
			end)
		end)

		describe("Numeric comparison matchers", function()
			it("should validate player stats", function()
				local playerHealth = 75
				local playerLevel = 10

				-- ✅ greaterThan / above
				expect(playerHealth).to.be.greaterThan(50)
				expect(playerLevel).to.be.above(5)

				-- ✅ lessThan / below
				expect(playerHealth).to.be.lessThan(100)
				expect(playerLevel).to.be.below(20)

				-- ✅ greaterThanOrEqual / atLeast
				expect(playerHealth).to.be.greaterThanOrEqual(75)
				expect(playerLevel).to.be.atLeast(10)

				-- ✅ lessThanOrEqual / atMost
				expect(playerHealth).to.be.lessThanOrEqual(100)
				expect(playerLevel).to.be.atMost(10)
			end)

			it("should validate score ranges", function()
				local score = 850

				-- ✅ Combine multiple checks
				expect(score).to.be.greaterThan(0)
				expect(score).to.be.lessThan(1000)
				expect(score).never.to.be.greaterThan(1000)
			end)
		end)

		describe("empty matcher", function()
			it("should check if collections are empty", function()
				local emptyInventory = {}
				local emptyMessage = ""

				-- ✅ Check if table is empty
				expect(emptyInventory).to.be.empty()

				-- ✅ Check if string is empty
				expect(emptyMessage).to.be.empty()
			end)

			it("should verify non-empty collections", function()
				local inventory = {"sword", "shield"}
				local message = "Hello"

				-- ✅ Use never modifier for non-empty
				expect(inventory).never.to.be.empty()
				expect(message).never.to.be.empty()
			end)
		end)

		describe("match matcher", function()
			it("should validate player name format", function()
				local playerName = "Player123"

				-- ✅ Match letters followed by numbers
				expect(playerName).to.match("^%w+%d+$")
			end)

			it("should validate UUID format", function()
				local sessionId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

				-- ✅ Match UUID pattern (simplified)
				expect(sessionId).to.match("%x+%-%x+%-%x+%-%x+%-%x+")
			end)

			it("should check error message format", function()
				local errorMsg = "Error: Invalid operation at line 42"

				-- ✅ Match error prefix
				expect(errorMsg).to.match("^Error:")

				-- ✅ Match line number
				expect(errorMsg).to.match("line %d+")
			end)
		end)

		describe("property matcher", function()
			it("should check if player has required fields", function()
				local player = {
					name = "Alice",
					level = 10,
					team = "red"
				}

				-- ✅ Check property existence
				expect(player).to.have.property("name")
				expect(player).to.have.property("level")
				expect(player).to.have.property("team")

				-- ✅ Check property doesn't exist
				expect(player).never.to.have.property("score")
			end)

			it("should validate property values", function()
				local config = {
					maxPlayers = 10,
					roundTime = 300
				}

				-- ✅ Check property with specific value
				expect(config).to.have.property("maxPlayers", 10)
				expect(config).to.have.property("roundTime", 300)
			end)

			it("should verify API response structure", function()
				local response = {
					status = "success",
					data = {
						userId = "12345",
						username = "alice"
					}
				}

				-- ✅ Check nested properties
				expect(response).to.have.property("status", "success")
				expect(response).to.have.property("data")
			end)
		end)

		describe("within matcher", function()
			it("should validate player health in range", function()
				local playerHealth = 75

				-- ✅ Check if value is within range (inclusive)
				expect(playerHealth).to.be.within(0, 100)
			end)

			it("should validate random damage values", function()
				local damage = 15

				-- ✅ Damage should be between 10 and 20
				expect(damage).to.be.within(10, 20)

				-- ✅ Never outside the range
				expect(damage).never.to.be.within(50, 100)
			end)

			it("should check percentage values", function()
				local successRate = 0.85

				-- ✅ Should be between 0 and 1
				expect(successRate).to.be.within(0, 1)
			end)

			it("should validate negative ranges", function()
				local temperature = -5

				-- ✅ Works with negative numbers
				expect(temperature).to.be.within(-10, 0)
			end)
		end)

		describe("oneOf matcher", function()
			it("should validate player status", function()
				local playerStatus = "active"

				-- ✅ Check if value is in enum list
				expect(playerStatus).to.be.oneOf({"active", "pending", "inactive"})
			end)

			it("should verify game mode", function()
				local gameMode = "PvP"

				-- ✅ Game mode should be one of valid modes
				expect(gameMode).to.be.oneOf({"PvP", "PvE", "Creative"})

				-- ✅ Never an invalid mode
				expect(gameMode).never.to.be.oneOf({"Admin", "Spectator"})
			end)

			it("should check team assignment", function()
				local team = "blue"

				-- ✅ Team must be red, blue, green, or yellow
				expect(team).to.be.oneOf({"red", "blue", "green", "yellow"})
			end)

			it("should validate difficulty level", function()
				local difficulty = 2

				-- ✅ Difficulty is 1-5
				expect(difficulty).to.be.oneOf({1, 2, 3, 4, 5})
			end)
		end)

		describe("Real-world usage example", function()
			it("should validate game state comprehensively", function()
				-- Simulate game state
				local gameState = {
					mode = "combat",
					players = {
						{name = "Alice", team = "red", score = 150},
						{name = "Bob", team = "blue", score = 120}
					},
					config = {
						maxPlayers = 10,
						roundTime = 300
					}
				}

				-- ✅ deepEqual: Verify entire state structure
				expect(gameState).to.deepEqual({
					mode = "combat",
					players = {
						{name = "Alice", team = "red", score = 150},
						{name = "Bob", team = "blue", score = 120}
					},
					config = {
						maxPlayers = 10,
						roundTime = 300
					}
				})

				-- ✅ include: Check specific string values
				expect(gameState.mode).to.include("combat")

				-- ✅ lengthOf: Verify collection sizes
				expect(gameState.players).to.have.lengthOf(2)

				-- ✅ Numeric comparison: Validate ranges
				expect(gameState.players[1].score).to.be.greaterThan(100)
				expect(gameState.players[1].score).to.be.lessThan(200)
				expect(gameState.config.maxPlayers).to.be.atLeast(10)
				expect(gameState.config.roundTime).to.be.atMost(300)
			end)
		end)
	end)
end
