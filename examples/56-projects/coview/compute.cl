coview-record title="Парсер CSV" type="cv-parse-csv" id="compute"

feature "cv-parse-csv" {
	x: computation 
	input=""
	title="Парсер CSV"
	output=(read @x.input | parse_csv)
	gui={ paint-gui @x }
	{
		gui {
			gui-tab {
				gui-slot @x "input" gui={ |in out| gui-text @in @out}
			}
		}
		param-info "input" in=true
		param-info "output" out=true
	}
}	