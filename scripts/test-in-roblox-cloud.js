#!/usr/bin/env node

/**
 * rbxcloud-test - Roblox Cloud Testing Tool
 *
 * 直接调用Roblox Open Cloud API执行TestEZ测试
 *
 * Features:
 * - Automatic build and upload of Place files
 * - Test name pattern filtering support
 * - Detailed test results output and log capture
 * - Direct API calls without rbxcloud dependency
 *
 * Usage examples:
 *   rbxcloud-test                    # Run all tests
 *   rbxcloud-test loop               # Run tests containing "loop"
 *   rbxcloud-test --verbose          # Verbose output mode
 *   rbxcloud-test --skip-build       # Skip build step
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const rbxCloud = require('./rbx-cloud-api');

/**
 * Parse command line arguments
 */
function parseArgs() {
  const args = process.argv.slice(2);
  const config = {
    pattern: null,
    verbose: 0,
    help: false,
    version: false,
    rbxl: 'test-place.rbxl',  // Default output file
    jest: false,
    roots: ['ReplicatedStorage'],
    glob: null,
    skipBuild: false,
    timeout: 120000,  // Default 2 minutes (120 seconds)
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === '-h' || arg === '--help') {
      config.help = true;
    } else if (arg === '-v' || arg === '--version') {
      config.version = true;
    } else if (arg === '-V' || arg === '--verbose') {
      config.verbose++;
    } else if (arg === '--skip-build') {
      config.skipBuild = true;
    } else if (arg === '-t' || arg === '--timeout') {
      config.timeout = parseInt(args[++i], 10) * 1000;  // Convert seconds to milliseconds
    } else if (arg === '-r' || arg === '--rbxl') {
      config.rbxl = args[++i];
    } else if (arg === '-j' || arg === '--jest') {
      config.jest = true;
    } else if (arg === '--roots') {
      config.roots = args[++i].split('/');
    } else if (arg === '--glob') {
      config.glob = args[++i];
    } else if (!arg.startsWith('-')) {
      // First non-option argument is the pattern
      if (!config.pattern) {
        config.pattern = arg;
      }
    }
  }

  return config;
}

/**
 * Show help information
 */
function showHelp() {
  console.log(`
rbxcloud-test - Roblox Cloud Testing Tool

Usage:
  rbxcloud-test [pattern] [options]

Arguments:
  <pattern>           Test name filter pattern (matches test files containing this string)

Options:
  -V, --verbose       Verbose output (can be specified multiple times for more detail)
  -h, --help          Show this help message
  -v, --version       Show version information
  -t, --timeout <sec> Task execution timeout in seconds (default: 120)
  -r, --rbxl <path>   Specify rbxl file path to upload (default: test-place.rbxl)
  -j, --jest          Use jest instead of testez (default: testez)
      --roots <path>  Test root paths, separated by / (default: ReplicatedStorage)
      --glob <match>  Match test files in roots
      --skip-build    Skip the Rojo build step

Examples:
  rbxcloud-test                    # Run all tests
  rbxcloud-test loop               # Run only tests containing "loop"
  rbxcloud-test --verbose          # Verbose output mode
  rbxcloud-test --skip-build       # Skip build, upload and test directly
  rbxcloud-test "should allow" -V  # Run specific test with verbose logging

Environment Variables (in .env.roblox):
  ROBLOX_API_KEY         Roblox Open Cloud API Key (required)
  UNIVERSE_ID            Universe ID (required)
  TEST_PLACE_ID          Test Place ID (required)

  Legacy names (still supported):
  RBXCLOUD_API_KEY       Old name for API Key
  RBXCLOUD_UNIVERSE_ID   Old name for Universe ID
  RBXCLOUD_PLACE_ID      Old name for Place ID

Note: Environment variables are automatically loaded from .env.roblox
`);
}

/**
 * Show version information
 */
function showVersion() {
  const packageJson = require('../package.json');
  console.log(`rbxcloud-test v${packageJson.version}`);
}

/**
 * Colored logging utilities
 */
const log = {
  info: (msg) => console.log(`\x1b[36m\u2139\x1b[0m ${msg}`),
  success: (msg) => console.log(`\x1b[32m\u2713\x1b[0m ${msg}`),
  error: (msg) => console.error(`\x1b[31m\u2717\x1b[0m ${msg}`),
  warn: (msg) => console.warn(`\x1b[33m\u26A0\x1b[0m ${msg}`),
  step: (msg) => console.log(`\n\x1b[1m\u25B6 ${msg}\x1b[0m`),
  debug: (msg, verbose) => {
    if (verbose > 0) console.log(`\x1b[90m[DEBUG]\x1b[0m ${msg}`);
  },
};

