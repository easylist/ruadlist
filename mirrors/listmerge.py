#!/usr/bin/python

import base64
import md5
import re
import urllib

def download(url):
    attempts = 5
    while True:
        # Lets assume file is downloaded and proper but check later if we can
        isprop = True
        data = ''

        # Download a subscription file from the web
        webfile = urllib.urlopen(url)
        if webfile.getcode() == 200:
            data = webfile.read()
        else:
            isprop = False
        webfile.close()

        # Check is file properly downloaded
        pat = re.compile('^.*!\s*checksum[\s\-:]+([\w\+\/=]+)\n',re.MULTILINE+re.IGNORECASE)
        m = pat.search(data)
        if m:
            csum = m.group(1) + '=='
            data = data.replace(m.group(0),'')
            data = re.sub('(\xEF\xBB\xBF|\r)','',data)
            data = re.sub('\n+','\n',data)
            cgen = md5.new()
            cgen.update(data)
            dsum = base64.encodestring(cgen.digest()).strip()
            if csum <> dsum:
                isprop = False
        if not(isprop) and (attempts > 0):
            print 'Wrong checksum or URL, attempt to re-download.'
            attempts = attempts - 1
        else:
            break

    # If file properly downloaded remove additional info and return data
    if isprop:
        data = re.sub('^\[[^\n]*\]\n','',data)
        return data

# Read configuration
f = open('listmerge.conf')
lines = f.readlines()
f.close()

# Parse configuration and download files
res = ''
error = False
for line in lines:
    imp = line.strip().split(' ')
    if imp[0] <> 'import':
        res += line
    else:
        res += '! ' + line
        data = download(imp[1])
        if data:
            res += data
        else:
            error = True

# Write merged list if all files imported fine
if not error:
    f = open('merged.list','w')
    f.write(res)
    f.close()
else:
    print 'ERROR: One of imported files were not downloaded successfully'
