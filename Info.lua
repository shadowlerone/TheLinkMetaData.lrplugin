--
-- Sample "Info.lua" file,
-- from "Adding Your Own Custom Photo-Metadata Fields to Lightroom"
-- at http://regex.info/blog/2016-09-15/2731
--
return {
   LrPluginName        = "The Link MetaData", -- update the name within quotes to how you want it to appear in the Plugin Manager
   LrToolkitIdentifier = "lewis.TheLink.Metadata", -- update the identifier within quotes so that it's unique to you and this plugin
   LrSdkVersion        = 2,
   LrMetadataProvider  = 'CustomMetadata.lua',
   LrMetadataTagsetFactory = 'LinkTagset.lua',
   LrLibraryMenuItems = {
	{
		title = "Automatically create collections...",
		file = "LinkSetupCollections.lua",
	  },
	{
		title = "Automatically create collection from image...",
		file = "LinkSetupSmartCollectionFromImage.lua",
	  },
	{
		title = "Apply metadata from string",
		file = "LinkApplyMetadataFromString.lua",
	  }
   },
   LrExportServiceProvider = {
	title="Export with Link Naming Scheme",
	file="LinkExportProviders.lua"
   }
}
