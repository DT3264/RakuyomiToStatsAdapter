
function ReaderStatistics:initData()
    -- ...
    -- Override title and md5 if is a rakuyomi manga
    self:overrideBookTitleAndMd5IfIsManga()
    self.id_curr_book = self:getIdBookDB()
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