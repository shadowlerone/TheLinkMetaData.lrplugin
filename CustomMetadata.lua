--
-- Sample "CustomMetadata.lua" file,
-- from "Adding Your Own Custom Photo-Metadata Fields to Lightroom"
-- at http://regex.info/blog/2016-09-15/2731
--

local Sections = require 'LinkSections'
return {
    schemaVersion = 1, -- increment this value any time you make a change to the field definitions below

    metadataFieldsForPhotos = { -- You can have as many fields as you like (the example below shows three)... just make sure each 'id' and 'title' are unique.
    -- Set "searchable" to true to allow as a search criteria in smart collections.
    -- If both "searchable" and "browsable" are true, the field shows up under "Metadata" in Library's grid filter.
    {
        id = 'cycle',
        title = 'Cycle',
        dataType = 'string',
        searchable = true,
        browsable = true
    }, {
        id = 'type',
        title = 'Type',
        dataType = 'enum',
        values = {{
            value = 'feature',
            title = 'Feature'
        }, {
            value = 'photoessay',
            title = 'Photo Essay'
        }, {
            value = 'brief',
            title = 'Brief'
        }, {
            value = nil,
            title = ""
        }},
        searchable = true,
        browsable = true
    }, {
        id = 'section',
        title = 'Section',
        dataType = 'enum',
        values = Sections,
        searchable = true,
        browsable = true
    }, {
        id = 'slug',
        title = 'Slug',
        dataType = 'string',
        searchable = true,
        browsable = true
    }, {
        id = 'author',
        title = 'Article Author',
        dataType = 'string',
        searchable = true,
        browsable = true
    }, {
        id = 'online_print',
        title = 'Online or Print',
        dataType = 'string',
        searchable = true,
        browsable = true
    }, {
        id = 'contributor',
        title = 'Photo Contributor',
        dataType = 'string',
        searchable = true,
        browsable = true
    }}
}
