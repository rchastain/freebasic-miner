
sub LogLn(AText as string, ARewrite as boolean)
#ifdef DEBUG
  const as string CFileName = "miner.log"
  dim as integer LFile = freefile
  if ARewrite then kill CFileName
  open CFileName for append as LFile
  print #LFile, time & " " & AText
  close LFile
#endif
end sub
