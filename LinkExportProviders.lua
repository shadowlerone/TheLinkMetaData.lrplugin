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

-- Source - https://stackoverflow.com/a
-- Posted by tonypdmtr
-- Retrieved 2025-11-30, License - CC BY-SA 3.0

function CleanNils(t)
  local ans = {}
  for _,v in pairs(t) do
    ans[ #ans+1 ] = v
  end
  return ans
end


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

-- exportServiceProvider.canExportToTemporaryLocation = true


-- TODO: filter images that are missing a metadata field
-- TODO: custom error messages

function exportServiceProvider.processRenderedPhotos(functionContext, exportContext)
	logger:trace('\n\n\n===========================================')
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
				local photo = rendition.photo
				logger:trace "Getting raw metadata"
				local rawMetaData = photo:getRawMetadata("customMetadata")
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
					cycle = metadata.cycle or '00',
					type = metadata.type,
					section = metadata.section or "unknown",
					slug = metadata.slug or "unknown",
					author = metadata.author or "unknown",
					online_print = metadata.online_print or "online",
					contributor  = metadata.contributor or photo:getFormattedMetadata('artist') or "unknown",
					filename = LrPathUtils.removeExtension(photo:getFormattedMetadata("preservedFileName")),
				}
				logger:trace 'File table'
				logger:trace ('\t' .. tostring(file.cycle))
				logger:trace ('\t' .. tostring(file.section))
				logger:trace ('\t' .. tostring(file.slug))
				logger:trace ('\t' .. tostring(file.author))
				logger:trace ('\t' .. tostring(file.online_print))
				logger:trace ('\t' .. tostring(file.contributor))
				logger:trace ('\t' .. tostring(file.filename))
				logger:trace '---'
				local file_array = {
					file.cycle, file.type, file.section, file.slug, file.author, file.online_print, file.contributor, file.filename
				}
				file_array = CleanNils(file_array)
				-- logger:trace ('\t' .. tostring(article_folder.cycle))
				logger:trace '---'
				logger:trace 'File name table created'
				logger:trace 'Creating folder table'


				local article_folder = {
					file.cycle, file.type, file.section, file.slug, file.author, file.online_print
				}
				article_folder = CleanNils(article_folder)				
				local new_filename = LrPathUtils.addExtension(table.concat(file_array, "."), LrPathUtils.extension(rendition.destinationPath))
				logger:trace('Renamed file: ' .. new_filename)
				-- local section_folder_name = table.concat(section_folder, ".")
				
				local article_folder_name = table.concat(article_folder, ".")
				logger:trace ('Named Folder: ' .. article_folder_name )
				local outdir = article_folder_name
				local dest_dir = LrPathUtils.child(LrPathUtils.parent(pathOrMessage), outdir)
				-- logger:trace 'Create directories'
				logger:trace ('Creating directories: ' .. tostring(LrFileUtils.createAllDirectories(
					dest_dir
				)))
				
				local full_output_filepath = LrPathUtils.child (dest_dir,new_filename)
				logger:trace ('Full output path: ' .. full_output_filepath)
				logger:trace ('Copied image: ' .. tostring(LrFileUtils.copy(pathOrMessage, full_output_filepath)))
				-- os:rename(LrPathUtils.child (dest_dir,LrPathUtils.leafName(pathOrMessage)), LrPathUtils.child (dest_dir,new_filename))
				-- local tmp_name = LrPathUtils.leafName(pathOrMessage)
				-- DO the magic
				if LrFileUtils.delete( pathOrMessage ) then
					logger:trace 'Deleted image'
				end


			end
		end
	end

end

---------------
return exportServiceProvider
