--[[
    Asynchronous Testing Example

    This example demonstrates:
    - Testing async operations
    - Handling promises/callbacks
    - Testing with yields and waits
    - Timeout handling
]]

return function()
    describe("Asynchronous Operations", function()
        it("should handle simple delays", function()
            local completed = false

            spawn(function()
                wait(0.1)
                completed = true
            end)

            -- Wait for async operation
            wait(0.2)

            expect(completed).to.equal(true)
        end)

        it("should test callback-based async", function()
            local result = nil
            local callbackCalled = false

            local function asyncOperation(callback)
                spawn(function()
                    wait(0.1)
                    callback("success")
                end)
            end

            asyncOperation(function(value)
                result = value
                callbackCalled = true
            end)

            -- Wait for callback
            wait(0.2)

            expect(callbackCalled).to.equal(true)
            expect(result).to.equal("success")
        end)
    end)

    describe("Promise-like Patterns", function()
        -- Simple Promise implementation for testing
        local function Promise(executor)
            local promise = {
                state = "pending",
                value = nil,
                callbacks = {}
            }

            function promise:andThen(callback)
                if self.state == "resolved" then
                    callback(self.value)
                else
                    table.insert(self.callbacks, callback)
                end
                return self
            end

            local function resolve(value)
                if promise.state == "pending" then
                    promise.state = "resolved"
                    promise.value = value

                    for _, callback in ipairs(promise.callbacks) do
                        callback(value)
                    end
                end
            end

            local function reject(error)
                if promise.state == "pending" then
                    promise.state = "rejected"
                    promise.value = error
                end
            end

            spawn(function()
                executor(resolve, reject)
            end)

            return promise
        end

        it("should resolve promises", function()
            local resolved = false
            local value = nil

            local promise = Promise(function(resolve, reject)
                wait(0.1)
                resolve("test value")
            end)

            promise:andThen(function(val)
                resolved = true
                value = val
            end)

            wait(0.2)

            expect(resolved).to.equal(true)
            expect(value).to.equal("test value")
        end)

        it("should chain promises", function()
            local finalValue = nil

            Promise(function(resolve)
                wait(0.05)
                resolve(5)
            end):andThen(function(value)
                return value * 2
            end):andThen(function(value)
                finalValue = value
            end)

            wait(0.2)

            expect(finalValue).to.equal(10)
        end)
    end)

    describe("Simulated Network Requests", function()
        local function mockHTTPRequest(url, callback)
            spawn(function()
                wait(0.1)

                if url:find("success") then
                    callback({
                        Success = true,
                        StatusCode = 200,
                        Body = '{"data": "test"}'
                    })
                else
                    callback({
                        Success = false,
                        StatusCode = 404,
                        Body = "Not found"
                    })
                end
            end)
        end

        it("should handle successful requests", function()
            local response = nil

            mockHTTPRequest("https://api.example.com/success", function(res)
                response = res
            end)

            wait(0.2)

            expect(response).to.be.ok()
            expect(response.Success).to.equal(true)
            expect(response.StatusCode).to.equal(200)
        end)

        it("should handle failed requests", function()
            local response = nil

            mockHTTPRequest("https://api.example.com/fail", function(res)
                response = res
            end)

            wait(0.2)

            expect(response).to.be.ok()
            expect(response.Success).to.equal(false)
            expect(response.StatusCode).to.equal(404)
        end)
    end)

    describe("Event-based Async", function()
        it("should test event firing and handling", function()
            -- Create a mock event
            local MockEvent = {
                listeners = {},

                Connect = function(self, callback)
                    table.insert(self.listeners, callback)
                    return {
                        Disconnect = function()
                            -- Remove callback
                        end
                    }
                end,

                Fire = function(self, ...)
                    for _, listener in ipairs(self.listeners) do
                        spawn(function()
                            listener(...)
                        end)
                    end
                end
            }

            local eventFired = false
            local eventData = nil

            MockEvent:Connect(function(data)
                eventFired = true
                eventData = data
            end)

            MockEvent:Fire("test data")

            wait(0.1)

            expect(eventFired).to.equal(true)
            expect(eventData).to.equal("test data")
        end)

        it("should handle multiple listeners", function()
            local MockEvent = {
                listeners = {},
                Connect = function(self, callback)
                    table.insert(self.listeners, callback)
                end,
                Fire = function(self, ...)
                    for _, listener in ipairs(self.listeners) do
                        spawn(function()
                            listener(...)
                        end)
                    end
                end
            }

            local count1 = 0
            local count2 = 0

            MockEvent:Connect(function()
                count1 = count1 + 1
            end)

            MockEvent:Connect(function()
                count2 = count2 + 1
            end)

            MockEvent:Fire()
            wait(0.1)

            expect(count1).to.equal(1)
            expect(count2).to.equal(1)
        end)
    end)

    describe("Retry Logic", function()
        it("should retry failed operations", function()
            local attempts = 0
            local maxAttempts = 3

            local function unreliableOperation(callback)
                spawn(function()
                    wait(0.05)
                    attempts = attempts + 1

                    if attempts < maxAttempts then
                        callback(false, "Failed")
                    else
                        callback(true, "Success")
                    end
                end)
            end

            local function retryOperation(operation, maxRetries, callback)
                local currentAttempt = 0

                local function attempt()
                    currentAttempt = currentAttempt + 1

                    operation(function(success, result)
                        if success then
                            callback(true, result, currentAttempt)
                        elseif currentAttempt < maxRetries then
                            spawn(function()
                                wait(0.1)
                                attempt()
                            end)
                        else
                            callback(false, result, currentAttempt)
                        end
                    end)
                end

                attempt()
            end

            local finalSuccess = nil
            local finalAttempts = nil

            retryOperation(unreliableOperation, 3, function(success, result, attemptCount)
                finalSuccess = success
                finalAttempts = attemptCount
            end)

            wait(0.5)

            expect(finalSuccess).to.equal(true)
            expect(finalAttempts).to.equal(3)
        end)
    end)

    describe("Timeout Handling", function()
        it("should timeout slow operations", function()
            local completed = false
            local timedOut = false

            local function slowOperation(callback)
                spawn(function()
                    wait(1)
                    if not timedOut then
                        completed = true
                        callback("done")
                    end
                end)
            end

            local function withTimeout(operation, timeout, callback)
                local finished = false

                -- Start the operation
                operation(function(result)
                    if not finished then
                        finished = true
                        callback(false, result)
                    end
                end)

                -- Start timeout
                spawn(function()
                    wait(timeout)
                    if not finished then
                        finished = true
                        timedOut = true
                        callback(true, "Timeout")
                    end
                end)
            end

            local didTimeout = nil

            withTimeout(slowOperation, 0.2, function(timeout, result)
                didTimeout = timeout
            end)

            wait(0.3)

            expect(didTimeout).to.equal(true)
            expect(completed).to.equal(false)
            expect(timedOut).to.equal(true)
        end)
    end)
end
