--- Advanced: Library: real player data of a character or card.
local M = {}

local Faces = VRFW.faces

local GENDER_MALE, GENDER_FEMALE = 1, 2      -- chara_gender values of a person

local u32 = VRFW.ids.unsigned

local function has_text(v)
  return type(v) == "string" and v ~= ""
end

local Columns = VRFW.table_files

local D = nil
local ANSWER = {}      -- character id -> { real, reason }

local function tables()
  if D ~= nil then return D end
  local base_rows, b = Columns.read("character/chara_base", "CHARA_BASE_INFO", { "id", "model", "gender", "description_text" })
  local model_rows, m = Columns.read("character/chara_model", "CHARA_MODEL_INFO", { "id", "clothes", "body" })
  local body_rows, y = Columns.read("character/chara_body", "CHARA_BODY_INFO", { "id", "body_mesh_path" })
  if not (base_rows and model_rows and body_rows) then
    D = false
    return D
  end
  local base, profile, model, body = {}, {}, {}, {}
  for _, r in ipairs(base_rows) do
    local id = u32(r[b.id])
    if id ~= 0 and base[id] == nil then
      base[id] = u32(r[b.model])
      local gender = math.floor(tonumber(r[b.gender]) or 0)
      if u32(r[b.description_text]) ~= 0 or gender == GENDER_MALE or gender == GENDER_FEMALE then profile[id] = true end
    end
  end
  for _, r in ipairs(model_rows) do
    local id = u32(r[m.id])
    if id ~= 0 and model[id] == nil then model[id] = u32(r[m.clothes]) ~= 0 and -1 or u32(r[m.body]) end
  end
  for _, r in ipairs(body_rows) do
    local id = u32(r[y.id])
    if id ~= 0 and body[id] == nil then body[id] = has_text(r[y.body_mesh_path]) end
  end
  D = { base = base, profile = profile, model = model, body = body }
  return D
end

-- a model id -> true = it can wear a kit or has clothes of its own, false = neither, nil = cannot tell
local function player_body(model_id)
  if model_id == 0 then return nil end
  local m = D.model[model_id]
  if m == nil then return nil end
  if m == -1 then return true end
  if m == 0 then return false end
  return D.body[m]
end

--- Advanced: a character (chara_base id) -> true / false (+ reason) / nil
function M.of_character(base)
  base = u32(base)
  local a = ANSWER[base]
  if a ~= nil then return a[1], a[2] end
  local real, reason = true, nil
  if Faces.of_character(base) == false then
    real, reason = false, "no_face"
  else
    local t = tables()
    local model_id = t and t.base[base] or nil
    if model_id == nil then
      real = nil
    elseif player_body(model_id) == false then
      real, reason = false, "no_player_body"
    elseif not t.profile[base] then
      real, reason = false, "no_profile"
    end
  end
  ANSWER[base] = { real, reason }
  return real, reason
end

--- Advanced: a card (chara_param id) -> as of_character of its character
function M.of_card(card)
  local ok, base = pcall(VRFW.character.base_of, u32(card))
  if not ok or type(base) ~= "number" then return nil end
  return M.of_character(base)
end

return M
