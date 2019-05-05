// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"
import "phoenix_html"
import LiveSocket from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()

document.addEventListener("DOMContentLoaded", _event => {
  let el = document.getElementById("messages");
  if (el != undefined) {
    el.scrollTop = el.scrollHeight;
  }
});

Array.from(document.getElementsByName("chat-input")).map(elem => {
  elem.addEventListener("focus", event => {
    if(event.sourceCapabilities === null && elem.value != ""){
      elem.value = "";
      let el = document.getElementById("messages");
      el.scrollTop = el.scrollHeight;
    }
  })
});
