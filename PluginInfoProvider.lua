require "PluginInit"

local function sectionsForTopOfDialog(f, _)
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
		}

	}
end



return {

	sectionsForTopOfDialog = sectionsForTopOfDialog,

}
