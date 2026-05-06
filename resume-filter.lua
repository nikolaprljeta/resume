local first_h1_removed = false
local emoji_map = {
  ["📧"] = "Email: ",
  ["💼"] = "LinkedIn: ",
  ["🐙"] = "GitHub: ",
  ["📞"] = "Phone: ",
  ["🏠"] = "Address: ",
}
local function strip_emoji(s)
  local cleaned = s:gsub("[\xF0-\xF7][\x80-\xBF][\x80-\xBF][\x80-\xBF]", "")
  cleaned = cleaned:gsub("[\xE2-\xEF][\x80-\xBF][\x80-\xBF]", "")
  return cleaned
end
local function inlines_to_text(inlines)
  local result = {}
  for _, el in ipairs(inlines) do
    if el.t == "Str" then table.insert(result, el.text)
    elseif el.t == "Space" then table.insert(result, " ") end
  end
  return table.concat(result)
end
local function raw(s) return pandoc.RawBlock("html", s) end
local function fix_emojis(inlines)
  local result = {}
  for _, el in ipairs(inlines) do
    if el.t == "Str" then
      local rep = emoji_map[el.text]
      if rep then table.insert(result, pandoc.Str(rep))
      else table.insert(result, pandoc.Str(strip_emoji(el.text))) end
    else table.insert(result, el) end
  end
  return result
end
local function is_badge_para(block)
  if block.t ~= "Para" then return false end
  if #block.content == 0 then return false end
  for _, inline in ipairs(block.content) do
    if inline.t ~= "Image" and inline.t ~= "Space" then
      if inline.t == "Link" then
        for _, sub in ipairs(inline.content) do
          if sub.t ~= "Image" then return false end
        end
      else return false end
    end
  end
  return true
end
function Pandoc(doc)
  local blocks = doc.blocks
  local sections = {}
  local current_section = nil
  for _, block in ipairs(blocks) do
    if block.t == "Header" and block.level == 1 and not first_h1_removed then
      first_h1_removed = true
    elseif is_badge_para(block) then
    elseif block.t == "HorizontalRule" then
    elseif block.t == "Header" and block.level == 2 then
      local label = inlines_to_text(block.content):gsub("^»%s*", "")
      current_section = { label = label, content = {} }
      table.insert(sections, current_section)
    else
      if current_section then
        if block.t == "Para" then block.content = fix_emojis(block.content) end
        table.insert(current_section.content, block)
      end
    end
  end
  local output = {}
  for _, section in ipairs(sections) do
    table.insert(output, raw('<div class="cv-section-wrapper bleed-x">'))
    table.insert(output, raw('<div class="cv-section">'))
    table.insert(output, raw('<div class="cv-section-label">' .. section.label .. '</div>'))
    table.insert(output, raw('<div class="cv-section-content">'))
    for _, b in ipairs(section.content) do table.insert(output, b) end
    table.insert(output, raw('</div>'))
    table.insert(output, raw('</div>'))
    table.insert(output, raw('</div>'))
  end
  return pandoc.Pandoc(output, doc.meta)
end
-- append is handled in Pandoc function above, this is just a note
