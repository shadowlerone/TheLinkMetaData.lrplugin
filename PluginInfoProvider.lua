require "PluginInit"
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'
local LrLogger = import 'LrLogger'

local bind = LrView.bind -- shortcut for bind() method
local logger = LrLogger("PluginProvider")
logger:enable('logfile')
logger.logLevel = "debug"


local function sectionsForTopOfDialog(f, propertyTable)
	return {
		{
			title = "The Link Newspaper Metadata Plugin",
			f:row {
				spacing = f:control_spacing(),

				f:static_text {
					title = LOC "$$$/CustomMetadata/Title1=Click the button to find out more about Adobe",
					fill_horizontal = 1,
				},

				f:push_button {
					width = 150,
					title = LOC "$$$/CustomMetadata/ButtonTitle=Connect to Adobe",
					enabled = true,
					action = function()
						LrHttp.openUrlInBrowser(PluginInit.URL)
					end,
				},
			},
		},
		{
			title = "Settings",
			f:row {
				bind_to_object = propertyTable,
				f:edit_field {
					value= bind 'output_directory'
				},
				f: push_button {
					title="Select output directory",
					action = function () 
						local path = LrDialogs.runOpenPanel( {
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
							propertyTable.output_directory = path[1]
						end
					end,
				}
			}
		}

	}
end



return {

	sectionsForTopOfDialog = sectionsForTopOfDialog,

}
