use framework "Foundation"
use scripting additions

property NSString : a reference to current application's NSString
property NSJSONSerialization : a reference to current application's NSJSONSerialization
property NSUTF8StringEncoding : a reference to current application's NSUTF8StringEncoding
property NSFileManager : a reference to current application's NSFileManager

on run argv
    set resultPayload to missing value
    set errorMessage to missing value
    set docRef to missing value

    try
        if (count of argv) is not 2 then error "Usage: osascript scripts/document/create.applescript <file-path> <json-spec>"

        set targetPath to my standardizePath(item 1 of argv)
        set specValue to my parseJson(item 2 of argv)

        if class of specValue is not record then error "Create spec must be a JSON object"
        if my pathExists(targetPath) then error "Target file already exists: " & targetPath

        tell application "Numbers"
            set docRef to make new document
        end tell

        my applyCreateSpec(docRef, specValue)

        tell application "Numbers"
            save docRef in POSIX file targetPath
        end tell

        set resultPayload to {|success|:true, |file|:targetPath}
    on error errMsg number errNum
        set errorMessage to my formatError(errMsg)
    end try

    if docRef is not missing value then my closeDocument(docRef)

    if errorMessage is not missing value then return my encodeJson({|error|:errorMessage})
    return my encodeJson(resultPayload)
end run

on applyCreateSpec(docRef, specValue)
    tell application "Numbers"
        set sheetRef to first sheet of docRef
        set tableRef to first table of sheetRef
    end tell

    set sheetSpecs to {}
    try
        set sheetSpecs to |sheets| of specValue
    end try

    if class of sheetSpecs is not list then error "Create spec field 'sheets' must be an array"
    if (count of sheetSpecs) is greater than 1 then error "Creating more than one sheet is not supported by AppleScript in Numbers 15.1"
    if (count of sheetSpecs) is 0 then return

    set sheetSpec to item 1 of sheetSpecs
    if class of sheetSpec is not record then error "Each sheet spec must be an object"

    set sheetName to missing value
    try
        set sheetName to |name| of sheetSpec as text
    end try

    tell application "Numbers"
        if sheetName is not missing value and sheetName is not "" then set name of sheetRef to sheetName
    end tell

    set tableSpecs to {}
    try
        set tableSpecs to |tables| of sheetSpec
    end try

    if class of tableSpecs is not list then error "Create spec field 'tables' must be an array"
    if (count of tableSpecs) is greater than 1 then error "Creating more than one table per sheet is not supported by AppleScript in Numbers 15.1"
    if (count of tableSpecs) is 0 then return

    set tableSpec to item 1 of tableSpecs
    if class of tableSpec is not record then error "Each table spec must be an object"

    set tableName to missing value
    try
        set tableName to |name| of tableSpec as text
    end try

    tell application "Numbers"
        if tableName is not missing value and tableName is not "" then set name of tableRef to tableName
    end tell

    set headersValue to {}
    try
        set headersValue to |headers| of tableSpec
    end try
    if class of headersValue is not list then error "Create spec field 'headers' must be an array"

    set rowsValue to {}
    try
        set rowsValue to |rows| of tableSpec
    end try
    if class of rowsValue is not list then error "Create spec field 'rows' must be an array"

    set totalColumns to my tableColumnCount(headersValue, rowsValue)
    set totalRows to (count of rowsValue)
    if (count of headersValue) is greater than 0 then set totalRows to totalRows + 1
    if totalRows is less than 1 then set totalRows to 1

    tell application "Numbers"
        try
            set header column count of tableRef to 0
        end try
        set header row count of tableRef to ((count of headersValue) is greater than 0) as integer
        set column count of tableRef to totalColumns
        set row count of tableRef to totalRows
    end tell

    repeat with columnIndex from 1 to (count of headersValue)
        tell application "Numbers"
            set value of cell columnIndex of tableRef to item columnIndex of headersValue
        end tell
    end repeat

    set dataStartOffset to 0
    if (count of headersValue) is greater than 0 then set dataStartOffset to 1

    repeat with rowIndex from 1 to (count of rowsValue)
        set rowValues to item rowIndex of rowsValue
        if class of rowValues is not list then error "Each data row must be an array"
        repeat with columnIndex from 1 to (count of rowValues)
            set cellIndex to (((rowIndex + dataStartOffset) - 1) * totalColumns) + columnIndex
            tell application "Numbers"
                set value of cell cellIndex of tableRef to item columnIndex of rowValues
            end tell
        end repeat
    end repeat
end applyCreateSpec

on tableColumnCount(headersValue, rowsValue)
    set totalColumns to count of headersValue
    repeat with rowValues in rowsValue
        if class of rowValues is not list then error "Each data row must be an array"
        if (count of rowValues) is greater than totalColumns then set totalColumns to count of rowValues
    end repeat
    if totalColumns is less than 1 then set totalColumns to 1
    return totalColumns
end tableColumnCount

on parseJson(jsonText)
    set jsonData to (NSString's stringWithString:jsonText)'s dataUsingEncoding:NSUTF8StringEncoding
    set {parsedValue, errorObject} to NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(reference)
    if parsedValue is missing value then error (errorObject's localizedDescription() as text)

    if (parsedValue's isKindOfClass:(current application's NSDictionary)) as boolean then
        return parsedValue as record
    end if

    if (parsedValue's isKindOfClass:(current application's NSArray)) as boolean then
        return parsedValue as list
    end if

    return parsedValue
end parseJson

on encodeJson(payloadValue)
    set {jsonData, errorObject} to NSJSONSerialization's dataWithJSONObject:payloadValue options:0 |error|:(reference)
    if jsonData is missing value then error (errorObject's localizedDescription() as text)
    return (NSString's alloc()'s initWithData:jsonData encoding:NSUTF8StringEncoding) as text
end encodeJson

on standardizePath(pathText)
    return ((NSString's stringWithString:pathText)'s stringByStandardizingPath()) as text
end standardizePath

on pathExists(pathText)
    return (NSFileManager's defaultManager()'s fileExistsAtPath:pathText) as boolean
end pathExists

on closeDocument(docRef)
    try
        tell application "Numbers"
            close docRef saving no
        end tell
    end try
end closeDocument

on formatError(errMsg)
    if errMsg is missing value then return "Unknown error"
    return errMsg as text
end formatError