/**
 * Execute command and return Promise
 */
function runCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    const verbose = options.verbose || 0;

    if (verbose > 0) {
      log.debug(`Executing: ${command} ${args.join(' ')}`, verbose);
    }

    const proc = spawn(command, args, {
      stdio: verbose > 1 ? 'inherit' : 'pipe',
      shell: true,
      ...options,
    });

    let stdout = '';
    let stderr = '';

    if (verbose <= 1) {
      proc.stdout?.on('data', (data) => {
        stdout += data.toString();
      });

      proc.stderr?.on('data', (data) => {
        stderr += data.toString();
      });
    }

    proc.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr, code });
      } else {
        const error = new Error(`Command failed with exit code ${code}`);
        error.stdout = stdout;
        error.stderr = stderr;
        error.code = code;
        reject(error);
      }
    });

    proc.on('error', reject);
  });
}

/**
 * Validate environment variables
 */
async function validateEnvironment() {
  // 支持新旧两种环境变量名
  const apiKey = process.env.ROBLOX_API_KEY || process.env.RBXCLOUD_API_KEY;
  const universeId = process.env.UNIVERSE_ID || process.env.RBXCLOUD_UNIVERSE_ID;
  const placeId = process.env.TEST_PLACE_ID || process.env.RBXCLOUD_PLACE_ID;

  const missing = [];
  if (!apiKey) missing.push('ROBLOX_API_KEY (or RBXCLOUD_API_KEY)');
  if (!universeId) missing.push('UNIVERSE_ID (or RBXCLOUD_UNIVERSE_ID)');
  if (!placeId) missing.push('TEST_PLACE_ID (or RBXCLOUD_PLACE_ID)');

  if (missing.length > 0) {
    log.error(`Missing required environment variables in .env.roblox: ${missing.join(', ')}`);
    throw new Error(`Missing environment variables: ${missing.join(', ')}`);
  }
}

/**
 * Step 1: Build Place with Rojo
 */
async function buildPlace(config) {
  if (config.skipBuild) {
    log.warn('Skipping Rojo build (--skip-build)');
    return;
  }

  log.step('Step 1/4: Building Place file with Rojo');

  const projectFile = 'default.project.json';

  if (!fs.existsSync(projectFile)) {
    throw new Error(`Rojo project file not found: ${projectFile}`);
  }

  log.info(`Project file: ${projectFile}`);
  log.info(`Output file: ${config.rbxl}`);

  try {
    await runCommand('rojo', ['build', projectFile, '-o', config.rbxl], {
      verbose: config.verbose,
    });

    const stats = fs.statSync(config.rbxl);
    log.success(`Build complete (${(stats.size / 1024 / 1024).toFixed(2)} MB)`);
  } catch (error) {
    log.error(`Build failed: ${error.message}`);
    if (error.stderr) {
      console.error(error.stderr);
    }
    throw error;
  }
}

/**
 * Step 2: Upload Place to Roblox Cloud
 */
async function uploadPlace(config) {
  log.step('Step 2/4: Uploading Place to Roblox Cloud');

  if (!fs.existsSync(config.rbxl)) {
    throw new Error(`Build file not found: ${config.rbxl}`);
  }

  const stats = fs.statSync(config.rbxl);
  log.info(`File: ${config.rbxl} (${(stats.size / 1024 / 1024).toFixed(2)} MB)`);

  try {
    const result = await rbxCloud.publishPlace(config.rbxl, 'Saved');

    if (config.verbose > 0) {
      log.debug(`Upload response: ${JSON.stringify(result)}`, config.verbose);
    }

    log.success('Upload complete');
    return result.versionNumber;
  } catch (error) {
    log.error(`Upload failed: ${error.message}`);
    throw error;
  }
}

/**
 * Step 3: Execute tests
 */
