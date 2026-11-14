-- lua_patch.scope: used
-- VRFW layer carousel: a row of cards made of layer instances, one card at the centre and its neighbours at both sides.
-- A card is instance i of every layer in `parts`; the carousel moves, scales and fades the instances at run time.
-- The screen owns what a card shows: the carousel tells it which item each instance holds.
-- Defines functions only: no engine call at load time.
if VRFW.layer_carousel == nil then
  local K = {}
  --- Internal: metatable index of the layer carousel.
  K.__index = K
  --- Advanced: Class of the layer carousel.
  VRFW.layer_carousel = K

  local C = {
    POSITION_GET = VRFW.commands.GET_LAYER_LOCAL_POS,   -- (layer, instance) -> x, y, z
    POSITION = VRFW.commands.SET_LAYER_LOCAL_POS,       -- (layer, x, y, z, instance)
    SCALE = VRFW.commands.SET_LAYER_LOCAL_SCALE,        -- (layer, x, y, z, instance)
    ALPHA = VRFW.commands.SET_LAYER_MODEL_ALPHA,        -- (layer, instance, 0, alpha)
    VISIBLE = VRFW.commands.SET_LAYER_VISIBLE,          -- (layer, instance, visible)
  }

  local function Number(v, default)
    return type(v) == "number" and v or default
  end

  --- Advanced: A carousel for `spec`: { parts = { { layer, pivot = { x, y } } }, places = { [0] = { x, y, scale, alpha }, ... },
  --- frames, wrap }. `places[d]` is the look of a card d steps from the centre (x mirrored on the left side); the last
  --- place is the parked one, never shown at rest. `pivot` is the part's origin measured from the card's centre.
  function K.new(spec)
    local c = setmetatable({}, K)
    c.parts = spec.parts
    c.places = spec.places
    c.parked = #spec.places
    c.reach = c.parked - 1
    c.ring = 2 * c.reach + 2
    c.frames = math.max(1, math.floor(Number(spec.frames, 8)))
    c.wrap_wanted = spec.wrap == true
    c.count, c.index = 0, 0
    c.offset, c.item, c.from, c.shown = {}, {}, {}, {}
    c.base, c.frame = nil, 0
    return c
  end

  --- Internal: The number of instances each part needs.
  function K:instances()
    return self.ring
  end

  -- Internal: The item `offset` steps from item `index`; nil past the ends of a carousel that does not wrap.
  function K:item_near(index, offset)
    local k = index + offset
    if self.wrap then
      return k % self.count
    end
    if k < 0 or k >= self.count then
      return nil
    end
    return k
  end

  -- Internal: The look of a card `offset` steps from the centre (a fraction between two places while it moves).
  function K:look(offset)
    local d = math.min(math.abs(offset), self.parked)
    local lo = math.floor(d)
    local hi = math.min(lo + 1, self.parked)
    local t = d - lo
    local a, b = self.places[lo], self.places[hi]
    local function Mix(key, default)
      local va, vb = Number(a[key], default), Number(b[key], default)
      return va + (vb - va) * t
    end
    local side = offset < 0 and -1 or 1
    return side * Mix("x", 0), Mix("y", 0), Mix("scale", 1), Mix("alpha", 1)
  end

  -- Internal: Applies the look of `offset` to instance `i` of every part.
  function K:place(i, offset)
    local x, y, scale, alpha = self:look(offset)
    local visible = self.item[i] ~= nil and math.abs(offset) < self.parked
    for p, part in ipairs(self.parts) do
      local base = self.base[p][i]
      local px, py = Number(part.pivot and part.pivot.x, 0), Number(part.pivot and part.pivot.y, 0)
      -- a hidden instance is moved too: its click zone leaves the screen with it
      VRFW.host.menu_command(C.POSITION, part.layer, base[1] + x + (scale - 1) * px, base[2] + y + (scale - 1) * py, base[3], i)
      if visible then
        VRFW.host.menu_command(C.SCALE, part.layer, scale, scale, 1, i)
        VRFW.host.menu_command(C.ALPHA, part.layer, i, 0, alpha)
      end
      if self.shown[i] ~= visible then
        VRFW.host.menu_command(C.VISIBLE, part.layer, i, visible)
      end
    end
    self.shown[i] = visible
  end

  --- Internal: Opens the carousel over `count` items with item `index` (0-based) at the centre. Call it once every instance of
  --- the parts is set up. Answers the list of { instance, item } the screen must fill.
  function K:open(count, index)
    if self.base == nil then
      self.base = {}
      for p, part in ipairs(self.parts) do
        self.base[p] = {}
        for i = 0, self.ring - 1 do
          local x, y, z = VRFW.host.menu_command(C.POSITION_GET, part.layer, i)
          self.base[p][i] = { Number(x, 0), Number(y, 0), Number(z, 0) }
        end
      end
    end
    self.count = math.max(0, math.floor(count))
    self.wrap = self.wrap_wanted and self.count >= self.ring
    return self:jump(index)
  end

  --- Internal: Puts item `index` at the centre without a slide. Answers the list of { instance, item } the screen must fill.
  function K:jump(index)
    self.index = math.max(0, math.min(math.max(0, self.count - 1), math.floor(index)))
    self.frame = 0
    local fill = {}
    for i = 0, self.ring - 1 do
      local offset = i - self.reach
      if i == self.ring - 1 then
        offset = self.parked
      end
      self.offset[i], self.from[i] = offset, offset
      self.item[i] = nil
      if math.abs(offset) < self.parked and self.count > 0 then
        self.item[i] = self:item_near(self.index, offset)
      end
      if self.item[i] ~= nil then
        fill[#fill + 1] = { instance = i, item = self.item[i] }
      end
    end
    for i = 0, self.ring - 1 do
      self.shown[i] = nil
      self:place(i, self.offset[i])
    end
    return fill
  end

  --- Internal: Moves one item to the right (direction 1) or to the left (-1). Answers false at an end of a carousel that does
  --- not wrap; else true and the { instance, item } the screen must fill (nil when no new card comes in).
  function K:move(direction)
    direction = direction < 0 and -1 or 1
    if self.count == 0 or self:item_near(self.index, direction) == nil then
      return false
    end
    if self.frame > 0 then
      self:finish()
    end
    local spare
    for i = 0, self.ring - 1 do
      if math.abs(self.offset[i]) >= self.parked then
        spare = i
      end
    end
    self.index = self:item_near(self.index, direction)
    -- The parked instance comes in from the side the cards move away from.
    self.offset[spare] = direction * self.parked
    self.item[spare] = self:item_near(self.index, direction * self.reach)
    self.shown[spare] = nil
    for i = 0, self.ring - 1 do
      self.from[i] = self.offset[i]
      self.offset[i] = self.offset[i] - direction
    end
    self.frame = self.frames
    self:place(spare, self.from[spare])
    if self.item[spare] == nil then
      return true, nil
    end
    return true, { instance = spare, item = self.item[spare] }
  end

  --- Internal: Ends a running slide at once.
  function K:finish()
    self.frame = 0
    for i = 0, self.ring - 1 do
      self.from[i] = self.offset[i]
      self:place(i, self.offset[i])
    end
  end

  --- Internal: One frame of the slide (the screen's Step). Answers true while the cards move.
  function K:step()
    if self.frame <= 0 then
      return false
    end
    self.frame = self.frame - 1
    if self.frame == 0 then
      self:finish()
      return false
    end
    local t = 1 - self.frame / self.frames
    local eased = 1 - (1 - t) * (1 - t)
    for i = 0, self.ring - 1 do
      self:place(i, self.from[i] + (self.offset[i] - self.from[i]) * eased)
    end
    return true
  end

  --- Internal: True while the cards move.
  function K:moving()
    return self.frame > 0
  end

  --- Internal: The item at the centre (0-based).
  function K:centre_item()
    return self.index
  end

  --- Internal: The instance at the centre.
  function K:centre_instance()
    for i = 0, self.ring - 1 do
      if self.offset[i] == 0 then
        return i
      end
    end
    return 0
  end

  --- Internal: The item instance `i` holds; nil when it holds none.
  function K:item_of(i)
    return self.item[i]
  end

  --- Internal: The instance that shows `item`; nil when no visible card holds it.
  function K:instance_of(item)
    for i = 0, self.ring - 1 do
      if self.item[i] == item and math.abs(self.offset[i]) < self.parked then
        return i
      end
    end
    return nil
  end

  --- Internal: How many steps instance `i` is from the centre (negative = to the left).
  function K:offset_of(i)
    return self.offset[i]
  end

  --- Advanced: Lays `count` marks of `spec` in one centred row with a wider gap between groups: spec = { layer, first, limit,
  --- x, y, pitch, group_gap, scale = { x, y } }, `groups` = the size of each group. Mark k (0-based) is instance
  --- first + k of the layer. Answers the number of marks laid (0 when they do not fit in `limit`).
  function K.lay_marks(spec, groups)
    local count = 0
    for _, size in ipairs(groups) do
      count = count + size
    end
    if count > spec.limit then
      count = 0
    end
    local width = (count - 1) * spec.pitch + math.max(0, #groups - 1) * spec.group_gap
    local x = spec.x - width / 2
    local k = 0
    if count > 0 then
      for _, size in ipairs(groups) do
        for _ = 1, size do
          local i = spec.first + k
          VRFW.host.menu_command(C.VISIBLE, spec.layer, i, true)
          VRFW.host.menu_command(C.POSITION, spec.layer, x, spec.y, 0, i)
          VRFW.host.menu_command(C.SCALE, spec.layer, spec.scale.x, spec.scale.y, 1, i)
          x = x + spec.pitch
          k = k + 1
        end
        x = x + spec.group_gap
      end
    end
    for i = spec.first + count, spec.first + spec.limit - 1 do
      VRFW.host.menu_command(C.VISIBLE, spec.layer, i, false)
    end
    return count
  end
end
