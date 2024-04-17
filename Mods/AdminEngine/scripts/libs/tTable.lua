tTable = {}

function tTable.contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

function tTable.index_of(intable, value)
    for i, v in ipairs(intable) do
        if v == value then
            return i
        end
    end
    return nil
end

function tTable.index_kindathesame(intable, value)
    for i, v in ipairs(intable) do
        if string.find(v, value) then
            return i
        end
    end
    return nil
end

function tTable.toggle(intable, value)
    if tTable.contains(intable, value) then
        table.remove(intable, tTable.index_of(intable, value))
        tTable.compress(intable)
    else
        table.insert(intable, value)
    end
end

function tTable.removeFirst(intable, value)
    if tTable.contains(intable, value) then
        table.remove(intable, tTable.index_of(intable, value))
    end
end

function tTable.compress(intable)
    local newTable = {}
    for _, v in ipairs(intable) do
        if not tTable.contains(newTable, v) then
            table.insert(newTable, v)
        end
    end
    return newTable
end

return tTable