async function runTests(config, versionId) {
  log.step('Step 3/4: Executing tests in Roblox Cloud');

  // Read test script
  const testScriptPath = path.join(__dirname, 'cloud-test.lua');
  if (!fs.existsSync(testScriptPath)) {
    throw new Error(`Test script not found: ${testScriptPath}`);
  }

  let testScript = fs.readFileSync(testScriptPath, 'utf-8');

  // Replace pattern placeholder
  testScript = testScript.replace('{{TEST_NAME_PATTERN}}', config.pattern || '');

  if (config.pattern) {
    log.info(`Test filter: ${config.pattern}`);
  } else {
    log.info('Running all tests');
  }

  try {
    // Execute script using API
    const response = await rbxCloud.executeLuau(testScript, versionId);

    if (config.verbose > 0) {
      log.debug(`Execute response: ${JSON.stringify(response)}`, config.verbose);
    }

    // Extract version-id, session-id and task-id from path
    const { versionId: taskVersionId, sessionId, taskId } = rbxCloud.parseTaskPath(response.path);

    if (config.verbose > 0) {
      log.debug(`Version ID: ${taskVersionId}, Session ID: ${sessionId}, Task ID: ${taskId}`, config.verbose);
    }

    log.info(`Task submitted: ${taskId.substring(0, 8)}...`);
    log.info('Waiting for execution to complete...');

    // Poll for task completion
    const result = await rbxCloud.pollTaskUntilComplete(taskVersionId, sessionId, taskId, {
      timeout: config.timeout, // 可配置的超时时间
      onProgress: (state, attempt, maxAttempts, elapsed) => {
        const elapsedSec = elapsed ? `${(elapsed / 1000).toFixed(1)}s` : '';
        process.stdout.write(`\rStatus: ${state} (${attempt}/${maxAttempts}) ${elapsedSec}...`);
      }
    });

    console.log(''); // New line after progress

    if (result.success) {
      log.success('Execution complete');
      return result.result;
    } else {
      throw new Error(`Task failed: ${JSON.stringify(result.taskInfo)}`);
    }
  } catch (error) {
    log.error(`Test execution failed: ${error.message}`);
    throw error;
  }
}

/**
 * Filter TestEZ internal stack trace lines
 * 过滤掉所有 TestEZ 包内部的代码堆栈
 */
function filterStackTrace(trace) {
  if (!trace) return trace;

  return trace
    .split('\n')
    .filter(line => {
      // 过滤掉 TestEZ 包内部的所有代码
      // TypeScript: node_modules.@rbxts.testez.src
      // Lua: Packages._Index.roblox_testez
      return !line.includes('node_modules.@rbxts.testez.src') &&
             !line.includes('Packages._Index.roblox_testez');
    })
    .join('\n');
}

/**
 * Step 4: Parse and display test results
 */
function displayResults(output, config) {
  log.step('Step 4/4: Test Results');

  let parsedResults;
  try {
    // Output is already the results JSON string from task output
    parsedResults = JSON.parse(output);
  } catch (e) {
    log.error(`Failed to parse results: ${e.message}`);
    console.log('\nRaw output:');
    console.log(output);
    throw e;
  }

  console.log('\n=======================================');
  console.log('           Test Results Summary');
  console.log('=======================================');

  const passRate = parsedResults.totalTests > 0
    ? ((parsedResults.passed / parsedResults.totalTests) * 100).toFixed(2)
    : 0;

  console.log(`Status: ${parsedResults.success ? '\x1b[32m\u2713 PASSED\x1b[0m' : '\x1b[31m\u2717 FAILED\x1b[0m'}`);
  console.log(`Total: ${parsedResults.totalTests || 0}`);
  console.log(`Passed: \x1b[32m${parsedResults.passed || 0}\x1b[0m`);
  console.log(`Failed: \x1b[31m${parsedResults.failed || 0}\x1b[0m`);
  console.log(`Skipped: \x1b[33m${parsedResults.skipped || 0}\x1b[0m`);
  console.log(`Pass rate: ${passRate}%`);
  console.log('=======================================');

  // Display error details
  if (parsedResults.errors && parsedResults.errors.length > 0) {
    console.log('\n\x1b[31mError Details:\x1b[0m\n');
    parsedResults.errors.forEach((error, index) => {
      console.log(`\x1b[31mError ${index + 1}: ${error.testName || 'Unknown'}\x1b[0m`);
      console.log(error.message);
      if (error.trace) {
        const filteredTrace = filterStackTrace(error.trace);
        if (filteredTrace.trim()) {  // Only show if there's content after filtering
          console.log('\x1b[90mStack trace:\x1b[0m');
          console.log(filteredTrace);
        }
      }
      console.log('');
    });
  }

  // Display captured test logs
  if (parsedResults.logs && parsedResults.logs.length > 0) {
    console.log('\n\x1b[36mTest Execution Logs:\x1b[0m\n');
    parsedResults.logs.forEach(logLine => {
      console.log(logLine);
    });
  }

  // Display captured print messages
  if (parsedResults.printMessages && parsedResults.printMessages.length > 0 && config.verbose > 0) {
    console.log('\n\x1b[36mCaptured Output:\x1b[0m\n');
    parsedResults.printMessages.forEach(msg => {
      const typeColor = msg.type === 'print' ? '\x1b[37m' : '\x1b[33m';
      console.log(`${typeColor}[${msg.type}]\x1b[0m ${msg.message}`);
    });
    console.log('');
  }

  // Filter stack traces in errors before saving
  if (parsedResults.errors && parsedResults.errors.length > 0) {
    parsedResults.errors = parsedResults.errors.map(error => ({
      ...error,
      trace: filterStackTrace(error.trace)
    }));
  }

  // Save results to file
  saveResults(parsedResults);

  return parsedResults;
}

