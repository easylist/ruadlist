let fs = require('fs');
(()=>{
    'use strict';

    console.log('Loading filters...')
    let cssFileName = './css-fixes-experimental.txt';
    let fixesFileName = './ruadlist-fixes.user.css';
    let templateFileName = `${fixesFileName}.template`;
    let fileEncoding = 'utf8';
    let oldVersion = null;
    {
        let fd = fs.openSync(fixesFileName, 'r');
        let len = 256, buff = Buffer.alloc(len, ' ', fileEncoding);
        fs.readSync(fd, buff, 0, len, 0);
        oldVersion = /@version\s(\d+\.\d+\.\d+)[\r\n]+/.exec(buff.toString())[1];
        fs.closeSync(fd);
    }
    let version = null;
    console.log('Current version:', oldVersion);
    {
        let ctime = fs.statSync(cssFileName).ctime;
        let fmt = x => `${(x < 10 ? '0' : '')}${x}`;
        let [yr, mn, dy] = [ctime.getFullYear(), ctime.getMonth() + 1, ctime.getDate()];
        let [hr, mi] = [ctime.getHours(), ctime.getMinutes()];
        version = `0.${yr}${fmt(mn)}${fmt(dy)}.${hr > 0 ? hr : ''}${hr > 0 ? fmt(mi) : mi}`;
    }
    console.log('New version:', version)
    if (!version || !oldVersion)
        throw `Unable to determine version. Exit.`;
    if (oldVersion === version) {
        console.log(`Source didn't change. Exit.`);
        return;
    }
    let data = fs.readFileSync(cssFileName, fileEncoding);
    let template = fs.readFileSync(templateFileName, fileEncoding);
    if (!data || !template)
        throw 'Failed to read files!';

    template = template.replace('%version%', version);

    console.log('Parsing filters...')
    let filters = data.split(/[\r\n]+/);
    let filterParts = /^([-\w.,]+)#\??#(.+?)(\:style\((.+)\))?\s*$/;
    let isDeep = /\/deep\//;
    let styles = [];
    let strcomp = (a, b) => a == b ? 0 : (a < b ? -1 : 1);
    {
        let domains = new Map(),
            skipped = [],
            i = 0, idx = 0;

        for (let filter of filters) {
            let parts = filterParts.exec(filter);
            if (!parts)
                continue;

            let [rule, location, selector, skip, style] = parts;
            style = style || 'display: none !important';
            if (!(location && selector) || isDeep.test(selector)) {
                skipped.push(filter);
                continue;
            }
            if (!domains.has(location)) {
                domains.set(location, i);
                i++;
            }
            idx = domains.get(location);
            if (!styles[idx]) {
                styles[idx] = {
                    location: location,
                    rules: [{ selector: selector, style: style}]
                };
            } else {
                styles[idx].rules.push({ selector: selector, style: style});
            }
        }
        console.log(`Skipped rows:\n> ${skipped.join('\n> ')}`);
    }
    styles.sort((a, b) => strcomp(a.location, b.location));
    console.log('Domain blocks:', styles.length);

    console.log('Generating CSS code...');
    {
        let css = '';
        let rulecomp = (a, b) => strcomp(a.style, b.style) * 2 + strcomp(a.selector, b.selector);
        // UserStyles doesn't accept some first-level domains from PeerName and similar DNS
        let skipUnsupportedDomains = loc => !/\.lib$/.test(loc);
        for (let style of styles) {
            if (style.rules.length > 1) {
                style.rules.sort(rulecomp);
                let rules = [],
                    smap = new Map(),
                    i = 0, idx = 0;
                for (let rule of style.rules) {
                    if (!smap.has(rule.style)) {
                        smap.set(rule.style, i);
                        i++;
                    }
                    idx = smap.get(rule.style);
                    if (!rules[idx]) {
                        rule.selector = [rule.selector];
                        rules[idx] = rule;
                    } else {
                        rules[idx].selector.push(rule.selector);
                    }
                }
                style.rules = rules;
            }
            style.location = style.location.split(',').filter(skipUnsupportedDomains);
            // construct domains header
            css += `\n@-moz-document${style.location.length > 1 ? '\n  ' : ' '}domain("${style.location.join(`"),\n  domain("`)}") {`;
            for (let rule of style.rules) {
                let style = `\n        ${rule.style.replace(/;\s/g, ';\n        ')}`;
                let selectors = [];
                if (!(rule.selector instanceof Array)) {
                    selectors.push(rule.selector);
                } else {
                    rule.selector.sort(strcomp);
                    let pos, next, str = rule.selector.join(',');
                    let lim = 75;
                    while (str.length > lim && str.includes(',')) {
                        pos = str.indexOf(',');
                        next = str.indexOf(',', pos + 1);
                        while (next > 0 && next < lim) {
                            pos = next;
                            next = str.indexOf(',', pos + 1);
                        }
                        selectors.push(str.slice(0, pos));
                        str = str.slice(pos + 1);
                    }
                    selectors.push(str);
                }
                let joinedSelectors = `\n    ${selectors.join(',\n    ')}`.replace(/,/g, ', ');
                css += `${joinedSelectors} {${style}\n    }`;
            }
            css += '\n}\n';
        }
        template = template.replace('%css%', css);
    }
    if (template.includes('%css%'))
        throw 'Something went wrong with CSS generation!';

    fs.writeFileSync(fixesFileName, template, fileEncoding);
    console.log('Done.');
})();
