// I'm just including this https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js above
// then adding it into the main tweak with this below. Nice and simple

// const options = { dynamic: true, brightness: 100, contrast: 100, grayscale: 0, sepia: 0, OLED: false };

// This implements webshade-fetch, which allows darkreader to avoid cors. If its not enabled, it will use the default fetch.
if (wsToken) {
    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.WebShadeCorsFetch) {
        const postMessage = window.webkit.messageHandlers.WebShadeCorsFetch.postMessage.bind(window.webkit.messageHandlers.WebShadeCorsFetch);
        // This checks if the handler is native code. If it isn't this 
        // means its most likely being impersonated by a script.
        // If this is the case, we use the default fetch to prevent token leakage.
        if (/\{\s+\[native code\]/.test(Function.prototype.toString.call(postMessage))) {
            const promises = {};
            const fakeFetch = (url) => {
                const id = Math.random().toString(36).slice(2);
                const promise = new Promise((resolve, reject) => {
                    promises[id] = { resolve, reject };
                });
                promises[id].timeout = setTimeout(() => {
                    promises[id].reject(new Error('No response'));
                    delete promises[id];
                }, 100000); // 100 secs

                postMessage({ url: encodeURI(url), id, token: wsToken });
                return promise;
            };
            window.webkit.WebShadeCorsFetchResponse = ({ id, type, message }) => {
                if (!id || !type) return;
                if (!promises[id]) return;
                clearTimeout(promises[id].timeout);
                if (type === 'data') {
                    const fakeFetch = {
                        text: () => Promise.resolve(atob(message)),
                        blob: () => Promise.resolve(new Blob([atob(message)])),
                    };
                    promises[id].resolve(fakeFetch);
                } else {
                    promises[id].reject(new Error(message));
                }
                delete promises[id];
            };
            DarkReader.setFetchMethod(fakeFetch);
        }
    }
}

const data = {
    brightness: options.brightness,
    contrast: options.contrast,
    grayscale: options.grayscale,
    sepia: options.sepia,
    darkSchemeBackgroundColor: options.OLED ? '#000' : '#181a1b',
}
if (options.dynamic) {
    DarkReader.auto(data);
} else {
    DarkReader.enable(data);
}