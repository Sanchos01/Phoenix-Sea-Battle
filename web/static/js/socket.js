import {Socket, Presence} from "phoenix"

let socket = new Socket("/socket", {
  params: {token: window.userToken},
  logger: (kind, msg, data) => {console.log(`${kind}:${msg}`,
  data)}
})

socket.connect()

let lobby             = socket.channel("room:lobby")
let chatInput         = document.querySelector("#chat-input")
let messagesContainer = document.querySelector("#messages")
let userList          = document.getElementById("userList")
let presences         = {}

let formatedTimestamp = (Ts) => {
  let date = new Date(Ts)
  return date.toLocaleString()
}

let listBy = (user, {metas: metas}) => {
  return {
    user: user,
    onlineAt: formatedTimestamp(metas[0].online_at)
  }
}

let render = (presences) => {
  console.log("rendering")
  userList.innerHTML = Presence.list(presences, listBy)
    .map(presence => `
      <li>
        ${presence.user}
        <br>
        <small>online since ${presence.onlineAt}</small>
      </li>
    `)
    .join("")
}

chatInput.addEventListener("keypress", event => {
  if(event.keyCode === 13 && chatInput.value != ""){
    lobby.push("new_msg", {body: chatInput.value})
    .receive("error", e => console.log(e))
    chatInput.value = ""
  }
})

lobby.on("presence_state", state => {
  presences = Presence.syncState(presences, state)
  render(presences)
})

lobby.on("presence_diff", diff => {
  presences = Presence.syncDiff(presences, diff)
  render(presences)
})

lobby.on("new_msg", payload => {
  let messageItem = document.createElement("li");
  messageItem.innerText = `[${formatedTimestamp(payload.timestamp)}] (${payload.user}): ${payload.body}`
  messagesContainer.appendChild(messageItem)
  messagesContainer.scrollTop = messagesContainer.scrollHeight
})

lobby.on("user_joined", payload => {
  let messageItem = document.createElement("li");
  messageItem.innerText = `[${formatedTimestamp(payload.timestamp)}] ${payload.user} Joined!`
  messagesContainer.appendChild(messageItem)
  messagesContainer.scrollTop = messagesContainer.scrollHeight
})

lobby.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
