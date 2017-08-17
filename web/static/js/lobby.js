import {Presence} from "phoenix"

let Lobby = {

  init(socket, element){
    if(!element) { return }
    socket.connect()
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( e => console.log("CLOSE", e) )
    let lobby = socket.channel("room:lobby")
    this.onReady(lobby)
  },

  onReady(lobby){
    let chatInput         = document.querySelector("#chat-input")
    let messagesContainer = document.querySelector("#messages")
    let userList          = document.querySelector("#userList")
    let presences         = {}

    chatInput.addEventListener("keypress", event => {
      if(event.keyCode === 13 && chatInput.value != ""){
        lobby.push("new_msg", {body: chatInput.value})
          .receive("error", e => console.log(e))
        chatInput.value = ""
      }
    })

    lobby.on("presence_state", state => {
      presences = Presence.syncState(presences, state)
      this.render(presences)
    })

    lobby.on("presence_diff", diff => {
      presences = Presence.syncDiff(presences, diff)
      this.render(presences)
    })

    lobby.on("new_msg", payload => {
      let messageItem = document.createElement("div");
      messageItem.innerText = `[${this.formatedTimestamp(payload.timestamp)}] (${payload.user}): ${payload.body}`
      messagesContainer.appendChild(messageItem)
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    })

    lobby.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })
  
    lobby.onError(e => console.log("something went wrong", e))
    lobby.onClose(e => console.log("channel closed", e))
  },

  formatedTimestamp(Ts){
    let date = new Date(Ts)
    return date.toLocaleTimeString()
  },

  listBy(user, {metas: metas}){
    return {
      user: user,
      state: metas[0].state,
      gameId: metas[0].gameId,
      with: metas[0].with
    }
  },

  // states: 0 - in lobby; 1 - game, wait opponent; 2 - game, full; 3 - game, ended
  render(presences){
    userList.innerHTML = Presence.list(presences, Lobby.listBy)
      .map(function (presence) {
        switch (presence.state) {
          case 0:
          return `
            <li class="users">
              ${presence.user}
              <br>
              <small>in lobby</small>
            </li>
          `
          case 1:
          return `
            <li class="users">
              ${presence.user}
              <br>
              <small>in game</small>
              <a class="btn btn-default btn-xs" href="/game/${presence.gameId}">Join</a>
            </li>
          `
          case 2:
          return `
            <li class="users">
              ${presence.user}
              <br>
              <small>in game with ${presence.with}</small>
            </li>
          `
          case 3:
          return `
            <li class="users">
              ${presence.user}
              <br>
              <small>game ended</small>
            </li>
          `
          default:
          return `
            <li class="users">
              ${presence.user}
              <br>
              <small>Unknown state</small>
            </li>
          `
        }
      })
      .join("")
  },
}
export default Lobby