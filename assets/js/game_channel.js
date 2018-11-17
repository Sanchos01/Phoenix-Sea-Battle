// import {Presence} from "phoenix"

let GameChannel = {

  onReady(game_channel, lobby, _gameId){
    let chatInput         = document.querySelector("#chat-input")
    let messagesContainer = document.querySelector("#messages")
    let adminButton       = document.querySelector("#game-control")
    let presences         = {}

    chatInput.addEventListener("keypress", event => {
      if(event.keyCode === 13 && chatInput.value != ""){
        game_channel.push("new_msg", {body: chatInput.value})
          .receive("error", e => console.log(e))
        chatInput.value = ""
      }
    })

    game_channel.on("new_msg", payload => {
      let messageItem = document.createElement("div");
      messageItem.innerText = `(${payload.user}): ${payload.body}`
      messagesContainer.appendChild(messageItem)
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    })

    lobby.join().receive("ok", resp => { console.log("Joined successfully", resp) })
                .receive("error", resp => { console.log("Unable to join", resp) })

    lobby.onError(e => console.log("something went wrong", e))
    lobby.onClose(e => console.log("channel closed", e))

    game_channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp) })
      .receive("error", resp => { console.log("Unable to join", resp) })

    game_channel.onError(e => console.log("something went wrong", e))
    game_channel.onClose(e => console.log("channel closed", e))
  },

  formatedTimestamp(Ts){
    let date = new Date(Ts)
    return date.toLocaleTimeString()
  },

  game_push(game_channel, event, body){ game_channel.push(event, {body: body}) }
}
export default GameChannel