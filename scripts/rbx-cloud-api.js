/**
 * Roblox Cloud API Module
 *
 * 直接调用Roblox Open Cloud API，不依赖rbxcloud工具
 */

const https = require('https');
const fs = require('fs');
const path = require('path');
const { HttpsProxyAgent } = require('https-proxy-agent');

// 使用 dotenv 加载环境变量（静默模式）
// 优先级：.env > .env.roblox（先加载 .env.roblox 作为默认值，再加载 .env 覆盖）
require('dotenv').config({
  path: path.join(process.cwd(), '.env.roblox'),
  debug: false  // 关闭调试输出
});
// .env 文件可以覆盖 .env.roblox 中的配置（用于本地开发）
require('dotenv').config({
  path: path.join(process.cwd(), '.env'),
  debug: false,
  override: true  // 覆盖 .env.roblox 中的变量
});

// 创建代理 agent（如果设置了环境变量）
const proxyUrl = process.env.HTTPS_PROXY || process.env.HTTP_PROXY;
const proxyAgent = proxyUrl ? new HttpsProxyAgent(proxyUrl) : undefined;

// 输出代理配置信息（仅在设置了代理时）
if (proxyAgent) {
  console.log(`🌐 使用代理: ${proxyUrl}`);
}

/**
 * 通用HTTPS请求函数
 */
function httpsRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    // 如果有代理，添加 agent 选项
    const requestOptions = {
      ...options,
      agent: proxyAgent
    };

    // 输出请求信息（如果使用代理）
    if (proxyAgent) {
      const urlObj = new URL(url);
      console.log(`📡 [代理请求] ${options.method || 'GET'} ${urlObj.hostname}${urlObj.pathname}`);
      console.log(`   通过代理: ${proxyUrl}`);
    }

    const startTime = Date.now();
    const req = https.request(url, requestOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const elapsed = Date.now() - startTime;
        if (proxyAgent) {
          console.log(`✅ [代理响应] HTTP ${res.statusCode} (耗时: ${elapsed}ms)`);
        }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({
            statusCode: res.statusCode,
            body: data,
            headers: res.headers
          });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', (err) => {
      const elapsed = Date.now() - startTime;
      if (proxyAgent) {
        console.log(`❌ [代理错误] ${err.message} (耗时: ${elapsed}ms)`);
      }
      reject(err);
    });

    if (options.body) {
      req.write(options.body);
    }

    req.end();
  });
}

/**
 * 上传Place文件到Roblox Cloud
 */
async function publishPlace(rbxlPath, versionType = 'Saved') {
  // 支持新旧两种环境变量名，优先使用新名称
  const universeId = process.env.UNIVERSE_ID || process.env.RBXCLOUD_UNIVERSE_ID;
  const placeId = process.env.TEST_PLACE_ID || process.env.RBXCLOUD_PLACE_ID;
  const apiKey = process.env.ROBLOX_API_KEY || process.env.RBXCLOUD_API_KEY;

  if (!universeId || !placeId || !apiKey) {
    throw new Error('Missing required environment variables: UNIVERSE_ID/RBXCLOUD_UNIVERSE_ID, TEST_PLACE_ID/RBXCLOUD_PLACE_ID, ROBLOX_API_KEY/RBXCLOUD_API_KEY');
  }

  const fileData = fs.readFileSync(rbxlPath);
  const url = `https://apis.roblox.com/universes/v1/${universeId}/places/${placeId}/versions?versionType=${versionType}`;

  const result = await httpsRequest(url, {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'Content-Type': 'application/octet-stream',
      'Content-Length': fileData.length
    },
    body: fileData
  });

  return JSON.parse(result.body);
}

/**
 * 执行Luau脚本
 * @param {string} script - Luau脚本内容
 * @param {number|null} versionId - Place版本ID（可选）
 * @param {object} options - 执行选项
 * @param {number} options.timeoutSeconds - 脚本超时时间（秒），范围1-300，默认300（5分钟）
 */
