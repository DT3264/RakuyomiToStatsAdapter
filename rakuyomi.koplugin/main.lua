function Rakuyomi:openLibraryView()
  local onChapterSelected = function(manga_path, manga_id)
      if self.ui and self.ui.rakuyomi_to_stats then
          self.ui.rakuyomi_to_stats:linkFileToManga(manga_path, manga_id)
      end
  end
  LibraryView:fetchAndShow(onChapterSelected)
  -- ...
end