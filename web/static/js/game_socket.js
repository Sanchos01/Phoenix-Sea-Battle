import {Presence} from "phoenix"

let GameSocket = {

  init(socket, element, gameId){
    if(!element) { return }
    socket.connect()
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( e => console.log("CLOSE", e) )
    let lobby = socket.channel("room:lobby", {game: `${gameId}`})
    let game = socket.channel(`game:${ gameId }`)
    this.onReady(game, lobby, gameId)
  },

  onReady(game, lobby, gameId){
    let chatInput         = document.querySelector("#chat-input")
    let messagesContainer = document.querySelector("#messages")
    let presences         = {}

    chatInput.addEventListener("keypress", event => {
      if(event.keyCode === 13 && chatInput.value != ""){
        game.push("new_msg", {body: chatInput.value})
          .receive("error", e => console.log(e))
        chatInput.value = ""
      }
    })

    game.on("new_msg", payload => {
      let messageItem = document.createElement("div");
      messageItem.innerText = `(${payload.user}): ${payload.body}`
      messagesContainer.appendChild(messageItem)
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    })

    game.on("presence_diff", diff => {
      presences = Presence.syncDiff(presences, diff)
      let users_count = Presence.list(presences, function(user, {metas: metas}){return user}).length
      if (users_count >= 2){
        lobby.push("close_state", {body: gameId})
      }
    })

    lobby.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

    lobby.onError(e => console.log("something went wrong", e))
    lobby.onClose(e => console.log("channel closed", e))

    game.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    game.onError(e => console.log("something went wrong", e))
    game.onClose(e => console.log("channel closed", e))
  },

  formatedTimestamp(Ts){
    let date = new Date(Ts)
    return date.toLocaleTimeString()
  },
}
export default GameSocket