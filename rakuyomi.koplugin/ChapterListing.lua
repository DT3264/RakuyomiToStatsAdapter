local ChapterListing = Menu:extend {
  -- ...
  -- callback to be called when a chapter is selected
  on_selected_chapter_callback = nil,
}
function ChapterListing:fetchAndShow(manga, onReturnCallback, accept_cached_results, onSelectedChapterCallback)
    -- ...
    UIManager:show(ChapterListing:new {
        -- ...
        on_selected_chapter_callback = onSelectedChapterCallback,
    })
    -- ...
end
function ChapterListing:openChapterOnReader(chapter, download_job)
    -- ..
    self.on_selected_chapter_callback(manga_path, chapter.manga_id)
    MangaReader:show({
      path = manga_path,
      on_end_of_book_callback = onEndOfBookCallback,
      on_return_callback = onReturnCallback,
    })
    -- ..
end