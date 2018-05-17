export default function (url, options = {}) {
  if (!options.cache) {
    url += ((-1 == url.indexOf("?")) ? "?" : "&") + "_=" + new Date().getTime();
  }

  var method = options.method || "GET";

  var xhr = new XMLHttpRequest();
  xhr.open(method, url);

  for (let header in (options.headers || {})){
    xhr.setRequestHeader(header, options.headers[header]);
  }

  xhr.onreadystatechange = () => {
    if (xhr.readyState === 4) {
      let status = xhr.status;

      if (status >= 200 && (status < 300 || status === 304)) {
        if (options.success) {
          options.success(xhr.responseText);
          pw.broadcast("pw:request:succeeded");
        }
      } else {
        if (options.error) {
          options.error(xhr, xhr.statusText);
          pw.broadcast("pw:request:failed");
        }
      }
    }

    pw.broadcast("pw:request:completed");
  }

  if (method !== "GET") {
    let $token = document.querySelector("meta[name='pw-authenticity-token']");
    let $param = document.querySelector("meta[name='pw-authenticity-param']");

    if ($token && $param) {
      if (!options.data || !options.data[$param.getAttribute("content")]) {
        if (!options.data) {
          options.data = {};
        }

        options.data[$param.getAttribute("content")] = $token.getAttribute("content");
      }
    }
  }

  var data;
  if (options.data) {
    xhr.setRequestHeader("Content-Type", "application/json");
    data = JSON.stringify(options.data);
  }

  xhr.send(data);

  pw.broadcast("pw:request:dispatched");

  return xhr;
};
