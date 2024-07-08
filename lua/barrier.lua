--possess a modified buffer to abort `:qa` for:
--* daemon but non-detached processes
--
--some impl notes:
--* of course it wont stop `:qa!`, `:%bw!`
--* it wont hurt `:wa`
--* it stops `:q!`

local M = {}

local augroups = require("infra.augroups")
local buflines = require("infra.buflines")
local ctx = require("infra.ctx")
local Ephemeral = require("infra.Ephemeral")
local ni = require("infra.ni")
local prefer = require("infra.prefer")

---@type {[string]: true}
local tokens = {}
local count = 0

local barrier = {}
do
  ---@private
  barrier.bufnr = nil

  local function get_lines()
    local lines = { "barriers:" }
    for token in pairs(tokens) do
      table.insert(lines, "* " .. token)
    end
    if #lines == 1 then return {} end
    return lines
  end

  function barrier.refresh()
    ctx.modifiable(barrier.bufnr, function() buflines.replaces_all(barrier.bufnr, get_lines()) end)
    prefer.bo(barrier.bufnr, "modified", count > 0)
  end

  local function protect_the_buf()
    barrier.bufnr = Ephemeral({ buftype = "acwrite", bufhidden = "hide", name = "barrier://quit" }, get_lines())

    local aug = augroups.BufAugroup(barrier.bufnr, "infra.barrier", false)
    aug:repeats("BufWriteCmd", { callback = function() end })
    --workaround for `:q!`
    aug:once("BufUnload", {
      nested = true,
      callback = function()
        vim.schedule(function() ni.buf_delete(barrier.bufnr, { force = true }) end)
      end,
    })
    --workaround for `:bw!`
    aug:once("BufWipeout", {
      callback = function()
        aug:unlink()
        vim.schedule(protect_the_buf)
      end,
    })
  end

  protect_the_buf()
end

---@param token string
function M.acquire(token)
  assert(tokens[token] == nil, "no re-entrance")
  tokens[token] = true
  count = count + 1

  barrier.refresh()
end

---@param token string
function M.release(token)
  assert(tokens[token], "not an acquired token")
  tokens[token] = nil
  count = count - 1

  barrier.refresh()
end

return M
