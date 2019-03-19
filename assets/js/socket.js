import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()

document.addEventListener("DOMContentLoaded", event => {
  let el = document.getElementById("messages");
  el.scrollTop = el.scrollHeight;
});

Array.from(document.getElementsByName("chat-input")).map(elem => {
  elem.addEventListener("keyup", e => {
    if(event.keyCode === 13 && elem.value != ""){
      elem.value = ""
      let el = document.getElementById("messages");
      el.scrollTop = el.scrollHeight;
    }
  })
});
