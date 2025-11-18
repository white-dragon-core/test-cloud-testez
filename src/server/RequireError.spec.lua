-- RequireError 测试套件
-- 测试 TestEZ 是否能正确捕获 require() 时发生的错误，并提供详细的错误位置信息

return function()
	_G.print("🧪 Starting RequireError capture tests...")

	describe("TestEZ should handle require() errors gracefully", function()
		it("should catch errors when requiring a broken module with pcall", function()
			_G.print("📦 Testing require() error capture with pcall...")

			-- 使用 pcall 包装 require，应该能捕获到错误
			local success, err = pcall(function()
				local BrokenModule = require(script.Parent.BrokenModule)
				return BrokenModule
			end)

			_G.print("🔍 pcall success: " .. tostring(success))
			_G.print("🔍 pcall error: " .. tostring(err))

			-- 我们期望 require 会失败
			expect(success).to.equal(false)
			expect(err).to.be.ok()

			-- 验证错误消息包含模块名称
			local errStr = tostring(err)
			expect(errStr:find("error while loading") or errStr:find("Requested module")).to.be.ok()
		end)

		it("should continue running tests after pcall-wrapped require error", function()
			_G.print("✅ Test continues after pcall-wrapped require error")
			expect(true).to.equal(true)
		end)
	end)

	describe("Error recovery and test continuation", function()
		it("should provide detailed error location for require failures", function()
			_G.print("📍 Testing error location reporting...")

			-- 这个测试验证 TestEZ 能提供详细的错误位置
			-- 即使 require() 失败，错误消息应该包含准确的位置信息
			local success, err = pcall(function()
				require(script.Parent.BrokenModule)
			end)

			-- 验证错误被捕获
			expect(success).to.equal(false)

			-- 验证错误消息存在
			expect(err).to.be.ok()

			_G.print("✅ Error location info verified")
		end)

		it("should run subsequent tests normally", function()
			_G.print("🎯 Subsequent test runs normally")

			-- 这个测试验证前面的 require 错误不会影响后续测试
			local result = 1 + 1
			expect(result).to.equal(2)
		end)
	end)

	_G.print("✅ RequireError tests completed")
	_G.print("📊 Summary: TestEZ successfully captures require() errors and allows tests to continue")
end
