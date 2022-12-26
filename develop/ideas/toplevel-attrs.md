F-TOPLEVEL-ATTRS-TO-SCOPE

наверху скопа, можно добавлять аттрибуты (сиречь параметры) в скоуп.

было:

artmaker title="З1"
 code={ |art|
 x: object 
  title="Зал"
  possible=@x.txt_file?
  txt_file=(find-files @art.output? ".*\.(txt)$" | geta 0 default=null)
  artefact={ |gen|
  	 zal-data output=(load-file @x.txt_file | compalang)
  }
  {{ console-log "zal possible=" @x.possible }}

}

стало:

artmaker title="З1"
 code={ |art|
 object 
  title="Зал"
  possible=@txt_file?
  txt_file=(find-files @art.output? ".*\.(txt)$" | geta 0 default=null)
  artefact={ |gen|
     zal-data output=(load-file @txt_file | compalang)
  }
  {{ console-log "zal possible=" @possible }}

}