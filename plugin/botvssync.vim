" Vim sync plugin for BotVS
" http://www.botvs.com
"

function! ShortEcho(msg)
  " regular :echomsg is supposed to shorten long messages when shortmess+=T but it does not.
  " under "norm echomsg", echomsg does shorten long messages.
  let saved=&shortmess
  set shortmess+=T
  exe "norm :echomsg a:msg\n"
  let &shortmess=saved
endfunction

function! SyncBotVS()
PyForBotVS << EOF
import vim
import sys

import socket
socket.setdefaulttimeout(20)

import time, os, re
import json

try:
    from urllib import urlopen, urlencode
    reload(sys)   
    sys.setdefaultencoding('utf8')
except ImportError:
    from urllib.request import urlopen
    from urllib.parse import urlencode
__version__ = '0.0.1'
rsync_url = "https://www.botvs.com/rsync"

def SyncFile(filename, token, content):
    success = False
    errCode = 0
    msg = ""
    try:
        data = {'token': token, 'method':'push', 'content': content, 'version': __version__, 'client': 'vim'}
        resp = json.loads(urlopen(rsync_url, urlencode(data).encode('utf8')).read().decode('utf8'))
        errCode = resp["code"]
        if errCode < 100:
            success = True
            msg = 'Hi ' + resp['user'] + ", [" + filename + "] saved to [" + resp['name'] + "]"
        else:
            if errCode == 405:
                msg = 'Sorry, ' + resp['user'] + ", sync failed ! Renew the token of [" + resp['name'] + "]"
            elif errCode == 406:
                msg = 'BotVS plugin for sublime need update ! http://www.botvs.com'
            else:
                msg = "BotVS sync [" + filename + " ] failed, errCode: %d, May be the token is not correct !" % errCode
            
    except:
        msg = str(sys.exc_info()[1]) + ", BotVS sync failed, please retry again !"
    vim.command('call ShortEcho("' + msg.replace('"', '\"') +'")')
    return success

cur_buf = vim.current.buffer
pattern = re.compile(r'botvs@([a-zA-Z0-9]{32})')
content = []
token = None
for line in cur_buf:
	skip = False
	if not token:
		match = pattern.search(line)
		if match:
			token = match.group(1)
			skip = True
	if not skip:
		content.append(line)
if token:
	SyncFile(vim.eval('bufname("%")'), token, '\n'.join(content))
EOF

endfunction

if has('python')
  command! -nargs=* PyForBotVS python <args>
elseif has('python3')
  command! -nargs=* PyForBotVS python3 <args>
endif

autocmd BufWritePost *.js :call SyncBotVS()
autocmd BufWritePost *.py :call SyncBotVS()

