@ECHO OFF
SET DIR=%~dp0
SET DIR="%DIR:~,-1%"
git -C %DIR% add -A
git -C %DIR% commit -m "updated"
git -C %DIR% push
SET DIR=
