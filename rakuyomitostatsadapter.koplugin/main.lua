local DataStorage = require("datastorage")
local Device = require("device")
local DocumentRegistry = require("document/documentregistry")
local logger = require("logger")
local SQ3 = require("lua-ljsqlite3/init")
local WidgetContainer = require("ui/widget/container/widgetcontainer")

local db_location = DataStorage:getSettingsDir() .. "/rakuyomi_file_map.sqlite3"
local DB_SCHEMA_VERSION = 20251005

logger.info("Loading RakuyomiToStatsAdapter")

local RakuyomiToStatsAdapter = WidgetContainer:extend{
    name = "rakuyomi_to_stats",
}

function RakuyomiToStatsAdapter:init()
    self.ui.menu:registerToMainMenu(self)
    self:checkInitDatabase()
end

function RakuyomiToStatsAdapter:addToMainMenu(_)
end

function RakuyomiToStatsAdapter:getMangaNameFromMangaId(manga_id)
    return string.gsub(manga_id, "%/series/[0-9A-Z]+/", "")
end

function RakuyomiToStatsAdapter:getPagesInManga(manga_path)
    local doc = DocumentRegistry:openDocument(manga_path)
    local page_count = doc:getPageCount()
    doc:close()
    return page_count
end

function RakuyomiToStatsAdapter:linkFileToManga(manga_path, manga_id, chapter_num)
    local manga_name = RakuyomiToStatsAdapter:getMangaNameFromMangaId(manga_id)
    local manga_pages = RakuyomiToStatsAdapter:getPagesInManga(manga_path)
    logger.dbg("@@@@@@@@@@@@@@@@@@")
    logger.dbg(string.format("Linking file (%s) to manga (%s) vol (%s) w (%s) pages", manga_path, manga_name, chapter_num, manga_pages))
    logger.dbg("@@@@@@@@@@@@@@@@@@")
    local conn = SQ3.open(db_location)
    local stmt = conn:prepare("INSERT INTO file_to_manga_map VALUES(?, ?, ?, ?) ON CONFLICT(file_path) DO NOTHING;")
    stmt:reset():bind(manga_path, manga_name, chapter_num, manga_pages):step()
    stmt:close()
    conn:close()
end

function RakuyomiToStatsAdapter:getPageOffset(file_path)
    local conn = SQ3.open(db_location)
    local stmt_get_info = conn:prepare("SELECT chapter_num, manga_name FROM file_to_manga_map WHERE file_path = ?")
    local manga_data = stmt_get_info:reset():bind(file_path):step()
    local manga_chapter_num = tonumber(manga_data[1])
    local manga_name = manga_data[2]

    local stmt_get_offset = conn:prepare("SELECT COALESCE(sum(chapter_pages), 0) FROM file_to_manga_map WHERE chapter_num < ? and manga_name = ?")
    local page_offset = tonumber(stmt_get_offset:reset():bind(manga_chapter_num, manga_name):step()[1])
    conn:close()
    return page_offset
end

function RakuyomiToStatsAdapter:getMangaForFilePathIfExists(file_path)
    local conn = SQ3.open(db_location)
    local stmt_manga_name = conn:prepare("SELECT manga_name FROM file_to_manga_map WHERE file_path = ?")
    local manga_name = stmt_manga_name:reset():bind(file_path):step()[1]
    conn:close()
    return manga_name
end

function RakuyomiToStatsAdapter:checkInitDatabase()
    local conn = SQ3.open(db_location)
    self:createDB(conn)
    conn:close()
end

function RakuyomiToStatsAdapter:createDB(conn)
    -- Make it WAL, if possible
    if Device:canUseWAL() then
        conn:exec("PRAGMA journal_mode=WAL;")
    else
        conn:exec("PRAGMA journal_mode=TRUNCATE;")
    end
    local initial_stmt = [[
        -- file_to_manga_map
        CREATE TABLE IF NOT EXISTS file_to_manga_map
        (
            file_path TEXT PRIMARY KEY,
            manga_name TEXT NOT NULL,
            chapter_num INTEGER NOT NULL,
            chapter_pages INTEGER NOT NULL
        );
        -- Indexes for getPageOffset
        CREATE INDEX IF NOT EXISTS idx_manga_chapter ON file_to_manga_map(manga_name, chapter_num);
        CREATE INDEX IF NOT EXISTS idx_chapter_num ON file_to_manga_map(chapter_num);
    ]]
    conn:exec(initial_stmt)

    -- DB schema version
    conn:exec(string.format("PRAGMA user_version=%d;", DB_SCHEMA_VERSION))
end

return RakuyomiToStatsAdapter
