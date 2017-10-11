let str = `...`;
str = str.replace(/\/\*.+?\*\//g,'').replace(/[\n\r]*/g,'')
         .replace(/\s+/g,' ').replace(/\s?@-moz-document\s/g,'\n').replace(/"\)\s?{\s?/g,'")#?#')
         .replace(/domain\("([^"]+)"\)/g,'$1').replace(/,\s/g,',').replace(/\s?{\s?/g,':style(')
         .replace(/;?\s?}}/g,')').replace(/;?\s?}\s?/g,'), ').replace(/\s?!/g,' !').replace(/"\s!/g,'"!');
let result = [];
let parts, domains, style, styles, activeStyle, i;
for (let rule of str.split('\n')) {
    parts = rule.split('#?#'); domains = parts[0];
    styles = parts[1].split(/,\s?(?!radial)(?!rgba)(?![^()]+\))/g);
    i = styles.length; activeStyle = null;
    while (i--) {
        style = styles[i].trim();
        if (style.includes(':style')) {
            activeStyle = style.match(/:style\(.*?\)/)[0];
            if (!/\(\s*display\s*:\s*none\s*!important\s*\)/.test(activeStyle))
                result.push(`${domains}#?#${style}`);
            else {
                result.push(`${domains}##${style.replace(activeStyle, '')}`);
                activeStyle = null;
            }
        } else {
            if (activeStyle)
                result.push(`${domains}#?#${style}${activeStyle}`);
            else
                result.push(`${domains}##${style}`);
        }
    }
}
result.join('\n');
