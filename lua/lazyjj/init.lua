-- File: lua/lazyjj/init.lua

local M = {}

local function open_floating_window()
	-- Get plenary's float window module which handles window creation
	local plenary = require("plenary.window.float")

	-- Create centered floating window at 90% of screen size with rounded borders
	local win = plenary.percentage_range_window(0.9, 0.8, {
		border = {
			"╭",
			"─",
			"╮",
			"│",
			"│",
			"╰",
			"─",
			"╯",
		},
	})

	-- Set buffer filetype for syntax highlighting
	vim.bo[win.bufnr].filetype = "lazyjj"

	-- Ensure window is completely opaque
	vim.wo[win.win_id].winblend = 0

	-- Hide buffer when window closes rather than delete it
	vim.cmd("setlocal bufhidden=hide")

	-- Automatically hide window when focus is lost
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = win.bufnr,
		callback = function()
			vim.cmd("hide")
		end,
		once = true,
	})

	-- Return window and buffer handles for further manipulation if needed
	return win.win_id, win.bufnr
end

function M.setup(opts)
	-- Store user config for later use
	M.config = vim.tbl_deep_extend("force", {
		-- Default configuration options can go here
		mapping = "<leader>jj", -- Default keymapping
	}, opts or {})

	-- Create user commands
	vim.api.nvim_create_user_command("LazyJJ", function()
		M.open()
	end, {})
	vim.api.nvim_create_user_command("LazyJJCwd", function()
		M.open({ cwd = vim.fn.getcwd() })
	end, {})

	-- Set up keymapping if provided
	if M.config.mapping then
		vim.keymap.set("n", M.config.mapping, M.open, {
			noremap = true,
			silent = true,
			desc = "LazyJJ", -- This will work with WhichKey and similar plugins
		})
	end
end

--- Open lazyjj in a floating terminal window.
--- @param opts table|nil Optional table with:
---   - `cwd` (string): directory to launch lazyjj in.
---     Defaults to Neovim's current working directory.
function M.open(opts)
	opts = opts or {}

	-- Store current window ID for late    -- Check if lazyjj is available
	local cmd = "lazyjj"
	if vim.fn.executable(cmd) ~= 1 then
		vim.notify(
			"lazyjj executable not found. Please install lazyjj and ensure it's in your PATH.",
			vim.log.levels.ERROR
		)
		return
	end

	local prev_win = vim.api.nvim_get_current_win()

	-- Create floating window
	open_floating_window()

	-- Execute lazyjj in the floating window
	vim.fn.termopen(cmd, {
		cwd = opts.cwd, -- nil falls back to Neovim's cwd
		-- Return to previous window on exit
		on_exit = function()
			if vim.api.nvim_win_is_valid(prev_win) then
				vim.api.nvim_set_current_win(prev_win)
			end
		end,
		-- Handle potential errors
		on_stderr = function(_, data)
			for _, line in ipairs(data) do
				if line:match("^Error:.*") then
					vim.notify("lazyjj error: " .. line, vim.log.levels.ERROR)
				end
			end
		end,
	})

	-- Enter insert mode to allow immediate interaction
	vim.cmd("startinsert")
end

return M
