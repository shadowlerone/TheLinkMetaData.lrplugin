-- local json = require "json"
local LrApplication = import "LrApplication"
local LrDialogs = import "LrDialogs"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrFunctionContext = import "LrFunctionContext"
local LrProgressScope = import "LrProgressScope"
local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'
local LrTasks = import 'LrTasks'


local logger = LrLogger("LinkExportLogger")
logger:enable('logfile')
logger.logLevel = "debug"

local exportServiceProvider = {}

local metadata
local LR_Keys = {
	'fileName',
	"preservedFileName",
	"rating",
	"title",
	"caption",
	"artist",
	"headline",

}
local SELECTOR = "%{%{([%w_.]+)}}"
-- Source - https://stackoverflow.com/a
-- Posted by tonypdmtr
-- Retrieved 2025-11-30, License - CC BY-SA 3.0

function CleanNils(t)
	local ans = {}
	for _, v in pairs(t) do
		ans[#ans + 1] = v
	end
	return ans
end

function explore(k, v)
	if type(v) == "table" then
		return explore(v)
	end
	logger:trace(k)
	logger:trace(v)
end

function has_key(table, key)
	for k, v in pairs(table) do
		-- logger:trace(k)
		if k == key then
			return true
		end
	end
	return false
end

function has_value(table, value)
	for k, v in pairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

function GetLinkMetadata(photo)
	logger:trace "Getting raw metadata"
	local rawMetaData
	logger:trace(photo)

	rawMetaData = photo:getRawMetadata("customMetadata")


	-- logger:trace(test)
	logger:trace "Raw Metadata obtained"
	local _metadata = {}
	-- metadata["lewis.TheLink.Metadata"] = {}
	logger:trace 'Parsing metadata'
	local last_id
	for i, v in ipairs(rawMetaData) do
		if v.sourcePlugin == "lewis.TheLink.Metadata" then
			logger:trace(v.id)
			logger:trace(v.value)
			_metadata[v.id] = v.value
			logger:trace(_metadata[v.id])
			last_id = v.id
		end
	end
	logger:trace "Returning metadata"
	logger:trace(_metadata[last_id])
	return _metadata
end

function GetAllMetadata(photo)
	logger:info "Getting Metadata"
	local rawMetaData

	rawMetaData = photo:getRawMetadata("customMetadata")
	logger:trace "Raw Metadata obtained"


	local _metadata = {}
	logger:info "Getting The Link specific metadata"
	for i, v in ipairs(rawMetaData) do
		if v.sourcePlugin == "lewis.TheLink.Metadata" then
			logger:trace(v.id)
			logger:trace(v.value)
			_metadata[v.id] = v.value
			-- table.insert(metadata, v.id, v.value)
		end
		-- table.insert(metadata, v.sourcePlugin .. '.' .. v.id, v.value)
		_metadata[v.sourcePlugin .. '.' .. v.id] = v.value
	end
	logger:info "Getting other metadata"
	for i, v in ipairs(LR_Keys) do
		logger:trace("going through pairs")
		logger:trace(i)
		logger:trace(v)
		_metadata[v] = photo:getFormattedMetadata(v)
	end
	logger:trace "All metadata obtained. total count: "
	logger:trace(#_metadata)
	return _metadata
end

function SubstitutePhotoMetadata(photo, str)
	local _metadata = GetLinkMetadata(photo)
	return SubstituteMetadata(_metadata, str)
end

function _sub(_m, _t)
	local m
	logger:trace "checking if token in metadata"
	if has_key(_m, _t) then
		logger:trace("token " .. _t .. " found in metadata table")
		m = _m[_t]
	else
		logger:warn("token " .. _t .. " not found in metadata table")
		-- m = "{{" .. token .. "}}"
		-- Token not found -> replacing with blank
		m = ""
	end
	return m
end

function SubstituteMetadata(_metadata, str)
	logger:trace "Entering substitute Metadata"
	-- find all replaceable tokens

	--[[ local tokens = string.find(str, "%{%b{}%}")
	if tokens then
		return tokens[1]
	end ]]
	local tokens = {}
	logger:trace("hunting for tokens")
	for token in str:gmatch("%{%{([%w_.]+)}}") do
		-- checking link metadata
		logger:trace("token found:")
		logger:trace(token)
		if not has_key(tokens, token) then
			local m
			logger:trace "checking if token in metadata"
			if has_key(_metadata, token) then
				logger:trace("token " .. token .. " found in metadata table")
				m = _metadata[token]
			else
				logger:warn("token " .. token .. " not found in metadata table")
				-- m = "{{" .. token .. "}}"
				-- Token not found -> replacing with blank
				m = ""
			end
			tokens[token] = m
		end
	end
	local output = str
	-- for token, value in pairs(tokens) do
	-- 	output = string.gsub(output, "%{%{" .. token .. "}}", value)
	-- end
	output = string.gsub(output, SELECTOR, tokens)
	-- remove duplicates
	-- iterate through them
	-- check if it's a token within this plugin
	-- check if it is a full plugin id (TODO)
	-- add resulting replacement to a list

	-- iterate through final list, gsubbing as we go

	logger:trace "exiting substitute metadata"

	-- final cleanup
	-- remove duplicate '.'
	-- sanitize for url
	return output
end

function PreviewTemplate(propertyTable, key, value, default_value)
	logger:trace "Entering Preview Template validation"
	-- logger:tracer(photo:getFormattedMetadata('preservedFileName'))
	-- local photo = catalog:
	local result = SubstituteMetadata(metadata, value)
	if #result < 1 then
		result = default_value or ''
	end
	propertyTable[key] = result

	logger:trace "Exiting Preview Template validation"
	return result
end

-- exportServiceProvider.name = "Export in the Link Format"
exportServiceProvider.allowFileFormats = { 'JPEG' }
exportServiceProvider.allowColorSpaces = { 'sRGB' }

exportServiceProvider.showSections = {
	-- 'exportLocation',
	'fileSettings',
	'imageSettings',
	'metadata'
}


-- Setup presets

local base_length = string.len "{{cycle}}.{{type}}.{{section}}.{{slug}}"

exportServiceProvider.exportPresetFields = {
	{ key = "volume_directory", default = '' },
	{ key = 'article_folder',   default = "{{cycle}}.{{section}}.{{slug}}.{{author}}.{{online_print}}" },
	{ key = 'photo_name',       default = "{{cycle}}.{{section}}.{{slug}}.{{author}}.{{online_print}}.{{contributor}}.{{filename}}" },
	{ key = 'print_location',   default = 'CYCLE {{cycle}}/PROD/PHOTOS' },
	{ key = 'online_location',  default = 'CYCLE {{cycle}}/ONLINE/PHOTOS' }
}

exportServiceProvider.sectionsForTopOfDialog = function(vf, propertyTable)
	local catalog -- = LrApplication.activeCatalog()
	local photo -- = catalog:getTargetPhoto()
	local filename -- = photo:getFormattedMetadata('preservedFileName')

	catalog = LrApplication.activeCatalog()
	photo = catalog:getTargetPhoto()
	filename = photo:getFormattedMetadata('preservedFileName')
	metadata = GetAllMetadata(photo)



	local LrView = import "LrView"


	LrView = import "LrView"



	local bind = LrView.bind -- a local shortcut for the binding function
	-- propertyTable.article_folder = "{{cycle}}.{{type}}.{{section}}.{{slug}}.{{author}}.{{online_print}}"

	logger:trace "sanity check"
	logger:trace(metadata['contributor'])
	propertyTable.photo_metadata = metadata
	propertyTable.photo_link_metadata = metadata

	logger:trace "Checking metadata..."
	logger:trace(#metadata)
	propertyTable.article_folder_preview = SubstituteMetadata(metadata, propertyTable.article_folder)
	propertyTable.photo_name_preview = SubstituteMetadata(metadata, propertyTable.photo_name)
	-- propertyTable.photo_name = "{{cycle}}.{{type}}.{{section}}.{{slug}}.{{author}}.{{online_print}}.{{contributor}}.{{filename}}"
	-- propertyTable.photo_name_preview = filename
	propertyTable._preview = ''
	propertyTable._preview = ''


	return {
		{
			spacing = vf:control_spacing(),
			title = "Naming Scheme",
			vf:row {
				spacing = vf:label_spacing(),
				vf:column {
					spacing = vf:control_spacing(),
					vf:static_text {
						title = 'Article Folder'
					},
					vf:static_text {
						title = 'Preview'
					},
				},
				vf:column {
					spacing = vf:control_spacing(),
					vf:edit_field {
						value = bind 'article_folder',
						placeholder_string = "{{cycle}}.{{type}}.{{section}}.{{slug}}.{{author}}.{{online_print}}",
						width_in_chars = base_length,
						immediate = true,
						validate = function(view, value)
							PreviewTemplate(propertyTable, 'article_folder_preview', value)

							return true, value
						end
					},
					vf:edit_field {
						enabled = false,
						value = bind 'article_folder_preview',
						width_in_chars = base_length,
					},
				}

			},
			vf:separator {
				fill_horizontal = 1
			},
			vf:row {
				spacing = vf:label_spacing(),

				vf:column {
					spacing = vf:control_spacing(),
					vf:static_text {
						title = 'Photo File Name'
					},
					vf:static_text {
						title = 'Preview'
					}
				},
				vf:column {
					spacing = vf:control_spacing(),
					vf:edit_field {
						value = bind 'photo_name',
						placeholder_string = "{{cycle}}.{{type}}.{{section}}.{{slug}}.{{author}}.{{online_print}}.{{contributor}}.{{filename}}",
						width_in_chars = base_length,
						immediate = true,
						validate = function(view, value)
							PreviewTemplate(propertyTable, 'photo_name_preview', value, filename)

							return true, value
						end

					},
					vf:edit_field {
						enabled = false,
						value = bind 'photo_name_preview',
						width_in_chars = base_length,
					},
				}


			},
		},
		{
			title = "File Location",
			vf:group_box {
				title = 'Volume Settings',
				vf:row {
					vf:static_text {
						title = 'Volume Folder'
					},
					vf:edit_field {
						value = bind 'volume_directory',
						placeholder_string = 'Shared Drive/Volume 47',
						width_in_chars = base_length
					},
					vf:push_button {
						title = "Select Folder",
						action = function()
							local path = LrDialogs.runOpenPanel({
								title = "Select base directory for exporting Volume",
								prompt = "Select folder",
								canChooseFiles = false,
								canChooseDirectories = true,
								canCreateDirectories = true,
								allowMultipleSelection = false,
							})
							logger:info("Selected path for output")
							logger:trace(#path)
							logger:trace(path[1])
							if path then
								propertyTable.volume_directory = LrPathUtils.standardizePath(path[1])
							end
						end,
					}
				},

			},
			vf:group_box {
				title = 'Export path templates',
				vf:row {
					vf:edit_field {
						value = bind 'print_location',
						width_in_chars = base_length
					},
				},
				vf:edit_field {
					value = bind 'online_location',
					width_in_chars = base_length
				},
			},

		}
	}
end




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
	local exportSettings = assert(exportContext.propertyTable)
	local nPhotos = exportSession:countRenditions()

	local pt = exportContext.propertyTable
	logger:info "================="
	logger:info "Export settings:"
	logger:info(pt.volume_directory)
	logger:info(pt.online_location)
	logger:info(pt.print_location)
	logger:info(pt.article_folder)
	logger:info(pt.photo_name)
	logger:trace("Setting up Scope")
	local progressScope = exportContext:configureProgress {
		title = nPhotos > 1
			and LOC("$$$/GPhoto/Publish/Progress=Exporting ^1 photos", nPhotos)
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
				local metadata = GetLinkMetadata(photo)

				logger:trace 'metadata parsed'

				logger:trace 'Creating file name table'

				local file = {
					cycle        = metadata.cycle or '00',
					type         = metadata.type,
					section      = metadata.section or "unknown",
					slug         = metadata.slug or "unknown",
					author       = metadata.author or "unknown",
					online_print = metadata.online_print or "online",
					contributor  = metadata.contributor or photo:getFormattedMetadata('artist') or "unknown",
					filename     = LrPathUtils.removeExtension(photo:getFormattedMetadata("preservedFileName")),
				}
				logger:trace 'File table'
				logger:trace('\t' .. tostring(file.cycle))
				logger:trace('\t' .. tostring(file.section))
				logger:trace('\t' .. tostring(file.slug))
				logger:trace('\t' .. tostring(file.author))
				logger:trace('\t' .. tostring(file.online_print))
				logger:trace('\t' .. tostring(file.contributor))
				logger:trace('\t' .. tostring(file.filename))
				logger:trace '---'
				local file_array = {
					file.cycle, file.type, file.section, file.slug, file.author, file.online_print, file.contributor,
					file.filename
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
				local new_filename = LrPathUtils.addExtension(table.concat(file_array, "."),
					LrPathUtils.extension(rendition.destinationPath))
				logger:trace('Renamed file: ' .. new_filename)
				-- local section_folder_name = table.concat(section_folder, ".")

				local article_folder_name = table.concat(article_folder, ".")
				logger:trace('Named Folder: ' .. article_folder_name)
				local outdir = article_folder_name
				local dest_dir = LrPathUtils.child(LrPathUtils.parent(pathOrMessage), outdir)
				-- logger:trace 'Create directories'
				logger:trace('Creating directories: ' .. tostring(LrFileUtils.createAllDirectories(
					dest_dir
				)))

				local full_output_filepath = LrPathUtils.child(dest_dir, new_filename)
				logger:trace('Full output path: ' .. full_output_filepath)
				logger:trace('Copied image: ' .. tostring(LrFileUtils.copy(pathOrMessage, full_output_filepath)))
				-- os:rename(LrPathUtils.child (dest_dir,LrPathUtils.leafName(pathOrMessage)), LrPathUtils.child (dest_dir,new_filename))
				-- local tmp_name = LrPathUtils.leafName(pathOrMessage)
				-- DO the magic
				if LrFileUtils.delete(pathOrMessage) then
					logger:trace 'Deleted image'
				end
			end
		end
	end
end

---------------
return exportServiceProvider
