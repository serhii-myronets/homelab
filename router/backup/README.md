# The router's backup key

`authorized_key` is the line the router needs so that core's nightly
`router-backup` job (core/03-gitops/apps/system/storage/router-backup) can
fetch its configuration. The key it names can do one thing: the line forces
`sysupgrade -b -`, which writes the backup GL.iNet's own UI makes to the
connection, and refuses forwarding and a terminal. The private half is in
Infisical at `/system/router-backup/SSH_PRIVATE_KEY`.

Add it once, and again after a reflash, in LuCI: System, Administration,
SSH-Keys - paste the whole line, options included. Nothing installs it over
ssh (decisions/0007).
