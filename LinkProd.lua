-- local json = require "json"
local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'


local logger = LrLogger("LinkExportLogger")
logger:enable('logfile')
logger.logLevel = "debug"

local exportServiceProvider = {}

-- exportServiceProvider.name = "Export in the Link Format"
exportServiceProvider.allowFileFormats = {'JPEG'}
exportServiceProvider.allowColorSpaces = {'sRGB'}

exportServiceProvider.showSections = {
	'exportLocation',
	'fileSettings',
	'imageSettings',
	'metadata'
}
-- recommended when exporting to the web
exportServiceProvider.hidePrintResolution = true

-- TODO: should be true
exportServiceProvider.canExportVideo = false -- video is not supported through this sample plug-in


-- TODO: filter images that are missing a metadata field
-- TODO: custom error messages

function exportServiceProvider.processRenderedPhotos(functionContext, exportContext)
	logger:trace('processRenderedPhotos')

	local exportSession = exportContext.exportSession
	local exportSettings = assert( exportContext.propertyTable )
	local nPhotos = exportSession:countRenditions()


	logger:trace("Setting up Scope")
	local progressScope = exportContext:configureProgress {
		title = nPhotos > 1
					and LOC( "$$$/GPhoto/Publish/Progress=Exporting ^1 photos", nPhotos )
					or LOC "$$$/GPhoto/Publish/Progress/One=Exporting one photo",
	}
	logger:trace("Scope Setup")


	logger:trace("Starting rendition loop")
	for i, rendition in exportContext:renditions { stopIfCanceled = true } do
		-- Update progress scope.
		-- progressScope:setPortionComplete( ( i - 1 ) / nPhotos )
		logger:trace "checking if skipped..."
		if not rendition.wasSkipped then
			local success, pathOrMessage = rendition:waitForRender()
			-- Update progress scope again once we've got rendered photo.
			-- progressScope:setPortionComplete( ( i - 0.5 ) / nPhotos )

			-- Check for cancellation again after photo has been rendered.
			if progressScope:isCanceled() then break end
			-- 

			if success then
				logger:trace "Success..."

				logger:trace "Getting raw metadata"
				local rawMetaData = rendition.photo:getRawMetadata("customMetadata")
				logger:trace "Raw Metadata obtained "
				local metadata = {}
				-- metadata["lewis.TheLink.Metadata"] = {}
				logger:trace 'Parsing metadata'
				for i, v in ipairs(rawMetaData) do
					if v.sourcePlugin == "lewis.TheLink.Metadata" then
						metadata[v.id] = v.value
					end
				end

				logger:trace 'metadata parsed'
				
				logger:trace 'Creating file name table'
				
				local file = {
					metadata.cycle,
					metadata.section,
					metadata.slug,
					metadata.author,
					metadata.online_print,
					metadata.contributor,
					LrPathUtils.removeExtension(rendition.photo:getFormattedMetadata("preservedFileName")),
				}
				
				logger:trace 'File name table created'
				logger:trace 'Creating folder table'
				local article_folder = {
					metadata.cycle,
					metadata.section,
					metadata.slug,
					metadata.author,
					metadata.online_print,
				}
				logger:trace 'folder table created'
				-- local section_folder = {
				-- 	metadata.cycle,
				-- 	metadata.section,
				-- }
				logger:trace 'section folder table created'
				logger:trace 'adding optional metadata'
				if metadata.type then
					table.insert(file, 2, metadata.type)
					table.insert(article_folder, 2, metadata.type)
				end

				local new_filename = LrPathUtils.addExtension(table.concat(file, "."), 'jpg')
				-- local section_folder_name = table.concat(section_folder, ".")
				local article_folder_name = table.concat(article_folder, ".")
				local outdir = article_folder_name
				local dest_dir = LrPathUtils.child(LrPathUtils.parent(pathOrMessage), outdir)
				LrFileUtils.createAllDirectories(
					dest_dir
				)
				local full_output_filepath = LrPathUtils.child (dest_dir,new_filename)
				LrFileUtils.copy(pathOrMessage, full_output_filepath)
				-- os:rename(LrPathUtils.child (dest_dir,LrPathUtils.leafName(pathOrMessage)), LrPathUtils.child (dest_dir,new_filename))
				-- local tmp_name = LrPathUtils.leafName(pathOrMessage)
				-- DO the magic
				LrFileUtils.delete( pathOrMessage )


			end
		end
	end

end

---------------
return exportServiceProvider
