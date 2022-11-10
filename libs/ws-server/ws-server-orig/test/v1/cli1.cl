load "./websocket.js misc"

c: ws-client url="ws://localhost:8100"
// on_open=(m_lambda "() => console.log('handl: opened')")

// m-eval "(cc) => { console.log('sending'); cc(555) }" @c.send
// console-log "hello" @c.send

get-remote-cell @c "@a->alfa" | set-cell-value 337

feature "get-remote-cell-read" "
  env.onvalues( [0,1], (cli,path) => {
    let cell = create_cell()
    cli.send({ name: 'get_cell', path: path, connection_id: env.$vz_unique_id })
    cli.on('message',(msg) => {
      if (msg.connection_id == env.$vz_unique_id && msg.cell_new_value)
        cell.set( msg.cell_new_value ) // получается мы в локальный канал пишем данные из удаленного канала
    })
  })
"

feature "get-remote-cell-write" "
  env.onvalues( [0,1], (cli,path) => {
    let cell = create_cell()
    cell.on('assigned',(v) => {
      cli.send({ name: 'write_cell', path: path, connection_id: env.$vz_unique_id, value: v })
    }
  })
"

// напрашивается remote get ?
// или вовсе удаленное создание объектов в мире удаленном.. и присылка output сюды?
/*
  т.е.
  let remote = ...
  
  remote-create @remote "read @a | get-cell 'alfa'"
  т.е. мы туды - компаланг строчку, а оно там создает процесс какой нам надо.. хм.. но как мы с ним общаемся?
  либо создавать вот представителя процесса.. но.. .я хочу не представителей процесса создавать, а работать с каналами
  мне так проще вроде как
  
  ну да.. и вроде как.. мне надо не то что output гонять.. т.е. я могу конечно.. но вроде как выгоднее.. подключаться к удаленным каналам...
  и с ними уже работать...

  ну тогда
  remote-connect @remote "@a->alfa"
*/

/* ну ок а что я хочу то от канала? писать туда? читать из него? что?

  let alfacell = (get-remote-cell @cli "@a->alfa")
  get-cell-value
*/