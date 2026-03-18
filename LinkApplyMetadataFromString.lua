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
local Sections = require 'utils.LinkSections'
local LinkTypes = require 'utils.LinkTypes'
require 'utils.str-utils'

local catalog
local cycle_string



LrFunctionContext.postAsyncTaskWithContext("AutoCollections", function(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    catalog = LrApplication.activeCatalog()
    photos = catalog:getTargetPhotos()

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
        local cycle = trim(data[1])
        cycle_string = string.format("%02d", cycle)
        local t_photo_contributor = ""
        local t_type = nil

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
            t_slug = trim(data[3])
            t_author = trim(data[4])
            t_online = trim(data[5])
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
                        t_slug = trim(data[3])
                        t_author = trim(data[4])
                        t_online = trim(data[5])
                        t_photo_contributor = trim(data[6])

                        section2 = true
                        break
                    end
                end
            end
            if not section2 then
                -- data[2] is type
                for i, v in ipairs(LinkTypes) do
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
                t_slug = trim(data[4])
                t_author = trim(data[5])
                t_online = trim(data[6])
            end
        end
        --[[  if (#data == 7) then

		end ]]
        for i, photo in ipairs(photos) do
			local fallback = {
				cycle = photo:getPropertyForPlugin(_PLUGIN,"cycle"),
				type = photo:getPropertyForPlugin(_PLUGIN,"type"),
				section = photo:getPropertyForPlugin(_PLUGIN,"section"),
				slug = photo:getPropertyForPlugin(_PLUGIN,"slug"),
				author = photo:getPropertyForPlugin(_PLUGIN,"author"),
				online = photo:getPropertyForPlugin(_PLUGIN,"online_print"),
				contributor  = photo:getPropertyForPlugin(_PLUGIN,"contributor"),
			}
            catalog:withWriteAccessDo("Setting metadata values", function()
                photo:setPropertyForPlugin(_PLUGIN, "cycle", cycle_string or fallback.cycle)
                photo:setPropertyForPlugin(_PLUGIN, "type", t_type or fallback.type)
                photo:setPropertyForPlugin(_PLUGIN, "section", t_section or fallback.section)
                photo:setPropertyForPlugin(_PLUGIN, "slug", t_slug or fallback.slug)
                photo:setPropertyForPlugin(_PLUGIN, "author", t_author or fallback.author)
                photo:setPropertyForPlugin(_PLUGIN, "online_print", t_online or fallback.online)
                photo:setPropertyForPlugin(_PLUGIN, "contributor", t_photo_contributor or fallback.contributor)
            end)
        end
    end
end)
