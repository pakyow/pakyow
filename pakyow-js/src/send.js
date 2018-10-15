export default function (url, options = {}) {
  var id = new Date().getTime();

  if (!options.cache) {
    url += ((-1 == url.indexOf("?")) ? "?" : "&") + "_=" + id;
  }

  var method = options.method || "GET";

  var xhr = new XMLHttpRequest();
  xhr.id = id;
  xhr.open(method, url);
  xhr.setRequestHeader("Pw-Ui", pw.version);

  for (let header in (options.headers || {})){
    xhr.setRequestHeader(header, options.headers[header]);
  }

  xhr.onreadystatechange = () => {
    if (xhr.readyState === 4) {
      let status = xhr.status;

      if (status >= 200 && (status < 300 || status === 304)) {
        if (options.success) {
          options.success(xhr, xhr.responseText);
        }
      } else {
        if (options.error) {
          options.error(xhr, xhr.statusText);
        }
      }

      if (options.complete) {
        options.complete(xhr);
      }
    }
  }

  xhr.onprogress = (event) => {
    if (options.progress) {
      options.progress(event);
    }
  }

  var data = options.data;
  if (!(data instanceof FormData)) {
    if (method !== "GET") {
      let $token = document.querySelector("meta[name='pw-authenticity-token']");
      let $param = document.querySelector("meta[name='pw-authenticity-param']");

      if ($token && $param) {
        if (!data || !data[$param.getAttribute("content")]) {
          if (!data) {
            data = {};
          }

          data[$param.getAttribute("content")] = $token.getAttribute("content");
        }
      }
    }

    if (data) {
      xhr.setRequestHeader("Content-Type", "application/json");
      data = JSON.stringify(data);
    }
  }

  xhr.send(data);

  return xhr;
};
