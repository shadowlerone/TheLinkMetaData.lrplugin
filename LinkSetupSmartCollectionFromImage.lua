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

LrFunctionContext.postAsyncTaskWithContext("AutoCollections", function(context)
	LrDialogs.attachErrorDialogToFunctionContext(context)
	catalog = LrApplication.activeCatalog()
	local photos = catalog:getTargetPhotos()

	for i, photo in ipairs(photos) do
		local cycle = photo:getPropertyForPlugin(_PLUGIN, "cycle") or "00"
		local type = photo:getPropertyForPlugin(_PLUGIN, "type") or ""
		local p_section = photo:getPropertyForPlugin(_PLUGIN, "section") or "other"
		local slug = photo:getPropertyForPlugin(_PLUGIN, "slug") or "unknown"
		local author = photo:getPropertyForPlugin(_PLUGIN, "author") or "unknown"
		local online_print = photo:getPropertyForPlugin(_PLUGIN, "online_print") or "online"
		local cycle_string = string.format("%02d", cycle)

		local file = { cycle_string, p_section, slug, author, online_print }
		if type ~= nil then
			table.insert(file, 2, type)
			-- table.insert(article_folder, 2, metadata.type)
		end
		local collections = SetupCollections(context, {
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
		for k, child_collection in pairs(col:getChildCollectionSets()) do
			if child_collection:getName() == (cycle_string .. "." .. s_section.title) then
				local c_name = table.concat(file, ".")
				catalog:withWriteAccessDo("Create child collection", function()
					Create_Article_Smart_Collection(child_collection, c_name, s_section, online_print, slug, author)
				end)
				break
			end
		end
	end


	-- LrSelection.deselectOthers()
	-- Iterate over every photo
	-- local photo = catalog:getTargetPhoto()


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
