// I'm just including this https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js above
// then adding it into the main tweak with this below. Nice and simple
const data = {
    brightness: options.brightness,
    contrast: options.contrast,
    grayscale: options.grayscale,
    sepia: options.sepia,
}
if (options.dynamic) {
    DarkReader.auto(data);
} else {
    DarkReader.enable(data);
}