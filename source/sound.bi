
#ifdef __FB_WIN32__
#include once "windows.bi"
#include once "win\mmsystem.bi"
#else
#include "inc/fbsound_dynamic.bi"
#define DWord uinteger
#endif

'Som
type TSons
  COn1  as DWord
  COn2  as DWord
  COff  as DWord
  Tempo as ubyte
end type

'Sons
#ifdef __FB_WIN32__
dim shared hMidiOut as HMIDIOUT
#else
dim shared as integer hEnterMenuItem, hFindGem, hFindObject, hDie
#endif
dim shared as TSons Som(1 to 6, 1 to 4), SomEx(1 to 7)
dim shared as ubyte Toca(1 to 6, 1 to 4), QtdNotasVenceu
dim shared as DWord UltNotaGameOver, resposta
dim shared as double TimerNotaVenceu

declare function InitSound as boolean
declare sub LoadSounds
declare sub FreeSound
declare sub Silencia
declare sub Sound01(OpMenu as integer, NewOpMenu as integer)
declare sub Sound02
declare sub Sound03
declare sub Sound04
declare sub Sound05
declare sub Sound06
declare sub Sound07(ASom as integer)
declare sub Sound08
declare sub Sound09
declare sub Sound10
declare sub Sound11
declare sub Sound12
declare sub Sound13(XTam1 as integer)
declare sub Sound14(Nota as integer)
declare sub Sound15(Nota as integer)
'Desativa os sons ligados
declare sub DesligaSons

#include once "sound.bas"
