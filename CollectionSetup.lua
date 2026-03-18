local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrColor = import 'LrColor'
local Sections = require 'utils.LinkSections'

local catalog
local cycle_string

function Criteria(criteria, operation, _value)
	return {
		criteria = criteria,
		operation = operation,
		value = _value
	}
end

function BeginsWithCriteria(criteria, _value)
	return Criteria(criteria, "beginsWith", _value)
end

function IsCriteria(criteria, _value)
	return Criteria(criteria, "==", _value)
end

function cycle_criteria(c_s)
	return BeginsWithCriteria("sdktext:lewis.TheLink.Metadata.cycle", c_s)
end

function section_criteria(section)
	return IsCriteria("sdk:lewis.TheLink.Metadata.section", section.value)
end

function online_print_criteria(name)
	return IsCriteria("sdktext:lewis.TheLink.Metadata.online_print", name)
end

function create_all_collection(parent, name)
	local child = catalog:createSmartCollection("@all", {
		cycle_criteria(cycle_string),
		online_print_criteria(name),
		combine = "intersect"
	}, parent, true)
	return child
end

function create_section_collection(section, parent, name)
	local child = catalog:createSmartCollection(cycle_string .. "." .. section.title .. ".all", {
		cycle_criteria(cycle_string),
		section_criteria(section),
		online_print_criteria(name),
		combine = "intersect"
	}, parent, true)
	return child
end

function Create_Article_Smart_Collection(parent, name, section, online_print, slug, author)
	local child = catalog:createSmartCollection(name, {
		cycle_criteria(cycle_string),
		section_criteria(section),
		online_print_criteria(online_print),
		BeginsWithCriteria("sdktext:lewis.TheLink.Metadata.slug", slug),
		BeginsWithCriteria("sdktext:lewis.TheLink.Metadata.author", author),
		combine = "intersect"
	}, parent, true)
	return child
end

local function generate(parent, name)
	for _, section in pairs(Sections) do
		if section.value == nil then
			catalog:withWriteAccessDo("Create child collection set", function()
				create_all_collection(parent, name)
			end)
		else
			catalog:withWriteAccessDo("Create child collection", function()
				create_section_collection(section, parent, name)
			end)
			catalog:withWriteAccessDo("Create child collection", function()
				child = catalog:createCollectionSet(cycle_string .. "." .. section.title, parent, true)
			end)
		end
	end
end

function SetupCollections(context, d)
	-- data = data or false
	LrDialogs.attachErrorDialogToFunctionContext(context)

	-- TODO: Create Dialog to get cycle number
	-- TODO: Ask if it is a special issue
	local progress = LrProgressScope {
		title = "Creating Issue Collection..."
	}
	progress:attachToFunctionContext(context)

	local props = LrBinding.makePropertyTable(context)

	props.cycle = 1
	props.special_issue = false

	catalog = LrApplication.activeCatalog()
	local cycle = 7
	local volume = 46
	local special_issue = false
	if d ~= nil then
		cycle = d.cycle
		volume = d.volume or 46
		special_issue = false
		props.cycle = d.cycle
		props.special_issue = false
	else
		-- Dialog

		local f = LrView.osFactory()
		local checkbox = f:checkbox({
			title = "Special Issue",
			value = false,
			checked_value = true,
			unchecked_value = false
		})

		local cycleField = f:edit_field {
			immediate = true,
			value = ""
		}
		local volumeField = f:edit_field {
			immediate = true,
			value = ""
		}
		local staticTextValueVolume = f:static_text {
			title = props.Volume
		}
		local staticTextValueCycle = f:static_text {
			title = props.cycle
		}
		local staticCheckValue = f:static_text {
			title = props.special_issue
		}

		-- Create the contents for the dialog.

		local c = f:column {
			spacing = f:dialog_spacing(),

			f:row { f:static_text {
				alignment = "right",
				width = LrView.share "label_width",
				title = "Issue Number: "
			},
				volumeField,
				f:static_text {
					alignment = "right",
					width = LrView.share "label_width",
					title = "Issue Number: "
				},
				cycleField, checkbox } -- end row
		}                  -- end column

		local run = LrDialogs.presentModalDialog {
			title = "Custom Dialog Observer",
			contents = c
		}


		props.volume = volumeField.value;
		props.cycle = cycleField.value
		props.special_issue = checkbox.value
	end
	if run ~= "cancel" then
		cycle_string = string.format("%02d", props.cycle)
		catalog:withWriteAccessDo("Create parent collection set", function()
			parent = catalog:createCollectionSet("Issue " .. cycle_string, nil, true)
			child = catalog:createSmartCollection("@all", {
				cycle_criteria(cycle_string),
				combine = "intersect"
			}, parent, true)
		end)

		catalog:withWriteAccessDo("Create child collection set", function()
			online_collection = catalog:createCollectionSet("online", parent, true)
			print_collection = catalog:createCollectionSet("print", parent, true)
		end)

		-- online
		generate(online_collection, "online")
		generate(print_collection, "print")
		return {
			o = online_collection,
			p = print_collection
		}
		--[[ if (special_issue == true) then
            for _, section in pairs(Sections) do
                catalog:withWriteAccessDo("Create child collection set", function()
                    child = catalog:createSmartCollection(table.concat({"Special Issue", cycle_string, section.title},
                        '.'), {
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
                        combine = "intersect"
                    }, parent, true)
                end)

            end
        end ]]
	end
end
