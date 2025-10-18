-- ServerUtils - 服务器端工具函数
local ServerUtils = {}

-- 验证玩家权限
function ServerUtils.hasPermission(userId, permissionLevel)
	if typeof(userId) ~= "number" or userId <= 0 then
		return false
	end

	if permissionLevel == "admin" then
		-- 简化的管理员检查（实际项目中应该查询数据库）
		return userId == 1 or userId == 2
	elseif permissionLevel == "moderator" then
		return userId <= 10
	else
		return true -- 默认权限
	end
end

-- 获取服务器时间戳
function ServerUtils.getServerTimestamp()
	return os.time()
end

-- 验证数据完整性
function ServerUtils.validateData(data)
	if typeof(data) ~= "table" then
		return false, "Data must be a table"
	end

	if not data.userId or typeof(data.userId) ~= "number" then
		return false, "Missing or invalid userId"
	end

	if not data.action or typeof(data.action) ~= "string" then
		return false, "Missing or invalid action"
	end

	return true, "Data is valid"
end

-- 计算玩家等级
function ServerUtils.calculateLevel(experience)
	if typeof(experience) ~= "number" or experience < 0 then
		return 1
	end

	-- 简单的等级计算公式：每1000经验一级
	return math.floor(experience / 1000) + 1
end

return ServerUtils
