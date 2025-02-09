local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrColor = import 'LrColor'
local Sections = require 'LinkSections'
-- Sections = {{
--     value = 'news',
--     title = "News"
-- }, {
--     value = 'fringe',
--     title = 'Fringe Arts'
-- }, {
--     value = 'sports',
--     title = 'Sports'
-- }, {
--     value = 'opinions',
--     title = 'Opinions'
-- }, {
--     value = 'editorial',
--     title = 'Editorial'
-- }, {
--     value = nil,
--     title = ""
-- }}

local catalog
local cycle_string
function generate(parent, name)
	for _, section in pairs(Sections) do
		if section.value == nil then
			catalog:withWriteAccessDo("Create child collection set", function()
				child = catalog:createSmartCollection("@all", {
					{
						criteria = "sdktext:lewis.TheLink.Metadata.cycle",
						operation = "beginsWith",
						value = cycle_string
					},
					{
						criteria = "sdktext:lewis.TheLink.Metadata.online_print",
						operation = "beginsWith",
						value = name
					},
					combine = "intersect"
				}, parent, true)
			end)
		else
			catalog:withWriteAccessDo("Create child collection set", function()
				child = catalog:createSmartCollection( cycle_string .. "." .. section.title, {
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
			end)
		end

	end
end


LrFunctionContext.postAsyncTaskWithContext("AutoCollections", function(context)

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
    local special_issue = false

    -- Dialog

    local f = LrView.osFactory()
    local checkbox = f:checkbox({
        title = "Special Issue",
        value = false,
        checked_value = true,
        unchecked_value = false
    })

    local updateField = f:edit_field{
        immediate = true,
        value = ""
    }
    local staticTextValue = f:static_text{
        title = props.cycle
    }
    local staticCheckValue = f:static_text{
        title = props.special_issue
    }

    -- This is the function that will run when the value props.myString is changed.

    local function myCalledFunction()
        -- outputToLog("props.cycle has been updated.")
        staticTextValue.title = updateField.value
        -- staticTextValue.text_color = LrColor(1, 0, 0)
    end
    local function myCalledFunction2()
        -- outputToLog("props.special_issue has been updated.")
        staticCheckValue.title = special_issue.value
        -- staticCheckValue.text_color = LrColor(1, 0, 0)
    end

    -- Add an observer to the property table.  We pass in the key and the function
    -- we want called when the value for the key changes.
    -- Note:  Only when the value changes will there be a notification sent which
    -- causes the function to be invoked.

    props:addObserver("cycle", myCalledFunction)
    props:addObserver("special_issue", myCalledFunction2)

    -- Create the contents for the dialog.

    local c = f:column{
        spacing = f:dialog_spacing(),
        -- spacing = f:dialog_spacing(),
        --[[  f:row{
            fill_horizontal = 1,
            f:static_text{
                alignment = "right",
                width = LrView.share "label_width",
                title = "Bound value: "
            },
            staticTextValue,
            f:static_text{
                alignment = "right",
                width = LrView.share "label_width",
                title = "Bound value: "
            },
            staticCheckValue
        }, -- end f:row ]]
        f:row{f:static_text{
            alignment = "right",
            width = LrView.share "label_width",
            title = "Issue Number: "
        }, updateField, checkbox --[[ f:push_button{
            title = "Update",

            -- When the 'Update' button is clicked.

            action = function()
                outputToLog("Update button clicked.")
                staticTextValue.text_color = LrColor(1, 0, 0)

                -- When this property is updated, the observer is notified.

                props.cycle = updateField.value
                props.special_issue = checkbox.value
            end
        } ]] } -- end row
    } -- end column

    local run = LrDialogs.presentModalDialog {
        title = "Custom Dialog Observer",
        contents = c
    }

    if run ~= "cancel" then
        props.cycle = updateField.value
        props.special_issue = checkbox.value
        cycle_string = string.format("%02d", props.cycle)
        catalog:withWriteAccessDo("Create parent collection set", function()
            parent = catalog:createCollectionSet("Issue " .. cycle_string, nil, true)
			child = catalog:createSmartCollection("@all", {
				{
					criteria = "sdktext:lewis.TheLink.Metadata.cycle",
					operation = "beginsWith",
					value = cycle_string
				},
				combine = "intersect"
			
			},parent,true)
        end)

        catalog:withWriteAccessDo("Create child collection set", function()
            online_collection = catalog:createCollectionSet("online", parent, true)
            print_collection = catalog:createCollectionSet("print", parent, true)
        end)


		-- online
		generate(online_collection, "online")
		generate(print_collection, "print")
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

end)
