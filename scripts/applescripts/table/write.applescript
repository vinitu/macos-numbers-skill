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
    set wasOpen to false

    try
        if (count of argv) is not 4 then error "Usage: osascript scripts/table/write.applescript <file-path> <sheet> <table> <json>"

        set inputPath to my standardizePath(item 1 of argv)
        set sheetName to item 2 of argv
        set tableName to item 3 of argv
        set operationsValue to my normalizeOperations(my parseJson(item 4 of argv))

        if sheetName is "" then error "Sheet name is required"
        if tableName is "" then error "Table name is required"

        set {docRef, wasOpen} to my openDocument(inputPath)
        set sheetRef to my requireSheet(docRef, sheetName)
        set tableRef to my requireTable(sheetRef, tableName)
        set updatedCount to my applyWriteOperations(tableRef, operationsValue)

        tell application "Numbers"
            save docRef
        end tell

        set resultPayload to {|success|:true, |cellsUpdated|:updatedCount}
    on error errMsg number errNum
        set errorMessage to my formatError(errMsg)
    end try

    my closeDocumentIfNeeded(docRef, wasOpen)

    if errorMessage is not missing value then return my encodeJson({|error|:errorMessage})
    return my encodeJson(resultPayload)
end run

on applyWriteOperations(tableRef, operationsValue)
    tell application "Numbers"
        set columnCountValue to column count of tableRef
    end tell

    set updatedCount to 0
    repeat with opValue in operationsValue
        set opRecord to contents of opValue
        if class of opRecord is not record then error "Each write operation must be an object"

        try
            set rowIndex to (|row| of opRecord) as integer
            set columnIndex to (|col| of opRecord) as integer
            set cellValue to |value| of opRecord
        on error
            error "Each write operation must contain row, col, and value"
        end try

        if rowIndex is less than 0 then error "Row index must be 0 or greater"
        if columnIndex is less than 0 then error "Column index must be 0 or greater"
        if columnIndex is greater than or equal to columnCountValue then error "Column index is outside the table width"

        set cellIndex to (rowIndex * columnCountValue) + columnIndex + 1
        tell application "Numbers"
            set value of cell cellIndex of tableRef to cellValue
        end tell
        set updatedCount to updatedCount + 1
    end repeat

    return updatedCount
end applyWriteOperations

on normalizeOperations(parsedValue)
    if class of parsedValue is record then return {parsedValue}
    if class of parsedValue is list then return parsedValue
    error "Write payload must be a JSON object or array of objects"
end normalizeOperations

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

on requireSheet(docRef, sheetName)
    tell application "Numbers"
        repeat with sheetRef in every sheet of docRef
            if (name of contents of sheetRef) is sheetName then return contents of sheetRef
        end repeat
    end tell
    error "Sheet not found: " & sheetName
end requireSheet

on requireTable(sheetRef, tableName)
    tell application "Numbers"
        repeat with tableRef in every table of sheetRef
            if (name of contents of tableRef) is tableName then return contents of tableRef
        end repeat
    end tell
    error "Table not found: " & tableName
end requireTable

on openDocument(inputPath)
    set targetPath to my canonicalExistingPath(inputPath)
    set existingDoc to my findOpenDocument(targetPath)
    if existingDoc is not missing value then return {existingDoc, true}

    tell application "Numbers"
        open POSIX file targetPath
    end tell

    repeat 20 times
        delay 0.1
        set openedDoc to my findOpenDocument(targetPath)
        if openedDoc is not missing value then return {openedDoc, false}
    end repeat

    error "Document not found after opening: " & inputPath
end openDocument

on findOpenDocument(targetPath)
    tell application "Numbers"
        repeat with docRef in every document
            try
                if (POSIX path of (file of contents of docRef as alias)) is targetPath then return contents of docRef
            end try
        end repeat
    end tell
    return missing value
end findOpenDocument

on closeDocumentIfNeeded(docRef, wasOpen)
    if docRef is missing value then return
    if wasOpen then return
    try
        tell application "Numbers"
            close docRef saving no
        end tell
    end try
end closeDocumentIfNeeded

on canonicalExistingPath(pathText)
    set standardizedPath to my standardizePath(pathText)
    if my pathExists(standardizedPath) is false then error "File not found: " & standardizedPath
    return POSIX path of (POSIX file standardizedPath as alias)
end canonicalExistingPath

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

on formatError(errMsg)
    if errMsg is missing value then return "Unknown error"
    return errMsg as text
end formatError
