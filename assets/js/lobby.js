import {Presence} from "phoenix"

let Lobby = {

  init(socket, element){
    if(!element) { return }
    socket.connect()
    socket.onOpen( ev => console.log("OPEN", ev) )
    socket.onError( ev => console.log("ERROR", ev) )
    socket.onClose( e => console.log("CLOSE", e) )
    let lobby = socket.channel("room:lobby")
    // this.onReady(lobby)
  },

  onReady(lobby){
    let chatInput         = document.querySelector("#chat-input")
    let messagesContainer = document.querySelector("#messages")

    chatInput.addEventListener("keypress", event => {
      if(event.keyCode === 13 && chatInput.value != ""){
        lobby.push("new_msg", {body: chatInput.value})
          .receive("error", e => console.log(e))
        chatInput.value = ""
      }
    })

    lobby.on("new_msg", payload => {
      lobby.params.last_seen_ts = payload.timestamp
      this.renderMsg(messagesContainer, payload)
    })

    lobby.on("pre_messages", resp => {
      resp.body.map(msg => {
        lobby.params.last_seen_ts = msg.timestamp
        this.renderMsg(messagesContainer, msg)
      })
    })

    lobby.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })
  
    lobby.onError(e => console.log("something went wrong", e))
    lobby.onClose(e => console.log("channel closed", e))
  },

  renderMsg(messagesContainer, msg){
    let messageItem = document.createElement("div");
    messageItem.innerText = `[${this.formatedTimestamp(msg.timestamp)}] (${msg.user}): ${msg.body}`
    Array.from(messagesContainer.children).slice(0, -19)
      .map(elem => messagesContainer.removeChild(elem))
    messagesContainer.appendChild(messageItem)
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  },

  formatedTimestamp(Ts){
    let date = new Date(Ts)
    return date.toLocaleTimeString()
  },
}
export default Lobby