local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'
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

LrFunctionContext.postAsyncTaskWithContext("AutoCollections", function(context)

    LrDialogs.attachErrorDialogToFunctionContext(context)

    -- TODO: Create Dialog to get cycle number
    -- TODO: Ask if it is a special issue
    local progress = LrProgressScope {
        title = "Exporting File Lists..."
    }
    progress:attachToFunctionContext(context)

    local catalog = LrApplication.activeCatalog()
    local cycle = 7

    catalog:withWriteAccessDo("Create parent collection set", function()
        parent = catalog:createCollectionSet(string.format("%02d", cycle), nil, true)
    end)
    for _, section in pairs(Sections) do

        catalog:withWriteAccessDo("Create child collection set", function()
            child = catalog:createSmartCollection(table.concat({string.format("%02d", cycle), section.title}, '.'), {
                {
                    criteria = "sdktext:lewis.TheLink.Metadata.cycle",
                    operation = "beginsWith",
                    value = string.format("%02d", cycle),
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
end)
