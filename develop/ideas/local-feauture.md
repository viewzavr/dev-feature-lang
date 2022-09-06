let some=..;

let f = (feature {
 ....
 text @some; // имеем доступ к локальному scope..
 ....
});

create-object @f;