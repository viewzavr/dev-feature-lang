 апарте. подумал что фичу мб делать так:
 feature "finerect" {

   r: rect color='red' count=5

   // все что дальше станет детьми rect
   circle
   triangle
   repeater model=@r.count {
     circle color=...
   }
 }

 еще был придумать как копировать параметры внешние и хорошо будет.
 feature "finerect" {

   object output=@r.output

   add-param count=5
   add-alias color="@r.color" ?

   r: rect color='red'

   // все что дальше станет детьми rect
   circle
   triangle
   repeater model=@count {
     circle color=...
   }
 }

и такая мысль:

 feature "finerect" ... и тут попер сразу объект?

 feature "finerect"
	r: rect color='red' count=5 {
	  circle
	  triangle
	}

ну вот. как вариант. особая форма опять. и получается заради меньше скобочек..