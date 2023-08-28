--possess a modified buffer to abort `:qa` for:
--* daemon but non-detached processes
--
--some other impl notes:
--* of course it wont stop `:qa!`
--* it wont hurt `:wa`
--* i found no easy way to survive from `:q!`

local M = {}

local dictlib = require("infra.dictlib")
local Ephemeral = require("infra.Ephemeral")
local prefer = require("infra.prefer")

local api = vim.api

local bufnr
do
  bufnr = Ephemeral({ buftype = "acwrite", bufhidden = "hide", name = "barrier://quit" })
  api.nvim_create_autocmd("bufwritecmd", { buffer = bufnr, callback = function() end })
end

local tokens = {}
local count = 0

---@param token string
function M.acquire(token)
  assert(tokens[token] == nil, "no re-entrance")
  tokens[token] = true
  count = count + 1
  prefer.bo(bufnr, "modified", true)
end

---@param token string
function M.release(token)
  assert(tokens[token], "invalid token")
  tokens[token] = nil
  count = count - 1
  assert(count >= 0)
  if count == 0 then prefer.bo(bufnr, "modified", false) end
end

---@return string[]
function M.tokens() return dictlib.keys(tokens) end

return M
