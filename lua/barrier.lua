--possess a modified buffer to abort `:qa` for:
--* daemon but non-detached processes
--
--and of course it wont stop `:qa!`

local M = {}

local bufrename = require("infra.bufrename")
local dictlib = require("infra.dictlib")
local Ephemeral = require("infra.Ephemeral")
local prefer = require("infra.prefer")

local bufnr
do
  bufnr = Ephemeral({ buftype = "" })
  bufrename(bufnr, "barrier://quit")
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
