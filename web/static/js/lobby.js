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
      state: metas[0].state
    }
  },

  render(presences){
    userList.innerHTML = Presence.list(presences, Lobby.listBy)
      .map(presence => `
        <li class="users">
          ${presence.user}
          <br>
          <small>in ${presence.state}</small>
          <a class="btn btn-default btn-xs" href="/games/${presence.user}">Join</a>
        </li>
      `)
      .join("")
  },
}
export default Lobby