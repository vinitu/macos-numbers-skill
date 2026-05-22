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
        if (count of argv) is not 4 then error "Usage: osascript scripts/table/append.applescript <file-path> <sheet> <table> <json>"

        set inputPath to my standardizePath(item 1 of argv)
        set sheetName to item 2 of argv
        set tableName to item 3 of argv
        set rowsValue to my normalizeRows(my parseJson(item 4 of argv))

        if sheetName is "" then error "Sheet name is required"
        if tableName is "" then error "Table name is required"

        set {docRef, wasOpen} to my openDocument(inputPath)
        set sheetRef to my requireSheet(docRef, sheetName)
        set tableRef to my requireTable(sheetRef, tableName)
        set appendResult to my appendRows(tableRef, rowsValue)

        tell application "Numbers"
            save docRef
        end tell

        set resultPayload to {|success|:true, |rowsAppended|:(item 1 of appendResult), |cellsUpdated|:(item 2 of appendResult)}
    on error errMsg number errNum
        set errorMessage to my formatError(errMsg)
    end try

    my closeDocumentIfNeeded(docRef, wasOpen)

    if errorMessage is not missing value then return my encodeJson({|error|:errorMessage})
    return my encodeJson(resultPayload)
end run

on appendRows(tableRef, rowsValue)
    tell application "Numbers"
        set columnCountValue to column count of tableRef
        set startRowCount to row count of tableRef
    end tell

    repeat with rowValues in rowsValue
        set rowList to contents of rowValues
        if class of rowList is not list then error "Each appended row must be an array"
        if (count of rowList) is greater than columnCountValue then error "Append row is wider than table: " & (count of rowList) & " > " & columnCountValue
    end repeat

    tell application "Numbers"
        set row count of tableRef to (startRowCount + (count of rowsValue))
    end tell

    set cellsUpdated to 0
    repeat with rowOffset from 0 to ((count of rowsValue) - 1)
        set rowList to item (rowOffset + 1) of rowsValue
        repeat with columnOffset from 0 to ((count of rowList) - 1)
            set cellIndex to ((startRowCount + rowOffset) * columnCountValue) + columnOffset + 1
            tell application "Numbers"
                set value of cell cellIndex of tableRef to item (columnOffset + 1) of rowList
            end tell
            set cellsUpdated to cellsUpdated + 1
        end repeat
    end repeat

    return {(count of rowsValue), cellsUpdated}
end appendRows

on normalizeRows(parsedValue)
    if class of parsedValue is not list then error "Append payload must be a JSON array"
    if (count of parsedValue) is 0 then return {}

    set firstItemValue to item 1 of parsedValue
    if class of firstItemValue is list then return parsedValue
    return {parsedValue}
end normalizeRows

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
