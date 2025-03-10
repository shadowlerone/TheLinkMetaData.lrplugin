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
local CollectionSetup = require "CollectionSetup"
-- local LinkSetupCollections = require 'LinkSetupCollections'

local catalog
local cycle_string

LrFunctionContext.postAsyncTaskWithContext("AutoCollections", function(context)
    LrDialogs.attachErrorDialogToFunctionContext(context)
    catalog = LrApplication.activeCatalog()

    LrSelection.deselectOthers()
    photo = catalog:getTargetPhoto()
    cycle = photo:getPropertyForPlugin(_PLUGIN, "cycle")
    type = photo:getPropertyForPlugin(_PLUGIN, "type")
    p_section = photo:getPropertyForPlugin(_PLUGIN, "section")
    slug = photo:getPropertyForPlugin(_PLUGIN, "slug")
    author = photo:getPropertyForPlugin(_PLUGIN, "author")
    online_print = photo:getPropertyForPlugin(_PLUGIN, "online_print")
    cycle_string = string.format("%02d", cycle)

    file = {cycle_string, p_section, slug, author, online_print}
    if type ~= nil then
        table.insert(file, 2, type)
        -- table.insert(article_folder, 2, metadata.type)
    end
    collections = SetupCollections(context, {
        cycle = cycle
    })

    if online_print == "print" then
        col = collections.p
    elseif online_print == "online" then
        col = collections.o
    end
    local s_section
    for _, section in pairs(Sections) do
        if section.value ~= nil then
            if section.value == p_section then
                s_section = section
            end
        end
    end
    for k, v in pairs(col:getChildCollectionSets()) do

        if v:getName() == (cycle_string .. "." .. s_section.title) then
            c_name = table.concat(file, ".")
            catalog:withWriteAccessDo("Create child collection", function()
                child = catalog:createSmartCollection(c_name, {
                    {
                        criteria = "sdktext:lewis.TheLink.Metadata.cycle",
                        operation = "beginsWith",
                        value = cycle_string
                    },
                    {
                        criteria = "sdk:lewis.TheLink.Metadata.section",
                        operation = "==",
                        value = s_section.value
                    },
                    {
                        criteria = "sdktext:lewis.TheLink.Metadata.online_print",
                        operation = "beginsWith",
                        value = online_print
                    },
                    {
                        criteria = "sdktext:lewis.TheLink.Metadata.slug",
                        operation = "beginsWith",
                        value = slug
                    },
                    {
                        criteria = "sdktext:lewis.TheLink.Metadata.author",
                        operation = "beginsWith",
                        value = author
                    },
                    combine = "intersect"
                }, v, true)
            end)
            break
        end
    end

    --[[  catalog:withWriteAccessDo("Create parent collection set", function()
        parent = catalog:createCollectionSet("Issue " .. cycle_string, nil, true)
        child = catalog:createSmartCollection("@all", {
            {
                criteria = "sdktext:lewis.TheLink.Metadata.cycle",
                operation = "beginsWith",
                value = cycle_string
            },
            combine = "intersect"

        }, parent, true)
    end)

    catalog:withWriteAccessDo("Create child collection set", function()
        online_collection = catalog:createCollectionSet("online", parent, true)
        print_collection = catalog:createCollectionSet("print", parent, true)
    end)


	catalog:withWriteAccessDo("Create child collection set", function()
		child = catalog:createSmartCollection(cycle_string .. "." .. section.title, {
			{
				criteria = "sdktext:lewis.TheLink.Metadata.cycle",
				operation = "beginsWith",
				value = cycle_string
			},
			{
				criteria = "sdk:lewis.TheLink.Metadata.section",
				operation = "==",
				value = section.value
			},
			{
				criteria = "sdktext:lewis.TheLink.Metadata.online_print",
				operation = "beginsWith",
				value = name
			},
			combine = "intersect"
		}, parent, true)
	end) ]]
    --  = photo:getPropertyForPlugin(_PLUGIN, "")
end)
