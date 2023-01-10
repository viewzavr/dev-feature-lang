feature "gui" {
 y: object {{ catch_children "code" external=true }}
}

// задача - добавить табу inspect всем гуи-объеткам
// желательно через модификатор. как?
/*
find-object-bf "gui" | x-modify {
 x-append-param code={
   gui-tab "debug" {
     ...
   }
 }
 или x-set-param code += { ..... } ?
}
*/

// find-object-bf "gui" | insert_children .. - не сработает

feature "gui-add-inspect-tab" {
 object {}
}

append_feature "gui" "gui-add-inspect-tab"