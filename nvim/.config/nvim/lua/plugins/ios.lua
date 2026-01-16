-- 1. DETECTION HELPERS
local function is_ios_project()
  local cwd = vim.fn.getcwd()
  local markers = {
    "*.xcodeproj",
    "*.xcworkspace",
    "Project.swift",
    "Package.swift",
  }

  local function has_marker(dir)
    for _, pattern in ipairs(markers) do
      if vim.fn.globpath(dir, pattern) ~= "" or vim.fn.filereadable(dir .. "/" .. pattern) == 1 then
        return true
      end
    end
    return false
  end

  if has_marker(cwd) then return true end

  for dir in vim.fs.parents(cwd) do
    if has_marker(dir) then return true end
  end

  return false
end

local function is_volaris_project()
  return vim.fn.isdirectory(vim.fn.getcwd() .. "/modules/Volaris") == 1
end

local function ensure_xcodebuild_loaded()
  local ok, lazy = pcall(require, "lazy")
  if ok and lazy.load then
    lazy.load({ plugins = { "xcodebuild.nvim" } })
  end
end

local function exec_xcodebuild(cmd)
  ensure_xcodebuild_loaded()
  if vim.fn.exists(":" .. cmd) == 2 then
    return pcall(vim.cmd, cmd)
  end
  return false, "command '" .. cmd .. "' not available after load"
end

-- 2. ENVIRONMENT LOADER
local function get_volaris_env()
  local env_file = vim.fn.getcwd() .. "/.xcode.env"
  local env_vars = {}
  if vim.fn.filereadable(env_file) == 1 then
    local content = vim.fn.readfile(env_file)
    local raw_token = table.concat(content, ""):gsub("%s+", "")
    if #raw_token > 0 then
        env_vars["SIMCTL_CHILD_FIRAAppCheckDebugToken"] = raw_token
        env_vars["FIRAAppCheckDebugToken"] = raw_token
        return env_vars
    end
  end
  return env_vars
end

-- 3. CONFIG READER (Disk-based for safety)
local function get_xcodebuild_config_disk()
  local paths = {
    vim.fn.getcwd() .. "/.nvim/xcodebuild/settings.json",
    vim.fn.getcwd() .. "/.nvim/xcodebuild/config.json"
  }
  for _, path in ipairs(paths) do
    if vim.fn.filereadable(path) == 1 then
       local content = vim.fn.readfile(path)
       local ok_json, json = pcall(vim.json.decode, table.concat(content, ""))
       if ok_json then return json end
    end
  end
  return {}
end

-- 4. DEVICE ID RESOLVER
local function get_device_id()
  -- A. Try in-memory config
  local ok, core_config = pcall(require, "xcodebuild.core.config")
  if ok and core_config.config and core_config.config.device then
      return core_config.config.device.id
  end

  -- B. Try persistent config file
  local config = get_xcodebuild_config_disk()
  if config.device then return config.device end

  -- C. Fallback to first BOOTED simulator
  local handle = io.popen("xcrun simctl list devices | grep '(Booted)' | grep -v 'Unavailable' | head -n 1")
  if handle then
     local line = handle:read("*l")
     handle:close()
     if line then
        local uuid = line:match("%((%w+-%w+-%w+-%w+-%w+)%)")
        if uuid then return uuid end
     end
   end
   
   return nil
 end
 
-- 4b. SYSTEM LLDB FINDER (Fix codelldb "Invalid Argument" on macOS)
local function get_system_lldb_path()
  local function is_file(path)
    return path and vim.fn.filereadable(path) == 1
  end

  local candidates = {
    "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB",
    "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/LLDB",
    "/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/LLDB",
  }

  local dev_root = vim.fn.system("xcode-select -p")
  if vim.v.shell_error == 0 and dev_root and #dev_root > 0 then
    dev_root = vim.fn.trim(dev_root)
    table.insert(candidates, 1, dev_root .. "/../SharedFrameworks/LLDB.framework/Versions/A/LLDB")
    table.insert(candidates, 1, dev_root .. "/../SharedFrameworks/LLDB.framework/LLDB")
  end

  for _, path in ipairs(candidates) do
    if is_file(path) then return path end
  end

  return nil
end

-- 5. GIT IGNORE HELPER
local function ensure_git_ignore_locally(filename)
  local git_dir = vim.fn.finddir(".git", ".;")
  if git_dir ~= "" then
    local exclude_file = git_dir .. "/info/exclude"
    vim.fn.mkdir(vim.fn.fnamemodify(exclude_file, ":h"), "p")
    local lines = {}
    if vim.fn.filereadable(exclude_file) == 1 then
      lines = vim.fn.readfile(exclude_file)
    end
    local found = false
    for _, line in ipairs(lines) do
      if line == filename then found = true break end
    end
    if not found then
      table.insert(lines, filename)
      vim.fn.writefile(lines, exclude_file)
      vim.notify("🙈 Added '" .. filename .. "' to .git/info/exclude", vim.log.levels.INFO)
    end
  end
