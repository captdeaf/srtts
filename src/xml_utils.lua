-- Utilities for generating XML UI.

function XML(tag, attributes, contents)
  if contents == nil and attributes ~= nil then
    contents = attributes
    attributes = nil
  end
  local rval = {
    tag = tag,
  }
  if type(attributes) == "string" then
    attributes = { class = attributes }
  end
  if attributes then
    rval["attributes"] = attributes
  end
  if contents == false then
    -- Only really used for Defaults
    return rval
  end
  if type(contents) == "table" then
    if contents["tag"] then
      -- A single child, helper.
      rval["children"] = {contents}
    else
      rval["children"] = contents
    end
  elseif type(contents) == "string" then
    rval["value"] = contents
  else
    die("Unknown contents type in XML <%s>: '%s'", tag, tostring(contents))
    rval["value"] = tostring(contents)
  end
  return rval
end

function XMLText(text, class, id)
  local attrs = {
    text = text,
  }
  if class then
    attrs["class"] = class
  end
  if id then
    attrs["id"] = id
  end
  return XML("Text", attrs, false)
end

function wrapXMLInBG(attributes, xml)
  local bgimage = attributes["bgimage"]
  attributes["bgimage"] = nil
  return XML("Panel", attributes, {
      XML("TableLayout",
        { cellBackgroundImage = bgimage },
        XML("Row", {XML("Cell", xml)})
      )
    }
  )
end

function showUI(name, color)
  local attrs = {
    active = true,
  }
  if color ~= nil then
    attrs["visibility"] = color
  else
    attrs["visibility"] = ""
  end
  UI.show(name)
  UI.setAttributes(name, attrs)
end

function hideUI(name)
  -- UI.hide(name)
  UI.setAttribute(name, "active", false)
end

