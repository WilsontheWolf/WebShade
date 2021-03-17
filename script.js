// I'm just including this https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js above
// then adding it into the main tweak with this below. Nice and simple
DarkReader.setFetchMethod(window.fetch);
DarkReader.auto({
    brightness: 100,
    contrast: 100,
    sepia: 0
});