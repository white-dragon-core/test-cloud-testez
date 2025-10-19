--[[
    Mocking and Test Doubles Example

    This example demonstrates:
    - Creating mock objects
    - Mocking Roblox services
    - Dependency injection for testing
    - Spy functions to track calls
]]

return function()
    describe("Mock Objects", function()
        it("should create a simple mock", function()
            local mockPlayer = {
                Name = "TestPlayer",
                UserId = 12345,
                Health = 100,
                MaxHealth = 100
            }

            expect(mockPlayer.Name).to.equal("TestPlayer")
            expect(mockPlayer.Health).to.equal(100)
        end)

        it("should create a mock with methods", function()
            local mockWeapon = {
                damage = 50,
                ammo = 10,

                fire = function(self)
                    if self.ammo > 0 then
                        self.ammo = self.ammo - 1
                        return self.damage
                    end
                    return 0
                end,

                reload = function(self)
                    self.ammo = 10
                end
            }

            local damage = mockWeapon:fire()
            expect(damage).to.equal(50)
            expect(mockWeapon.ammo).to.equal(9)
        end)
    end)

    describe("Spy Functions", function()
        it("should track function calls", function()
            local callCount = 0
            local lastArgs = nil

            local spy = function(...)
                callCount = callCount + 1
                lastArgs = {...}
            end

            spy("arg1", "arg2")
            spy("arg3")

            expect(callCount).to.equal(2)
            expect(lastArgs[1]).to.equal("arg3")
        end)

        it("should wrap existing functions", function()
            local originalFunction = function(a, b)
                return a + b
            end

            local callCount = 0
            local wrappedFunction = function(...)
                callCount = callCount + 1
                return originalFunction(...)
            end

            local result1 = wrappedFunction(2, 3)
            local result2 = wrappedFunction(5, 7)

            expect(result1).to.equal(5)
            expect(result2).to.equal(12)
            expect(callCount).to.equal(2)
        end)
    end)

    describe("Mocking Roblox Services", function()
        it("should mock DataStoreService", function()
            local testData = {}

            local MockDataStoreService = {
                GetDataStore = function(self, name)
                    return {
                        name = name,
                        data = {},

                        GetAsync = function(self, key)
                            return self.data[key]
                        end,

                        SetAsync = function(self, key, value)
                            self.data[key] = value
                        end,

                        UpdateAsync = function(self, key, transformFunction)
                            local oldValue = self.data[key]
                            local newValue = transformFunction(oldValue)
                            self.data[key] = newValue
                            return newValue
                        end
                    }
                end
            }

            local dataStore = MockDataStoreService:GetDataStore("PlayerData")
            dataStore:SetAsync("Player_123", { coins = 100 })
            local data = dataStore:GetAsync("Player_123")

            expect(data.coins).to.equal(100)
        end)

        it("should mock TweenService", function()
            local MockTweenService = {
                Create = function(self, instance, tweenInfo, propertyTable)
                    return {
                        instance = instance,
                        properties = propertyTable,
                        isPlaying = false,

                        Play = function(self)
                            self.isPlaying = true
                            -- Instantly apply properties for testing
                            for key, value in pairs(self.properties) do
                                self.instance[key] = value
                            end
                        end,

                        Cancel = function(self)
                            self.isPlaying = false
                        end
                    }
                end
            }

            local part = { Transparency = 0 }
            local tween = MockTweenService:Create(part, nil, { Transparency = 1 })
            tween:Play()

            expect(part.Transparency).to.equal(1)
            expect(tween.isPlaying).to.equal(true)
        end)
    end)

    describe("Dependency Injection", function()
        -- Original function that depends on external service
        local function savePlayerData(player, dataStore)
            local data = {
                level = player.Level,
                coins = player.Coins
            }
            dataStore:SetAsync("Player_" .. player.UserId, data)
        end

        local function loadPlayerData(player, dataStore)
            local data = dataStore:GetAsync("Player_" .. player.UserId)
            if data then
                player.Level = data.level
                player.Coins = data.coins
            end
        end

        it("should save and load player data with mock datastore", function()
            -- Create mock datastore
            local mockDataStore = {
                data = {},

                GetAsync = function(self, key)
                    return self.data[key]
                end,

                SetAsync = function(self, key, value)
                    self.data[key] = value
                end
            }

            -- Create mock player
            local mockPlayer = {
                UserId = 12345,
                Level = 5,
                Coins = 1000
            }

            -- Test saving
            savePlayerData(mockPlayer, mockDataStore)
            expect(mockDataStore.data["Player_12345"]).to.be.ok()
            expect(mockDataStore.data["Player_12345"].level).to.equal(5)

            -- Test loading
            local newPlayer = {
                UserId = 12345,
                Level = 1,
                Coins = 0
            }
            loadPlayerData(newPlayer, mockDataStore)
            expect(newPlayer.Level).to.equal(5)
            expect(newPlayer.Coins).to.equal(1000)
        end)
    end)

    describe("Mock Remote Events", function()
        it("should mock RemoteEvent behavior", function()
            local receivedArgs = nil

            local MockRemoteEvent = {
                OnServerEvent = {
                    Connect = function(self, callback)
                        return {
                            callback = callback,
                            Disconnect = function() end
                        }
                    end
                },

                FireClient = function(self, player, ...)
                    receivedArgs = {...}
                end,

                FireAllClients = function(self, ...)
                    receivedArgs = {...}
                end
            }

            MockRemoteEvent:FireClient(nil, "message", 123)

            expect(receivedArgs[1]).to.equal("message")
            expect(receivedArgs[2]).to.equal(123)
        end)
    end)

    describe("Testing with Time", function()
        it("should mock time-dependent functions", function()
            local currentTime = 0

            local MockTime = {
                now = function()
                    return currentTime
                end,

                advance = function(seconds)
                    currentTime = currentTime + seconds
                end
            }

            local function createCooldown(duration, timeProvider)
                local lastUse = 0

                return {
                    canUse = function()
                        return timeProvider.now() - lastUse >= duration
                    end,

                    use = function()
                        lastUse = timeProvider.now()
                    end
                }
            end

            local cooldown = createCooldown(5, MockTime)

            expect(cooldown.canUse()).to.equal(true)

            cooldown.use()
            expect(cooldown.canUse()).to.equal(false)

            MockTime.advance(3)
            expect(cooldown.canUse()).to.equal(false)

            MockTime.advance(2)
            expect(cooldown.canUse()).to.equal(true)
        end)
    end)
end
