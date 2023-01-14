// показывает если загружаются файлы
// идея показывать не имена файлов а вообще мб кружки/символы
// а при наведении мышки уже имена

coview-record title="Прогресс загрузки файлов" type="v" cat_id="plugin"

feature "show-file-progress" {
  plugin title="Прогресс загрузки файлов"
  {  
    load "show-file-progress.cl"
  }
}

