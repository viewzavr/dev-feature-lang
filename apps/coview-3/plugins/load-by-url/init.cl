coview-record title="Загрузить из URL" type="plugin-from-url" cat_id="plugin"

feature "plugin-from-url" {
  p: plugin title="Загрузить из URL" url=""
  {  
    gui {
      gui-tab "main" {
        text "Укажите URL с compalang-файлом. Он будет загружен."
        gui-slot @p "url" gui={ |in out| gui-string @in @out }
      }
    }
    load @p.url
  }
}