end

return {
  -- 1. The Engine: xcodebuild.nvim
  {
    "wojciech-kulik/xcodebuild.nvim",
    lazy = false,
    ft = { "swift", "objective-c" },
    cmd = {
      "XcodebuildPicker",
      "XcodebuildBuild",
      "XcodebuildDebug",
      "XcodebuildTest",
      "XcodebuildSelectScheme",
      "XcodebuildSelectDevice",
      "XcodebuildProjectManager",
      "XcodebuildToggleLogs",
    },
    keys = {
      { "<leader>X", desc = "Show Xcodebuild Actions" },
      { "<leader>xb", desc = "Build Project" },
      { "<leader>xr", desc = "Build & Debug" },
      { "<leader>xS", desc = "Stop App" },
      { "<leader>xi", desc = "Initialize LSP" },
      { "<leader>xC", desc = "Check LSP Config" },
      { "<leader>xK", desc = "Check LSP Capabilities" },
    },
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      local xcodebuild = require("xcodebuild")
      
      local ok_setup, setup_err = pcall(xcodebuild.setup, {
        show_build_progress_bar = true,
        restore_on_start = true,
        -- OPTIMIZATION: Disable unused integrations
        integrations = {
            dap = { enabled = true }, 
            xcode_build_server = { enabled = false },
            nvim_tree = { enabled = false },
            neo_tree = { enabled = false },
            oil = { enabled = false },
            diffview = { enabled = false },
            navic = { enabled = false },
        },
        logs = {
          auto_open_on_success_tests = false,
          auto_open_on_failed_tests = true,
          auto_open_on_success_build = false,
          auto_open_on_failed_build = true,
        },
        code_coverage = { enabled = true },
        commands = { extra_build_args = { "-parallelizeTargets" } },
      })
      if not ok_setup then
        vim.notify("❌ xcodebuild.nvim setup failed: " .. tostring(setup_err), vim.log.levels.ERROR)
        return
      end
      local has_dap = pcall(require, "dap")
      local ok_dap, dap_integration = pcall(require, "xcodebuild.integrations.dap")
      if has_dap and ok_dap and dap_integration and dap_integration.setup then
        dap_integration.setup()
      else
        vim.notify("⚠️ xcodebuild.nvim dap integration skipped (nvim-dap missing?). Run :Lazy install nvim-dap", vim.log.levels.WARN)
      end

      -- AUTOCMD: Build -> Debug Handoff
      vim.api.nvim_create_autocmd("User", {
        pattern = "XcodebuildBuildFinished",
        callback = function(event)
          if _G.volaris_debug_queued then
             _G.volaris_debug_queued = false 
             vim.notify("🚀 Build Finished. Triggering Debugger...", vim.log.levels.INFO)
             local dap = require("dap")
             if dap.configurations.swift and dap.configurations.swift[1] then
                 dap.run(dap.configurations.swift[1])
             end
          end
        end,
      })

      -- OPTIMIZATION: Disable Spellcheck for Swift (Clean UI)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "swift", "objective-c" },
        callback = function() vim.opt_local.spell = false end,
      })

      -- KEYMAPS
      vim.keymap.set("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Show Xcodebuild Actions" })
      vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
      
      -- [WORKFLOW] Build & Debug (Robust)
      vim.keymap.set("n", "<leader>xr", function()
          if is_volaris_project() then
            _G.volaris_debug_queued = true
            exec_xcodebuild("XcodebuildBuild")
          else
            local ok, err = exec_xcodebuild("XcodebuildBuildDebug")
            if not ok then
              vim.notify("⚠️ XcodebuildBuildDebug unavailable: " .. tostring(err) .. ". Running build only.", vim.log.levels.WARN)
              exec_xcodebuild("XcodebuildBuild")
            end
          end
      end, { desc = "Build & Debug" })
      
      -- [NEW] Stop App
      vim.keymap.set("n", "<leader>xS", function()
          local device_id = get_device_id()
          if device_id then
              local bundle_id = "com.applaudo.dev.volaris"
              local cmd = string.format("xcrun simctl terminate '%s' '%s'", device_id, bundle_id)
              vim.fn.system(cmd)
              vim.notify("🛑 App Terminated on " .. device_id, vim.log.levels.INFO)
          else
              vim.notify("⚠️ Could not find Device ID to stop app.", vim.log.levels.WARN)
          end
      end, { desc = "Stop App (Simulator)" })

      -- [NEW] Fix LSP (Generate buildServer.json)
      vim.keymap.set("n", "<leader>xi", function()
          if vim.fn.executable("xcode-build-server") == 0 then
              vim.notify("❌ 'xcode-build-server' not found. Run: brew install xcode-build-server", vim.log.levels.ERROR)
              return
          end

          local scheme, project
          local ok, core_config = pcall(require, "xcodebuild.core.config")
          if ok and core_config.config then
              scheme = core_config.config.scheme
              project = core_config.config.projectFile
          end

          if not scheme or not project then
              local disk_config = get_xcodebuild_config_disk()
              scheme = disk_config.scheme
              project = disk_config.projectFile
          end
          
          if scheme and not project then
             local workspaces = vim.fn.glob(vim.fn.getcwd() .. "/*.xcworkspace", false, true)
             if #workspaces > 0 then project = workspaces[1] else
                 local projects = vim.fn.glob(vim.fn.getcwd() .. "/*.xcodeproj", false, true)
                 if #projects > 0 then project = projects[1] end
             end
          end
          
          if not scheme or not project then
              vim.notify("⚠️ No Scheme/Project selected. Please run <leader>xp and <leader>xs first.", vim.log.levels.WARN)
              return
          end
          
          vim.notify("⚙️ Generating buildServer.json for Scheme: " .. scheme .. "...", vim.log.levels.INFO)
          
          local flag = "-project"
          if project:match("%.xcworkspace$") then flag = "-workspace" end
          
          local cmd = string.format("xcode-build-server config -scheme '%s' %s '%s'", scheme, flag, project)
          local output = vim.fn.system(cmd)
          
          if vim.v.shell_error == 0 then
              ensure_git_ignore_locally("buildServer.json")
              ensure_git_ignore_locally(".nvim")
              vim.notify("✅ LSP Configured! Restarting LSP...", vim.log.levels.INFO)
              vim.cmd("LspRestart")
          else
              vim.notify("❌ LSP Setup Failed:\n" .. output, vim.log.levels.ERROR)
          end
      end, { desc = "Fix LSP (Generate buildServer.json)" })

      vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
      vim.keymap.set("n", "<leader>xs", "<cmd>XcodebuildSelectScheme<cr>", { desc = "Select Scheme" })
      vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" })
      vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildProjectManager<cr>", { desc = "Select Project/Workspace" })
      vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Build Logs" })
      
      vim.keymap.set("n", "<leader>xM", function()
        vim.cmd("vsplit | term xcrun simctl spawn booted log stream --level debug --predicate 'process == \"Volaris\"'")
      end, { desc = "Monitor Simulator Logs" })
      
      vim.keymap.set("n", "<leader>xC", function()
          local file = vim.fn.getcwd() .. "/buildServer.json"
          if vim.fn.filereadable(file) == 1 then
              local content = vim.fn.readfile(file)
              local json = vim.json.decode(table.concat(content, ""))
              vim.notify("📄 buildServer.json found!", vim.log.levels.INFO)
              vim.notify("Target: " .. vim.inspect(json), vim.log.levels.INFO)
          else
              vim.notify("❌ buildServer.json NOT found. Run <leader>xi to generate it.", vim.log.levels.ERROR)
          end
      end, { desc = "Check LSP Config" })

      vim.keymap.set("n", "<leader>xK", function()
          local clients = vim.lsp.get_active_clients({ bufnr = 0 })
          for _, client in ipairs(clients) do
              local caps = client.server_capabilities
              vim.notify("🔍 " .. client.name .. ": Def=" .. tostring(caps.definitionProvider) .. " Decl=" .. tostring(caps.declarationProvider), vim.log.levels.INFO)
          end
      end, { desc = "Check LSP Capabilities" })
    end,
  },

  -- 2. The Debugger: nvim-dap + codelldb
  {
    "mfussenegger/nvim-dap",
    ft = { "swift", "objective-c" },
    dependencies = { "mason-org/mason.nvim", "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
    
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>do", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dO", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate Debugger" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle Debug UI" },
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      
      local codelldb_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"
      local ok, registry = pcall(require, "mason-registry")
      if ok and registry.has_package("codelldb") then
         local pkg = registry.get_package("codelldb")
         if pkg and pkg.get_install_path then
            codelldb_path = pkg:get_install_path() .. "/extension/adapter/codelldb"
         end
      end

      -- DETECT SYSTEM LLDB (Corrects "Invalid Argument" crashes)
      local system_lldb = get_system_lldb_path()
      local adapter_args = { "--port", "${port}", "--settings", '{"showDisassembly": "never"}' }
      if system_lldb then
          vim.notify("🍏 Using System LLDB: " .. system_lldb, vim.log.levels.INFO)
          table.insert(adapter_args, "--liblldb")
          table.insert(adapter_args, system_lldb)
      else
          vim.notify("⚠️ System LLDB not found. Using bundled fallback.", vim.log.levels.WARN)
      end

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = codelldb_path,
          args = adapter_args,
        },
      }
      
      -- ROBUST DEBUG CONFIGURATION
      dap.configurations.swift = {
        {
          name = "Debug iOS App (Smart)",
          type = "codelldb",
          request = "attach", 
          processId = function()
             local derived_data = os.getenv("HOME") .. "/Library/Developer/Xcode/DerivedData"
             local handle = io.popen("find " .. derived_data .. " -type d -name '*.app' -mmin -60 -print0 | xargs -0 ls -td | head -n 1")
             local pid = nil
             if handle then
               local found_app = handle:read("*l")
               handle:close()
               if found_app and #found_app > 0 then
                   local binary_name = vim.fn.fnamemodify(found_app, ":t:r")
                   local out = vim.fn.system("pgrep -x " .. binary_name)
                   if vim.v.shell_error == 0 and out then
                       local first_pid = out:match("%d+")
                       if first_pid then pid = tonumber(first_pid) end
                   end
               end
             end
             return pid or require("dap.utils").pick_process()
          end,
          waitFor = false,
          program = function()
             local derived_data = os.getenv("HOME") .. "/Library/Developer/Xcode/DerivedData"
             local handle = io.popen("find " .. derived_data .. " -type d -name '*.app' -mmin -60 -print0 | xargs -0 ls -td | head -n 1")
             if handle then
               local found_app = handle:read("*l")
               handle:close()
               if found_app and #found_app > 0 then
                   local binary_name = vim.fn.fnamemodify(found_app, ":t:r")
                   return found_app .. "/" .. binary_name
               end
             end
             return vim.fn.getcwd() 
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        }
      }
      
      -- [INTERCEPTOR] Manages the "Attach" sequence manually
      local original_dap_run = dap.run
      dap.run = function(config, opts)
         if config.request == "attach" and is_volaris_project() then
             local env_vars = get_volaris_env()
             local token = env_vars["SIMCTL_CHILD_FIRAAppCheckDebugToken"]
             
             if token then
                 local masked = string.sub(token, 1, 6) .. "..."
                 vim.notify("💉 DAP: Launching with Token [" .. masked .. "]", vim.log.levels.INFO)
                 
                 local device_id = get_device_id()
                 if device_id then
                     local bundle_id = "com.applaudo.dev.volaris"
                     local cmd = string.format(
                         "xcrun simctl terminate '%s' '%s' 2>/dev/null; SIMCTL_CHILD_FIRAAppCheckDebugToken='%s' xcrun simctl launch --wait-for-debugger '%s' '%s'", 
                         device_id, bundle_id, token, device_id, bundle_id
                     )
                     
                     local output = vim.fn.system(cmd)
                     if vim.v.shell_error ~= 0 then
                         vim.notify("❌ Launch Error: " .. output, vim.log.levels.ERROR)
                     else
                         local pid = output:match(": (%d+)")
                         if pid then
                             -- INCREASED TIMEOUT to 5 seconds
                             local retries = 50
                             while retries > 0 do
                                 local check = vim.fn.system("ps -p " .. pid)
                                 if check:find(pid) then
                                     vim.notify("✅ App Running (PID: " .. pid .. "). Attaching...", vim.log.levels.INFO)
                                     config.processId = tonumber(pid)
                                     config.pid = tonumber(pid)
                                     config.waitFor = false
                                     break
                                 end
                                 vim.wait(100)
                                 retries = retries - 1
                             end
                             if retries == 0 then
                                vim.notify("❌ DAP Timeout: Process " .. pid .. " not found in ps after 5s", vim.log.levels.ERROR)
                             end
                         end
                     end
                 else
                     vim.notify("⚠️ Device ID not found. Skipping manual launch.", vim.log.levels.WARN)
                 end
             end
         end
         return original_dap_run(config, opts)
      end
      
      vim.keymap.set("n", "<leader>da", function()
          if dap.configurations.swift and dap.configurations.swift[1] then
              dap.run(dap.configurations.swift[1])
          else
              dap.continue()
          end
      end, { desc = "Debug iOS App (Global)" })
    end,
  },

  -- 3. LSP: sourcekit-lsp
  {
    "neovim/nvim-lspconfig",
    -- Always load to ensure opts merge correctly (sourcekit only starts on swift files anyway)
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.sourcekit = {
        cmd = { "xcrun", "sourcekit-lsp" },
        filetypes = { "swift", "objective-c" },
        root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern("buildServer.json", "*.xcodeproj", "*.xcworkspace", ".git")(fname) 
                   or vim.fn.getcwd()
        end,
      }
    end,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "sourcekit" then
            vim.notify("🔗 SourceKit Attached!", vim.log.levels.INFO)
            local opts = { buffer = args.buf, desc = "Go to Definition" }
            vim.keymap.set("n", "gD", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gy", vim.lsp.buf.definition, opts)
          end
        end,
      })
    end,
  },
}
