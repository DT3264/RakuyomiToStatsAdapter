function Rakuyomi:openLibraryView()
  local onChapterSelected = function(manga_path, manga_id, manga_chapters)
      if self.ui and self.ui.rakuyomi_to_stats then
          self.ui.rakuyomi_to_stats:linkFileToManga(manga_path, manga_id, manga_chapters)
      end
  end
  LibraryView:fetchAndShow(onChapterSelected)
  -- ...
end