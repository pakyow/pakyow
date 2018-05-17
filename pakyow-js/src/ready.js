export default function(callback) {
  if (document.readyState === "interactive" || document.readyState === "complete") {
   callback()
  } else {
    document.addEventListener("DOMContentLoaded", callback);
  }
};
