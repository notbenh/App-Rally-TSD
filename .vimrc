autocmd BufWritePost * call system("git st >/dev/null 2>&1 && git add -A && git ci -m 'automated'")
