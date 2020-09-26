
#define DEBUG_LINE_ID __FILE__ & " " & __FUNCTION__ & "(" & __LINE__ & ") "
#define DEBUG_LOG(_X_) LogLn(DEBUG_LINE_ID & (_X_))
#define DEBUG_LOG_REWRITE(_X_) LogLn(DEBUG_LINE_ID & (_X_), true)

declare sub LogLn(byref AText as const string, byref ARewrite as const boolean = false)

#include once "log.bas"
