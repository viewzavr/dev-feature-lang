//////////////////

feature "coview-category" {
  x: object 
      records=(m-eval {: known_records=@known_records id=@x.id | return (known_records || []).filter( x => x.params.id == id ) :})
}
feature "coview-record"

// filter_cats_func=func add_to=object

let known_cats = (find-objects-bf "coview-category")
let known_records = (find-objects-bf "coview-record")

// вход: массив идентификаторов категорий
// выход: список list в формате для add-object-dialog
fun "gather-cats" { |id_array|
  
  let my_cats = (m-eval {: cats=@known_cats id_array=@id_array |
    return cats.filter( x => id_array.indexOf( x.params.id )>=0 )
  :})

  //return (read @my_cats | map_geta "records" | arr_compact)
  //return (read @my_cats | map_geta "title" | arr_compact)

  return (@my_cats | map { |cat|
    list @cat.title @cat.records
  })
}

////////////////////

feature "computation" { object }
feature "data-artefact" { object }