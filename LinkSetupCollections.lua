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

local CollectionSetup = require "CollectionSetup"
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

    SetupCollections(context)

end)
