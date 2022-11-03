load "./websocket.js misc ./remote2.cl new-modifiers"

s: ws-server port=8100 on_message=(m-lambda "(client,msg) => {
  console.log('got message',msg)
}")

read @s | x-modify {
  m-on 'message' (m-lambda "() => console.log('qq!!!!!!!')")
}

a: object alfa=1 beta=2

console-log @a.alfa

object-on-server @s