// Modified from https://github.com/OrionBrowser/DarkMode/blob/main/oriondark.js
const css = `
${options.dynamic ? '@media (prefers-color-scheme: dark) {' : ''}
:root {
    filter: invert(90%) hue-rotate(180deg) brightness(${options.brightness}%) contrast(${options.contrast}%) grayscale(${options.grayscale}%) sepia(${options.sepia}%);
    background: #fff;
} 
iframe, img, image, video, [style*="background-image"] { 
    filter: invert() hue-rotate(180deg) brightness(${options.brightness + 5}%) contrast(${options.contrast + 5}%);
}
${options.dynamic ? '}' : ''}
`;
const id = "webshade-browser-dark-theme";
const ee = document.getElementById(id);
if (null != ee) ee.parentNode.removeChild(ee);
style = document.createElement('style');
style.type = "text/css";
style.id = id;
if (style.styleSheet) style.styleSheet.cssText = css;
else style.appendChild(document.createTextNode(css));
document.head.appendChild(style);