async function executeLuau(script, versionId = null, options = {}) {
  // 支持新旧两种环境变量名，优先使用新名称
  const universeId = process.env.UNIVERSE_ID || process.env.RBXCLOUD_UNIVERSE_ID;
  const placeId = process.env.TEST_PLACE_ID || process.env.RBXCLOUD_PLACE_ID;
  const apiKey = process.env.ROBLOX_API_KEY || process.env.RBXCLOUD_API_KEY;

  if (!universeId || !placeId || !apiKey) {
    throw new Error('Missing required environment variables');
  }

  let url;
  if (versionId) {
    url = `https://apis.roblox.com/cloud/v2/universes/${universeId}/places/${placeId}/versions/${versionId}/luau-execution-session-tasks`;
  } else {
    url = `https://apis.roblox.com/cloud/v2/universes/${universeId}/places/${placeId}/luau-execution-session-tasks`;
  }

  // 构建请求体，包含可选的timeout参数
  const requestBody = { script };

  if (options.timeoutSeconds) {
    // 验证超时范围（1-300秒）
    const timeout = Math.max(1, Math.min(300, options.timeoutSeconds));
    requestBody.timeout = `${timeout}s`;
  }

  const body = JSON.stringify(requestBody);

  const result = await httpsRequest(url, {
    method: 'POST',
    headers: {
      'x-api-key': apiKey,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body)
    },
    body
  });

  return JSON.parse(result.body);
}

/**
 * 获取任务状态
 */
async function getTask(versionId, sessionId, taskId) {
  // 支持新旧两种环境变量名，优先使用新名称
  const universeId = process.env.UNIVERSE_ID || process.env.RBXCLOUD_UNIVERSE_ID;
  const placeId = process.env.TEST_PLACE_ID || process.env.RBXCLOUD_PLACE_ID;
  const apiKey = process.env.ROBLOX_API_KEY || process.env.RBXCLOUD_API_KEY;

  const url = `https://apis.roblox.com/cloud/v2/universes/${universeId}/places/${placeId}/versions/${versionId}/luau-execution-sessions/${sessionId}/tasks/${taskId}`;

  const result = await httpsRequest(url, {
    method: 'GET',
    headers: {
      'x-api-key': apiKey
    }
  });

  return JSON.parse(result.body);
}

/**
 * 轮询任务直到完成
 */
async function pollTaskUntilComplete(versionId, sessionId, taskId, options = {}) {
  const maxAttempts = options.maxAttempts || 60;
  const pollInterval = options.pollInterval || 3000;
  const initialDelay = options.initialDelay || 5000;
  const timeout = options.timeout || 60000; // 默认60秒超时
  const onProgress = options.onProgress || (() => {});

  const startTime = Date.now();

  // 初始等待
  await new Promise(resolve => setTimeout(resolve, initialDelay));

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    // 检查超时
    const elapsed = Date.now() - startTime;
    if (elapsed >= timeout) {
      throw new Error(`Task execution timeout after ${(elapsed / 1000).toFixed(1)}s (limit: ${timeout / 1000}s)`);
    }

    try {
      const taskInfo = await getTask(versionId, sessionId, taskId);

      onProgress(taskInfo.state, attempt + 1, maxAttempts, elapsed);

      if (taskInfo.state === 'COMPLETE') {
        if (taskInfo.output && taskInfo.output.results && taskInfo.output.results.length > 0) {
          return {
            success: true,
            result: taskInfo.output.results[0],
            taskInfo
          };
        } else {
          throw new Error('No results in task output');
        }
      } else if (taskInfo.state === 'FAILED') {
        return {
          success: false,
          error: taskInfo.error,
          taskInfo
        };
      }
    } catch (error) {
      // 如果是超时错误，直接抛出
      if (error.message.includes('timeout')) {
        throw error;
      }
      if (attempt === maxAttempts - 1) {
        throw error;
      }
      // 继续轮询
      onProgress('PROCESSING', attempt + 1, maxAttempts, elapsed);
    }

    await new Promise(resolve => setTimeout(resolve, pollInterval));
  }

  throw new Error('Task completion timeout (max attempts reached)');
}

/**
 * 从路径中提取IDs
 */
function parseTaskPath(path) {
  const parts = path.split('/');
  const versionsIndex = parts.indexOf('versions');
  const sessionsIndex = parts.indexOf('luau-execution-sessions');
  const tasksIndex = parts.indexOf('tasks');

  return {
    versionId: parts[versionsIndex + 1],
    sessionId: parts[sessionsIndex + 1],
    taskId: parts[tasksIndex + 1]
  };
}

module.exports = {
  publishPlace,
  executeLuau,
  getTask,
  pollTaskUntilComplete,
  parseTaskPath
};
