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
        if (count of argv) is not 3 then error "Usage: osascript scripts/table/read.applescript <file-path> <sheet> <table>"

        set inputPath to my standardizePath(item 1 of argv)
        set sheetName to item 2 of argv
        set tableName to item 3 of argv
        if sheetName is "" then error "Sheet name is required"
        if tableName is "" then error "Table name is required"

        set {docRef, wasOpen} to my openDocument(inputPath)
        set sheetRef to my requireSheet(docRef, sheetName)
        set tableRef to my requireTable(sheetRef, tableName)
        set resultPayload to {|file|:inputPath, |sheets|:{{|name|:sheetName, |tables|:{my readTable(tableRef)}}}}
    on error errMsg number errNum
        set errorMessage to my formatError(errMsg)
    end try

    my closeDocumentIfNeeded(docRef, wasOpen)

    if errorMessage is not missing value then return my encodeJson({|error|:errorMessage})
    return my encodeJson(resultPayload)
end run

on readTable(tableRef)
    tell application "Numbers"
        set tableName to name of tableRef
        set rowCountValue to row count of tableRef
        set columnCountValue to column count of tableRef
        set headerRowCountValue to header row count of tableRef
        set headerColumnCountValue to header column count of tableRef
    end tell

    set headersValue to {}
    if headerRowCountValue is greater than 0 then
        repeat with columnIndex from 1 to columnCountValue
            set end of headersValue to my formattedCellValue(tableRef, columnIndex)
        end repeat
    end if

    set rowsValue to {}
    if rowCountValue is greater than headerRowCountValue then
        repeat with rowIndex from (headerRowCountValue + 1) to rowCountValue
            set rowValues to {}
            set hasData to false
            repeat with columnIndex from 1 to columnCountValue
                set cellIndex to ((rowIndex - 1) * columnCountValue) + columnIndex
                set cellValue to my formattedCellValue(tableRef, cellIndex)
                if cellValue is not "" then set hasData to true
                set end of rowValues to cellValue
            end repeat
            if hasData then set end of rowsValue to rowValues
        end repeat
    end if

    return {|name|:tableName, |rowCount|:rowCountValue, |columnCount|:columnCountValue, |headerRowCount|:headerRowCountValue, |headerColumnCount|:headerColumnCountValue, |headers|:headersValue, |rows|:rowsValue}
end readTable

on formattedCellValue(tableRef, cellIndex)
    tell application "Numbers"
        try
            set cellValue to formatted value of cell cellIndex of tableRef
            if cellValue is missing value then return ""
            return cellValue as text
        on error
            return ""
        end try
    end tell
end formattedCellValue

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
