
function ReaderStatistics:initData()
    -- ...
    -- Override title and md5 if is a rakuyomi manga
    self:overrideBookTitleAndMd5IfIsManga()
    self.id_curr_book = self:getIdBookDB()
    -- ...
end

function ReaderStatistics:insertDB(updated_pagecount)
    -- ...
    local conn = SQ3.open(db_location)
    local page_offset = 0
    if self.ui.rakuyomi_to_stats then
        page_offset = self.ui.rakuyomi_to_stats:getPageOffset(self.ui.doc_settings.data.doc_path)
    end
    --...
    if duration > 0 then
        local adjusted_page = page + page_offset
        local adjusted_total_pages = self.data.pages + page_offset
        stmt:reset():bind(id_book, adjusted_page, ts, duration, adjusted_total_pages):step()
    end
    -- ...
     local sql_stmt = [[
        UPDATE book
        SET    pages = ?
        WHERE  id = ?;
    ]]
    stmt = conn:prepare(sql_stmt)
    local adjusted_book_pages = (updated_pagecount or self.data.pages) + page_offset
    stmt:reset():bind(adjusted_book_pages, id_book):step()
    -- ...
end

-- Add the following function below the initData function
function ReaderStatistics:overrideBookTitleAndMd5IfIsManga()
    if self.ui and self.ui.rakuyomi_to_stats then
        local doc_path = self.ui.doc_settings.data.doc_path
        local manga_name = self.ui.rakuyomi_to_stats:getMangaForFilePathIfExists(doc_path)
        if manga_name ~= nil then
            -- This is the name the manga is registred in the statistics database
            self.data.title = manga_name
            -- For subsequent chapters stats to contribute to the same manga,
            -- set the md5 (which is used as the ID to distinguish between books)
            -- as the manga name.
            self.doc_md5 = manga_name
        end
    end
end