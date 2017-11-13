let fs = require('fs');
(async () => {
    'use strict';
    const reader = filename => new Promise(
        (r, j) => fs.readFile(filename, 'utf8', (err, data) => {
            if (err)
                return j(err);
            return r(data);
        })
    ).catch((err) => console.log(err));

    let str = await reader('./ruadlist-fixes.css');
    let hdr = await reader('./css-fixes-experimental.header');

    if (!str || !hdr)
        return;

    str = str.replace(/\/\*.+?\*\//g,'').replace(/[\n\r]+/g,'').replace(/\s+/g,' ')
             .replace(/@media[^{]+\{.*?\}\s?\}\s?/g, '')
             .replace(/\s?@-moz-document\s/g,'\n').replace(/"\)\s?{\s?/g,'")#?#')
             .replace(/domain\("([^"]+)"\)/g,'$1').replace(/,\s/g,',')
             .replace(/\s?{(?![^>]*#>)\s?/g,':style(').replace(/;?\s?}\s?}/g,')')
             .replace(/;?\s?}(?![^>]*#>)\s?/g,'), ').replace(/\s?!/g,' !').replace(/"\s!/g,'"!');
    let result = [], disabled = [];
    let parts, domains, style, styles, activeStyle, i;
    for (let rule of str.split('\n')) {
        if (rule === '')
            continue;
        if (rule.startsWith('regexp') || rule.startsWith('url-prefix')) {
            disabled.push(`! ${rule}`)
            continue;
        }
        parts = rule.split('#?#');
        domains = parts[0];
        result.push(`! ---`);
        styles = parts[1].split(/,\s?(?!radial)(?!rgba)(?![^>]*#>)(?![^()]+\))/g);
        i = styles.length;
        activeStyle = null;
        while (i--) {
            style = styles[i].trim();
            if (style.includes(':style')) {
                activeStyle = style.match(/:style\(.*?\)$/)[0];
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
    // TODO: either add template and generate fixes list with template or update existing file

    hdr = hdr.replace('%filters%', result.join('\n')+'\n! --- disabled ---\n'+disabled.join('\n'))
    fs.writeFile('./css-fixes-experimental.txt', hdr, (err) => {
        if (err)
            return console.log('Unable to save JS:', err);
        console.log('Filters generated and saved.')
    });
})();
