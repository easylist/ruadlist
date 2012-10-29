#!/usr/bin/python

import base64
import md5
import pickle
import re
import urllib

# Parse parameters
from optparse import OptionParser
optpars = OptionParser()
optpars.add_option("-c", "--config", action='store', default='listmerge.conf', 
                   dest='conffile', metavar='FILE',
                   help="read config from FILE (default: 'listmerge.conf')")
optpars.add_option("-o", "--output", action='store', default='merged.list', 
                   dest='outfile', metavar='FILE',
                   help="write merged list to FILE (default: 'merged.list')")
optpars.add_option("-k", "--keep", action='store_false', default=True, dest='removecom',
                   help="do not remove remove comments (default: remove)")
(options, args) = optpars.parse_args()

# Clean data
def clndata(data):
    data = data.replace('\xEF\xBB\xBF','')
    data = data.replace('\r','')
    data = re.sub('\n\n+','\n',data)
    return data

# Calculate and return base64-encoded MD5 checksum
def getcrc(data):
    cgen = md5.new()
    cgen.update(clndata(data))
    return base64.encodestring(cgen.digest()).replace('==','').strip()

# Download file marked to import in configuration and clean it up
def download(url, lmdate):
    attempts = 5
    while True:
        # Lets assume file is downloaded and proper but check later if we can
        isprop = True
        data = ''

        # Download a subscription file from the web
        webfile = urllib.urlopen(url)
        if webfile.getcode() == 200: # URL is valid and file exists
            clmdate = webfile.info().getheader('last-modified')
            fname = url.split('/')[-1]
            if lmdate <> clmdate:
                # Download file if it is not latest one
                data = webfile.read()
                cache = open(fname, 'w')
                cache.write(data)
                cache.close()
            else:
                # Load local copy of file if it was not changed
                print 'File ' + fname + ' was not changed, loading local copy.'
                try:
                    cache = open(fname, 'r')
                    data = cache.read()
                    cache.close()
                except IOError as e:
                    print 'Cache failure, loading file from the Web.'
                    data = webfile.read()
                    cache = open(fname, 'w')
                    cache.write(data)
                    cache.close()
        else:
            isprop = False
        webfile.close()

        # Check is file properly downloaded
        pat = re.compile('!\s*checksum[\s\-:]+([\w\+\/=]+)\n',
                         re.MULTILINE+re.IGNORECASE)
        m = pat.search(data)
        if m:
            csum = m.group(1)
            data = data.replace(m.group(0),'')
            if csum <> getcrc(data):
                isprop = False
        if not(isprop) and (attempts > 0):
            print 'Wrong checksum or URL, attempt to re-download.'
            attempts = attempts - 1
        else:
            break

    # If file properly downloaded remove additional info and return data
    if isprop:
        if options.removecom:
            data = re.sub('\n![^\n]*','\n',data)
            data = re.sub('\n+','\n',data)
        data = re.sub('^(\xEF\xBB\xBF)?\[[^\n]*\]\n','',data)
        return data, clmdate

# Read configuration
f = open(options.conffile,'r')
lines = f.readlines()
f.close()

# Restore information about last modified dates of subscriptions
lmdates = dict()
try:
    f = open('last-modified.db','rb')
    lmdates = pickle.load(f)
    f.close()
except IOError as e:
   print 'Missing last-modified.db, will be created from scratch.'

# Parse configuration and download files
res = ''
error = False
for line in lines:
    imp = line.strip().split(' ')
    if imp[0] <> 'import':
        res += line
    else:
        res += '! ' + '-' * 78 + '\n'
        res += '! ' + imp[1] + '\n'
        res += '! ' + '-' * 78 + '\n'
        lmdate = ''
        fname = imp[1].split('/')[-1]
        if fname in lmdates:
            lmdate = lmdates[fname]
        (data, lmdate) = download(imp[1], lmdate)
        lmdates[fname] = lmdate
        if data:
            res += data
        else:
            error = True

f = open('last-modified.db','wb')
pickle.dump(lmdates, f)
f.close()

# Final cleanup
res = clndata(res)
# Add UTF-8 BOM if missing
if res[:3] <> '\xEF\xBB\xBF':
    res = '\xEF\xBB\xBF' + res
# Add checksum
res = res.replace('\n','\n! Checksum: ' + getcrc(res) + '\n',1)

# Write merged list if all files imported fine
if not error:
    f = open(options.outfile,'w')
    f.write(res)
    f.close()
else:
    print 'ERROR: One of imported files were not downloaded successfully'