/**
 * Save test results to file
 */
function saveResults(results) {
  const testResultDir = path.join(process.cwd(), '.test-result');
  if (!fs.existsSync(testResultDir)) {
    fs.mkdirSync(testResultDir, { recursive: true });
  }

  // Clean up old results (keep last 2)
  try {
    const files = fs.readdirSync(testResultDir)
      .filter(file => file.endsWith('.yaml') || file.endsWith('.yml'))
      .map(file => ({
        name: file,
        path: path.join(testResultDir, file),
        time: fs.statSync(path.join(testResultDir, file)).mtime.getTime()
      }))
      .sort((a, b) => b.time - a.time);

    if (files.length > 1) {
      files.slice(2).forEach(file => fs.unlinkSync(file.path));
    }
  } catch (e) {
    // Ignore cleanup errors
  }

  // Save new results in YAML format with sections separated by blank lines
  const dateString = new Date().toISOString().replace(/:/g, '-').replace(/\..+/, '');
  const resultsPath = path.join(testResultDir, `${dateString}.yaml`);

  const yamlOptions = {
    lineWidth: -1,  // Don't wrap lines
    noRefs: true,   // Don't use anchors/references
    styles: {
      '!!null': 'empty'  // Represent null as empty
    }
  };

  // Build YAML in sections with blank lines between them
  const sections = [];

  // Section 1: Metadata
  sections.push(yaml.dump({
    timestamp: new Date().toISOString(),
    important: "Results from Roblox Cloud test execution. read stacktrace files in out/ (roblox-ts generation)"
  }, yamlOptions).trim());

  // Section 2: Test Summary
  sections.push(yaml.dump({
    success: results.success,
    totalTests: results.totalTests,
    passed: results.passed,
    failed: results.failed,
    skipped: results.skipped
  }, yamlOptions).trim());

  // Section 3: Errors (if any)
  if (results.errors && results.errors.length > 0) {
    sections.push(yaml.dump({
      errors: results.errors
    }, yamlOptions).trim());
  }

  // Section 4: Print Messages (if any)
  if (results.printMessages && results.printMessages.length > 0) {
    sections.push(yaml.dump({
      printMessages: results.printMessages
    }, yamlOptions).trim());
  }

  // Join sections with blank lines
  const yamlContent = sections.join('\n\n');

  fs.writeFileSync(resultsPath, yamlContent, 'utf-8');
  console.log(`\n\u{1F4DD} Full results saved to: ${resultsPath}\n`);
}

/**
 * Main function
 */
async function main() {
  const config = parseArgs();

  // Handle help and version
  if (config.help) {
    showHelp();
    process.exit(0);
  }

  if (config.version) {
    showVersion();
    process.exit(0);
  }

  console.log('\x1b[1m\n\u{1F680} Roblox Cloud Testing Tool\x1b[0m');
  console.log('=======================================\n');

  if (config.pattern) {
    log.info(`Test filter: "${config.pattern}"`);
  }
  if (config.verbose > 0) {
    log.info(`Verbose level: ${config.verbose}`);
  }

  const startTime = Date.now();

  try {
    // Validate environment
    await validateEnvironment();

    // Execute test workflow
    await buildPlace(config);
    const versionNumber = await uploadPlace(config);
    const output = await runTests(config, versionNumber);
    const results = displayResults(output, config);

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`\n\u{23F1}  Total time: ${duration}s\n`);

    // Set exit code based on test results
    process.exit(results.success ? 0 : 1);

  } catch (error) {
    log.error(`Execution failed: ${error.message}`);

    if (config.verbose > 0 && error.stack) {
      console.error('\nStack trace:');
      console.error(error.stack);
    }

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`\n\u{23F1}  Total time: ${duration}s\n`);

    process.exit(1);
  }
}

// Run main function
if (require.main === module) {
  main();
}

module.exports = { parseArgs, runCommand, displayResults };
