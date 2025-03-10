local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrColor = import 'LrColor'
local LrSelection = import 'LrSelection'
local Sections = require 'LinkSections'

local catalog
local cycle_string

local types = {{
    value = 'feature',
    title = 'Feature'
}, {
    value = 'photoessay',
    title = 'Photo Essay'
}, {
    value = 'brief',
    title = 'Brief'
}, {
    value = nil,
    title = ""
}}

function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

LrFunctionContext.postAsyncTaskWithContext("AutoCollections", function(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    catalog = LrApplication.activeCatalog()

    -- LrSelection.deselectOthers()
    photos = catalog:getTargetPhotos()
    --[[ photo = catalog:getTargetPhoto()
    cycle = photo:getPropertyForPlugin(_PLUGIN, "cycle")
    type = photo:getPropertyForPlugin(_PLUGIN, "type")
    p_section = photo:getPropertyForPlugin(_PLUGIN, "section")
    slug = photo:getPropertyForPlugin(_PLUGIN, "slug")
    author = photo:getPropertyForPlugin(_PLUGIN, "author")
    online_print = photo:getPropertyForPlugin(_PLUGIN, "online_print") ]]

    local f = LrView.osFactory()
    local updateField = f:edit_field{
        immediate = true,
        value = ""
    }
    -- Create the contents for the dialog.

    local c = f:column{
        spacing = f:dialog_spacing(),

        f:row{f:static_text{
            alignment = "right",
            width = LrView.share "label_width",
            title = "Issue Number: "
        }, updateField, checkbox} -- end row
    } -- end column

    local run = LrDialogs.presentModalDialog {
        title = "Custom Dialog Observer",
        contents = c
    }
    -- inputstring = string.gsub(updateField.value, "%s+", "")
    inputstring = updateField.value:match '^%s*(.*%S)' or ''
    data = mysplit(inputstring, ".")
    if run ~= "cancel" then
        cycle = data[1]
        cycle_string = string.format("%02d", cycle)
        t_photo_contributor = ""
        t_type = nil

        if (#data == 5) then
            -- t_section = data[2]
            for i, v in ipairs(Sections) do
                if v.value ~= nil then
                    if (string.lower(string.sub(data[2], 1, 3)) == string.lower(string.sub(v.title, 1, 3)) or
                        string.lower(string.sub(data[2], 1, 3)) == string.lower(string.sub(v.value, 1, 3))) then
                        t_section = v.value
                    end
                end
            end
            t_slug = data[3]
            t_author = data[4]
            t_online = data[5]
        end
        if (#data == 6) then
            section2 = false
            -- checking if 2 is type or section
            for i, v in ipairs(Sections) do
                if v.value ~= nil then
                    if (string.lower(string.sub(data[2], 1, 3)) == string.lower(string.sub(v.title, 1, 3)) or
                        string.lower(string.sub(data[2], 1, 3)) == string.lower(string.sub(v.value, 1, 3))) then
                        -- data[2] is section
                        t_section = v.value
                        t_slug = data[3]
                        t_author = data[4]
                        t_online = data[5]
                        t_photo_contributor = data[6]

                        section2 = true
                        break
                    end
                end
            end
            if not section2 then
                -- data[2] is type
                for i, v in ipairs(types) do
                    if v.value ~= nil then
                        if (string.lower(string.sub(data[2], 1, 3)) == string.lower(string.sub(v.title, 1, 3)) or
                            string.lower(string.sub(data[2], 1, 3)) == string.lower(string.sub(v.value, 1, 3))) then
                            t_type = v.value
                        end
                    end
                end
                -- t_type = data[2]
                for i, v in ipairs(Sections) do
                    if v.value ~= nil then
                        if (string.lower(string.sub(data[3], 1, 3)) == string.lower(string.sub(v.title, 1, 3)) or
                            string.lower(string.sub(data[3], 1, 3)) == string.lower(string.sub(v.value, 1, 3))) then
                            t_section = v.value
                        end
                    end
                end
                t_slug = data[4]
                t_author = data[5]
                t_online = data[6]
            end
        end
        --[[  if (#data == 7) then

		end ]]
        for i, v in ipairs(photos) do
            catalog:withWriteAccessDo("Create child collection", function()
                v:setPropertyForPlugin(_PLUGIN, "cycle", cycle_string)
                v:setPropertyForPlugin(_PLUGIN, "type", t_type)
                v:setPropertyForPlugin(_PLUGIN, "section", t_section)
                v:setPropertyForPlugin(_PLUGIN, "slug", t_slug)
                v:setPropertyForPlugin(_PLUGIN, "author", t_author)
                v:setPropertyForPlugin(_PLUGIN, "online_print", t_online)
                v:setPropertyForPlugin(_PLUGIN, "contributor", t_photo_contributor)
            end)
        end
    end
end)
