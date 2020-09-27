
' FreeBASIC Miner

#include once "fbgfx.bi"
#include once "file.bi"
#include once "log.bi"
#include once "sound.bi"
#include once "types.bi"

#if __fb_lang__ = "fb"
using FB
#endif

function Clock() as double
' https://www.freebasic.net/forum/viewtopic.php?p=276085#p276085
  static as integer init = 0
  static as double startTimer
  if init = 0 then
    init = 1
    startTimer = timer
  end if
  return timer - startTimer
end function

#define RGBA_A(c) (cuint(c) shr 24)
#define RGBA_R(c) (cuint(c) shr 16 and 255)
#define RGBA_G(c) (cuint(c) shr 8 and 255)
#define RGBA_B(c) (cuint(c) and 255)
#define Magenta &HFFFF00FF
#define FontBitmapWidth 838
#define MaxUndo 49
#define DefaultLanguage "Portuguese"

const CAppName = "FreeBASIC Miner"
const CAppVer  = "1.1"
const CBuild   = "build " & __DATE__ & " " & __TIME__ & " " & __FB_SIGNATURE__
const CAppInfo = CAppName & " " & CAppVer & " " & CBuild
const C255     = chr(255)

declare sub EscreveNumero(byval Numero as long, Comprimento as integer, X1 as integer, Y1 as integer, PReenche as integer)
declare sub Escreve(byval Texto as string, x1 as integer, y1 as integer, Bold as integer = 0, BoldV as integer = 0)
declare sub EscreveCentro(byval Texto as string, x1 as integer, Bold as integer = 0, BoldV as integer = 0)
declare sub EscrevePT(Pontos as  integer, X as integer, Y as integer, CJCarac as integer)
declare function LargTexto(byval Texto as string, Bold as integer = 0) as integer
declare sub IniciaJogo
declare sub IniciaVida
declare sub LoadMine(NMina as integer, SoQuant as integer = 0)
declare sub LoadCustomMine(NMina as integer, Editando as integer = 0)
declare sub LeMinaDet(Editando as integer = 0)
declare sub SearchCustomMines
declare sub Desenha
declare sub Joga
declare sub PegaObj(POX as integer, POY as integer)
declare function EmpurraObj(byval POX as integer, byval POY as integer, byval MDir as integer, byval Peso as integer, byval Quant as integer) as integer
declare sub Explode(byval EXX as integer, byval EXY as integer, byval XTam as integer)
declare sub LimpaMina
declare function EntersTop10 as integer
declare sub LeTopDez
declare sub TrocaTelas
declare sub MontaTopDez
declare sub LimpaTopDez
declare sub Mensagem(QCor as integer, Tipo as integer, T1 as string, T2 as string, T3 as string, OX as integer = 400, OY as integer= 300, Opcao as integer = 0)
declare sub DesBox(h as integer, V as integer, QCor as integer, OX as integer = 400, OY as integer = 300)
declare sub PutLogo(LX as integer, LY as integer)
declare sub PlaySoundGameOver
declare sub PlaySoundGameWon
declare sub MarcaPt(Pontos as integer, X as integer, Y as integer)
declare function CTRX as integer
declare function CTRY as integer
declare function ProximaTeclaDemo as string
declare sub DrawProgressBar(APercent as integer)
declare sub RegravaConfig
declare function LoadLanguage(ALang as string) as integer
declare sub LoadLanguageNames
declare sub DrawBackground
declare sub ConvertPointsToExtraLife(APoints as integer)
declare sub CalculaBonusTempo
declare sub GetMouseState
declare sub MudaStatus(NovoStatus as integer)
declare sub LimpaTeclado(IncLMTec as integer = 0)
' Editor
declare sub Edita
declare sub EscreveNumeroPeq(byval Numero as integer, X1 as integer, Y1 as integer)
declare sub SalvaMina(ParaTestar as integer = 0)
declare sub Dlinha(x1 as integer, y1 as integer, x2 as integer, y2 as integer, QualCor as integer)
declare sub CopiaMMinEd
declare sub CopiaMEdMin
declare sub EncerraTeste
declare sub DesenhaItem(ITX as integer, ITY as integer, ITN as integer)
declare function MaiorColuna as integer
declare function MaiorLinha as integer
declare function ContaTesouros as integer
declare function PosMouseEd() as integer
declare sub FazRedo
declare sub FazUndo
declare sub ClearEditorMine
declare function CloseUnsavedMineConfirmation as integer
declare sub SwapEDXY
declare sub GravaUndo
declare function EndOfTestConfirmation as integer

' Armazenamento das imagens
dim shared as any ptr GBitmap(281)
' Mensagens de pontos na tela
dim shared as TMessage GMessage(20)
' Recordes
dim shared GBestScore(10) as TBestScore
' Menu
dim shared as integer OpMenu, Opcao1, PosTop10, Mina1, Mina2, XM, YM
' Genéricas
dim shared as integer Iniciado, MapX, MapY, ProxMsg, LenMSG, EncerraEditor
dim shared as string GKey, GKeyBefore
dim shared as uinteger CorRGB, CorRGB2
' Fonte
dim shared as string Lt_
dim shared as integer PosLetra(100, 1)
' Screen
dim shared ScrAtiva as integer
' Idiomas
dim shared as string GLangName(15), GCurrLangName
dim shared as integer GLangCount, GCurrLangIndex
' Timer
dim shared as uinteger ATimer, NTimer
dim shared NumFPS(5) as integer
dim shared NomFPS(5) as string
dim shared as double GTimeStart
' Jogo
dim shared GJogo as TJogo
dim shared GBoneco as TBoneco
dim shared GMina as TMina
dim shared PontoTesouro(7 to 22) as integer
dim shared as integer TmpSleep, GBonus, Quadros, ultQuadros
dim shared as double GTimer1, GTimer2
' Explosões
dim shared Explosao(10) as TExplosao
' Comportamentos de objetos
dim shared Comport(13) as TComportamento
' Tipos de objetos
dim shared GObjectData(84) as TObjectData
' Tiles: fundo - layer 0 (0 = água)
dim shared as ubyte Fundo(-1 to 100, -1 to 60)
' Tiles: objetos - layer 1
dim shared as TObj GObject(-1 to 100, -1 to 60)
' Tiles: frente - layer 2
dim shared as ubyte Frente(-1 to 100, -1 to 60)
' Imagens do boneco
dim shared Parado(5) as integer
dim shared Movendo(7, 3) as integer
dim shared Usando(2, 1) as integer
' Tela inicial
dim shared as integer GGrad, GRed, GGreen, GBlue
' Modo demonstração
dim shared as string TeclasDemo
dim shared as integer PositDemo, DemoW1, DemoW2, DemoCiclo, MensDemo, TempMens
dim shared as double GDemoTimer
' Minas personalizadas
dim shared as integer MinaPers(999), SelPers(999), QuantPers, PersTemp
' Textos
dim shared as string GText(159)
' Mouse
dim shared as integer GMX, GMY, GMB, GMXOld, GMYOld, GMBOld, GMBDown, GMBUp, MouseSimNao, GMMove, MouseSobre, GMW, GMWOld, MouseWDir
' Editor
dim shared as TMina MinaEd
dim shared as string GLMKey, GUMKey
dim shared as integer EdX1, EdX2, EdY1, EdY2, EdMOn, EdShow, PrimeiroItem, ItemSel
dim shared as integer EDXX1, EDXX2, EDYY1, EDYY2, EdGrid, PosMouse
' Undo
dim shared as integer MatrizAtual, MatrizRedoLimite, MatrizUndoLimite, EdMovendoUndo, BonecoX(MaxUndo), BonecoY(MaxUndo)
dim shared as ubyte UndoFundo(MaxUndo, -1 to 100, -1 to 60), UndoFrente(MaxUndo, -1 to 100, -1 to 60), UndoObjeto(MaxUndo, -1 to 100, -1 to 60)
' Fonte
Lt_ = "ABCDEFGHIJKLMNOPQRSTUVWXYZÇÁÉÍÓÚÂÊÔÃÕÀabcdefghijklmnopqrstuvwxyzçáéíóúâêôãõà.,:?!0123456789-+'/()=_>|"

DEBUG_LOG_REWRITE(CAppInfo)
GLangName(0) = DefaultLanguage
windowtitle CAppName
screen 19, 32, 2
randomize
GRed = int(rnd * 2)
GGreen = int(rnd * 2)
GBlue = int(rnd * 2)
GGrad = 0
DrawBackground
draw string (25, 500), "Carregando FreeBASIC Miner..."
line (20, 520)-(779, 554), rgb(200, 200, 200), bf
line (21, 519)-(778, 555), rgb(200, 200, 200), b
line (23, 523)-(776, 551), rgb(16, 16, 48), bf
DrawProgressBar 5
' Definição das imagens do boneco
' Parado (depende do último movimento)
Parado(0) = 116
Parado(1) = 119
Parado(2) = 122
Parado(3) = 117
Parado(4) = 117
Parado(5) = 116
' Andando p/ direita
Movendo(0, 0) = 119
Movendo(0, 1) = 118
Movendo(0, 2) = 120
Movendo(0, 3) = 118
' Andando p/ esquerda
Movendo(1, 0) = 122
Movendo(1, 1) = 121
Movendo(1, 2) = 123
Movendo(1, 3) = 121
' Subindo
Movendo(2, 0) = 124
Movendo(2, 1) = 117
Movendo(2, 2) = 125
Movendo(2, 3) = 117
' Descendo
Movendo(3, 0) = 124
Movendo(3, 1) = 117
Movendo(3, 2) = 125
Movendo(3, 3) = 117
' Caindo
Movendo(4, 0) = 126
Movendo(4, 1) = 126
Movendo(4, 2) = 126
Movendo(4, 3) = 126
' Empurrando p/ direita
Movendo(5, 0) = 128
Movendo(5, 1) = 127
Movendo(5, 2) = 129
Movendo(5, 3) = 127
' Empurrando para esquerda
Movendo(6, 0) = 131
Movendo(6, 1) = 130
Movendo(6, 2) = 132
Movendo(6, 3) = 130
' Morrendo
Movendo(7, 0) = 116
Movendo(7, 1) = 119
Movendo(7, 2) = 117
Movendo(7, 3) = 122
' Usando a picareta
Usando(0, 0) = 133
Usando(0, 1) = 134
' Usando a furadeira p/ direita
Usando(1, 0) = 135
Usando(1, 1) = 136
' Usando a furadeira p/ esquerda
Usando(2, 0) = 137
Usando(2, 1) = 138
DrawProgressBar 10
' Definição dos comportamentos
' Vazio (inclui água)
with Comport(0)
  .Vazio = 1
  .Sobe = 0
  .Apoia = 0
  .Anda = 2
  .Mata = 0
  .PEmpurra = 3 ' Não pode ser empurrado
  .Cai = 0
  .Destroi = 0
  .Som = 1
end with
' Terra (pode ser eliminada)
with Comport(1)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 1
  .Mata = 0
  .PEmpurra = 3
  .Cai = 0
  .Destroi = 1
  .Som = 1
end with
' Parede destrutível
with Comport(2)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 0
  .Mata = 0
  .PEmpurra = 3
  .Cai = 0
  .Destroi = 2
  .Som = 1
end with
' Parede indestrutível
with Comport(3)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 0
  .Mata = 0
  .PEmpurra = 3
  .Cai = 0
  .Destroi = 0
  .Som = 2
end with
' Escada
with Comport(4)
  .Vazio = 0
  .Sobe = 1
  .Apoia = 1
  .Anda = 2
  .Mata = 0
  .PEmpurra = 3
  .Cai = 0
  .Destroi = 1
  .Som = 1
end with
' Diamante
with Comport(5)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 1
  .Mata = 0
  .PEmpurra = 3
  .Cai = 1
  .Destroi = 1
  .Som = 2
end with
' Pedra
with Comport(6)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 0
  .Mata = 0
  .PEmpurra = 3
  .Cai = 1
  .Destroi = 2
  .Som = 2
end with
' Carrinho
with Comport(7)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 0
  .Mata = 0
  .PEmpurra = 0
  .Cai = 1
  .Destroi = 1
  .Som = 3
end with
' Caixa
with Comport(8)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 0
  .Mata = 0
  .PEmpurra = 2
  .Cai = 1
  .Destroi = 2
  .Som = 4
end with
' Feno
with Comport(9)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 0
  .Mata = 0
  .PEmpurra = 1
  .Cai = 1
  .Destroi = 2
  .Som = 1
end with
' Item
with Comport(10)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 1
  .Mata = 0
  .PEmpurra = 3
  .Cai = 1
  .Destroi = 1
  .Som = 3
end with
' Bomba acionada
with Comport(11)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 2
  .Mata = 0
  .PEmpurra = 3
  .Cai = 1
  .Destroi = 0
  .Som = 3
end with
' Suporte em uso
with Comport(12)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 2
  .Mata = 0
  .PEmpurra = 3
  .Cai = 1
  .Destroi = 1
  .Som = 2
end with
' Espetos
with Comport(13)
  .Vazio = 0
  .Sobe = 0
  .Apoia = 1
  .Anda = 2
  .Mata = 1
  .PEmpurra = 3
  .Cai = 0
  .Destroi = 1
  .Som = 2
end with
DrawProgressBar 15
' Definição dos tipos de objetos
dim as integer f, g, h, i
' Vazio (0)
with GObjectData(0)
  .Tipo = 0
  .Img  = 0
  .Item = 0
end with
' Terras (1-14)
for f = 0 to 13
  with GObjectData(f + 1)
    .Tipo = 1
    .Img  = f + 36
    .Item = 0
  end with
next
' Paredes destrutíveis (15-25)
for f = 0 to 10
  with GObjectData(f + 15)
    .Tipo = 2
    .Img  = f + 50
    .Item = 0
  end with
next
' Paredes indestrutíveis (26-37)
for f = 0 to 11
  with GObjectData(f + 26)
    .Tipo = 3
    .Img  = f + 61
    .Item = 0
  end with
next
' Escadas (38-39)
for f = 0 to 1
  with GObjectData(f + 38)
    .Tipo = 4
    .Img  = f + 73
    .Item = 0
  end with
next
' Diamantes (40-55)
for f = 0 to 15
  with GObjectData(f + 40)
    .Tipo = 5
    .Img  = f + 75
    .Item = f + 7
  end with
next
' Pedras (56-63)
for f = 0 to 7
  with GObjectData(f + 56)
    .Tipo = 6
    .Img  = f + 91
    .Item = 0
  end with
next
' Carrinhos (64-66)
for f = 0 to 2
  with GObjectData(f + 64)
    .Tipo = 7
    .Img  = f + 99
    .Item = 0
  end with
next
' Caixas (67-68)
for f = 0 to 1
  with GObjectData(f + 67)
    .Tipo = 8
    .Img  = f + 102
    .Item = 0
  end with
next
' Feno (69-70)
for f = 0 to 1
  with GObjectData(f + 69)
    .Tipo = 9
    .Img  = f + 104
    .Item = 0
  end with
next
' Itens para pegar (71-76)
for f = 0 to 5
  with GObjectData(f + 71)
    .Tipo = 10
    .Img  = f + 106
    .Item = f + 1
    end with
next
' Bombas em Uso (77-78: Pequena; 79-80: Grande)
for f = 0 to 3
  with GObjectData(f + 77)
    .Tipo = 11
    .Img  = f + 112
    .Item = 0
  end with
next
' Suporte em Uso (81)
with GObjectData(81)
  .Tipo = 12
  .Img  = 236
  .Item = 0
end with
' Espetos (82-84)
for f = 0 to 2
  with GObjectData(f + 82)
    .Tipo = 13
    .Img  = 233 + f
    .item = 0
  end with
next
DrawProgressBar 20
' Pontos por tesouro
PontoTesouro(07) = 01
PontoTesouro(08) = 02
PontoTesouro(09) = 03
PontoTesouro(10) = 04
PontoTesouro(11) = 05
PontoTesouro(12) = 06
PontoTesouro(13) = 07
PontoTesouro(14) = 08
PontoTesouro(15) = 09
PontoTesouro(16) = 10
PontoTesouro(17) = 12
PontoTesouro(18) = 15
PontoTesouro(19) = 17
PontoTesouro(20) = 20
PontoTesouro(21) = 25
PontoTesouro(22) = 30
'
if not InitSoundSystem then
  cls
  draw string (10, 20), GText(1)
  draw string (10, 50), GText(50)
  LimpaTeclado
  end 1
end if
DrawProgressBar 25
'
dim LBLoadRes as integer
dim as any ptr LBitmap, LFontBitmap
LBitmap = imagecreate(800, 440, 0, 32)
GBitmap(275) = imagecreate(448, 444, rgba(0, 0, 0, 255), 32)
for f = 0 to 79
  circle GBitmap(275), (222, 222), 144 - f, rgba(0, 0, 0, 255 - f * 3.17),,,, f
next
circle GBitmap(275), (222, 222), 64, rgba(0, 0, 0, 0),,,, f
LBLoadRes = bload("res/Sprites.bmp", LBitmap)
if LBLoadRes <> 0 then DEBUG_LOG("LBLoadRes " & str(LBLoadRes))
' Posições das figuras no arquivo de imagem
' 0-184 = fundos, frentes, objetos, bonecos...
for f = 0 to 184
  GBitmap(f) = imagecreate(32, 32, 0, 32)
  put GBitmap(f), (0, 0), LBitmap, ((f mod 25) * 32, (f \ 25) * 32)-step(31, 31), pset
next
DrawProgressBar 30
' 185-196 = Explosoes
for f = 0 to 11
  GBitmap(185 + f) = imagecreate(32, 32, 0, 32)
  ' Transparência gradativa
  for g = 0 to 31
    for h = 0 to 31
      CorRGB = point(320 + f * 32 + g, 224 + h, LBitmap)
      if CorRGB = Magenta then
        pset GBitmap(185 + f), (g, h), rgba(255, 0, 255, 0)
      else
        pset GBitmap(185 + f), (g, h), rgba(rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 255 - f * 21)
      end if
    next
  next
next
' 197 - 208 = Algarismos (fundo opaco)
for f = 0 to 11
  GBitmap(197 + f) = imagecreate(10, 15, 0, 32)
  put GBitmap(197 + f), (0, 0), LBitmap, (f * 10 + 672, 256)-step(9, 14), pset
next
DrawProgressBar 35
' 209 = Medidor do oxigênio
GBitmap(209) = imagecreate(100, 16, 0, 32)
put GBitmap(209), (0, 0), LBitmap, (672, 272)-(771, 287), pset
' 210 = Barra de informações - (210)
GBitmap(210) = imagecreate(800, 56, 0, 32)
put GBitmap(210), (0, 0), LBitmap, (0, 352)-(799, 407), pset
' 211 = Logo do jogo (211)
GBitmap(211) = imagecreate(220, 96, 0, 32)
put GBitmap(211), (0, 0), LBitmap, (0, 256)-(219, 351), pset
' 212 = Game over (212)
GBitmap(212) = imagecreate(128, 64, 0, 32)
put GBitmap(212), (0, 0), LBitmap, (672, 288)-(799, 351), pset
' 213 - 237 = Agua (213 a 237); espetos (233-235); suporte em uso (236); fundo para água (237)
for f = 0 to 24
  GBitmap(213 + f) = imagecreate(32, 32, 0, 32)
  put GBitmap(213 + f), (0, 0), LBitmap, (f * 32, 408)-step(31, 31), pset
next
' 238 = Setinhas: vermelha, laranja, amarela, verde e azul
GBitmap(238) = imagecreate(58, 15, 0, 32)
put GBitmap(238), (0, 0), LBitmap, (7, 385)-(64, 399), pset
DrawProgressBar 40
' 239 - 246 = Números (esmaecendo)
for f = 0 to 7
  GBitmap(239 + f) = imagecreate(90, 15, 0, 32)
  for h = 0 to 89
    for i = 0 to 14
      CorRGB = (point(288 + h, 320 + i, LBitmap) and 255) * (1 - f * .1)
      pset GBitmap(239 + f), (h, i), rgba(255, 255, 0, CorRGB)
    next
  next
next
DrawProgressBar 45
' 247 = Fonte
LFontBitmap = imagecreate(FontBitmapWidth, 23, 0, 32)
GBitmap(247) = imagecreate(FontBitmapWidth, 22, 0, 32)
LBLoadRes = bload("res/Font.bmp", LFontBitmap)
if LBLoadRes <> 0 then DEBUG_LOG("LBLoadRes " & str(LBLoadRes))
h = 0
PosLetra(0, 0) = 0
for g = 0 to FontBitmapWidth - 1
  for f = 0 to 21
    CorRGB = point(g, f, LFontBitmap) and 255
    pset GBitmap(247), (g, f), rgba(255, 255, 255, CorRGB)
  next
  if (point(g, 22, LFontBitmap) and 1) = 0 then
    PosLetra(h, 1) = g
    h += 1
    if g < FontBitmapWidth - 1 then PosLetra(h, 0) = g + 1
  end if
next
imagedestroy LFontBitmap
DrawProgressBar 50
' 248 - 251 = Quadros para mensagem
for h = 0 to 3
  GBitmap(248 + h) = imagecreate(64, 64, 0, 32)
  for f = 0 to 63
    for g = 0 to 63
      CorRGB = point(288 + h * 64 + f, 256 + g, LBitmap)
      if CorRGB = Magenta then
        pset GBitmap(248 + h), (f, g), rgba(255, 0, 255, 0)
      else
        pset GBitmap(248 + h), (f, g), rgba(rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 192)
      end if
    next
  next
next
DrawProgressBar 55
' 252 = FreeBasic's horse
GBitmap(252) = imagecreate(59, 47, 0, 32)
put GBitmap(252), (0, 0), LBitmap, (225, 256)-(283, 302), pset
' Objetos de frente
for h = 25 to 36
  for g = 0 to 31
    for f = 0 to 31
      CorRGB = point(f, g, GBitmap(h))
      if CorRGB = Magenta then
        pset GBitmap(h), (f, g), rgba(255, 0, 255, 0)
      else
        if h < 32 then
          pset GBitmap(h), (f, g), rgba(rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 191)
        else
          pset GBitmap(h), (f, g), rgba(rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 127)
        end if
      end if
    next
  next
next
DrawProgressBar 60
for h = 0 to 5
  GBitmap(253 + h) = imagecreate(42, 48, 0, 32)
  put GBitmap(253 + h), (0, 0), LBitmap, (544 + (h mod 3) * 42, 256 + (int(h / 3) * 48))-step(41, 47), pset
next
for f= 259 to 273
  GBitmap(f) = imagecreate(32, 32, 0, 32)
next
DrawProgressBar 65
for f = 0 to 4
  put GBitmap(264 + f), (0, 0), LBitmap, (378 + f * 32, 320)-step(31, 31), pset
  for g = 0 to 31
    put GBitmap(269 + f), (g, 0), LBitmap, (409 + f * 32 - g, 320)-step(0, 31), pset
    for h = 0 to 31
      pset GBitmap(259 + f), (31 - h, g), point(378 + f * 32 + g, 320 + h, LBitmap)
    next
  next
next
DrawProgressBar 70
' Números pequenos para o editor
GBitmap(274) = imagecreate(60, 8, 0, 32)
put GBitmap(274), (0, 0), LBitmap, (288, 335)-(347, 342), pset
imagedestroy LBitmap
' Imagens do Menu
GBitmap(276) = imagecreate(630, 128, 0, 32)
LBitmap = imagecreate(723, 128, 0, 32)
LBLoadRes = bload("res/Menu.bmp", LBitmap)
if LBLoadRes <> 0 then  DEBUG_LOG("LBLoadRes " & str(LBLoadRes))
put GBitmap(276), (0,0), LBitmap, (0, 0)-(629, 127), pset
GBitmap(277) = imagecreate(96, 96, 0, 32)
' Imagens do menu do editor
GBitmap(278) = imagecreate(73, 19, rgba(255, 0, 255, 0), 32)
for f = 0 to 3
  line GBitmap(278), (3 - f, f)-(69 +  f, 18 - f), rgba(0, 0, 0, 255), b
next
DrawProgressBar 75
line GBitmap(278), (4, 4)-(68, 14), rgba(0, 0, 0, 64), Bf
GBitmap(279) = imagecreate(611, 21, rgba(255, 0, 255, 0), 32)
line GBitmap(279), (0,0)-(22, 20), rgb(128, 128, 128), b
line GBitmap(279), (23,0)-(45, 20), rgb(128, 128, 128), b
line GBitmap(279), (46,0)-(564, 20), rgb(128, 128, 128), b
line GBitmap(279), (565,0)-(587, 20), rgb(128, 128, 128), b
line GBitmap(279), (588,0)-(610, 20), rgb(128, 128, 128), b
put GBitmap(279), (3, 2), LBitmap, (688, 66)-(703, 82), pset
put GBitmap(279), (30, 2), LBitmap, (695, 66)-(703, 82), pset
put GBitmap(279), (572, 2), LBitmap, (677, 66)-(685, 82), pset
put GBitmap(279), (592, 2), LBitmap, (677, 66)-(692, 82), pset
line GBitmap(279), (48, 4)-(562, 17), rgba(255, 255, 255, 255), B
line GBitmap(279), (48, 4)-(561, 16), rgba(128, 128, 128, 255), B
line GBitmap(279), (49, 5)-(52, 16), rgba(255, 255, 0, 255), BF
line GBitmap(279), (53, 5)-(152, 16), rgba(80, 160, 160, 255), BF
line GBitmap(279), (153, 5)-(208, 16), rgba(185, 106, 106, 255), BF
line GBitmap(279), (209, 5)-(561, 16), rgba(100, 180, 100, 255), BF
DrawProgressBar 80
GBitmap(280) = imagecreate (187, 56, rgba(255, 0, 255, 0), 32)
for f = 0 to 1
  for g = 0 to 1
    line GBitmap(280), (g * 27, f * 28)-step(26, 27), rgba(96, 96, 96, 255), B
    put GBitmap(280), (2 + g * 27, 3 + f * 28), LBitmap, (631 + g * 23, f * 23)- step(22, 22), pset
  next
  for g = 0 to 2
    line GBitmap(280), (106 + g * 27, f * 28)-step(26, 27), rgba(96, 96, 96, 255), B
    put GBitmap(280), (108 + g * 27, 3 + f * 28), LBitmap, (631 + f * 23, 46 + g * 23)- step(22, 22), pset
  next
next
line GBitmap(280), (54, 0)-step(51, 55), rgba(0, 0, 0, 255), B
line GBitmap(280), (55, 0)-step(49, 55), rgba(128, 128, 128, 255), B
put GBitmap(280), (57, 3), LBitmap, (677, 0)-(722, 49), pset
GBitmap(281) = imagecreate (46, 16, rgba(192, 192, 192, 255), 32)
put GBitmap(281), (0, 0), LBitmap, (677, 50)-(722, 65), pset
imagedestroy LBitmap
DrawProgressBar 85
'Highlight do menu
for f = 0 to 15
  circle GBitmap(277), (f + 15, f + 15), 15, rgba(64, 255, 64, f * 16),,,, f
  circle GBitmap(277), (f + 15, 80 - f), 15, rgba(64, 255, 64, f * 16),,,, f
  circle GBitmap(277), (80 - f, f + 15), 15, rgba(64, 255, 64, f * 16),,,, f
  circle GBitmap(277), (80 - f, 80 - f), 15, rgba(64, 255, 64, f * 16),,,, f
  line GBitmap(277), (16 + f, f)-(79 - f, 95 - f), rgba(64, 255, 64, f * 16), bf
  line GBitmap(277), (f , 16 + f)-(95 - f, 79 - f), rgba(64, 255, 64, f * 16), bf
next
DrawProgressBar 90
sleep 5, 1
LoadSounds
LoadMine 0, 1
DrawProgressBar 95

GJogo.NumVidas = 2

if fileexists("config.min") then
  open "config.min" for input as #1
  input #1, GJogo.Volume
  input #1, GJogo.MaxAlcancada
  input #1, GCurrLangName
  close #1
else
  GJogo.Volume   = 64
  GJogo.MaxAlcancada = 1
  GCurrLangName = DefaultLanguage
end if
LoadLanguage(GCurrLangName)
DrawProgressBar 100

if GJogo.MaxAlcancada < 1 then GJogo.MaxAlcancada = 1
if GJogo.Volume < 0 or GJogo.Volume > 127 then GJogo. Volume = 64
'midiOutSetVolume(0, (GJogo.Volume Shl 9) or (GJogo.Volume Shl 1))

' FPS / velocidade
GJogo.Passos = 8
GJogo.DelayMSec = 33
GJogo.TamanhoPasso = 4
' Le recordes
LeTopDez
' Inicia parâmetros
IniciaJogo
IniciaVida
LimpaMina
MudaStatus NoMenu
TmpSleep = 25
Quadros = 0
UltQuadros = 0
GTimer1 = Clock
cls
screenset 0, 1
ScrAtiva = 0

Joga

FreeSound
for f = 0 to 277
  imagedestroy GBitmap(f)
next

end

' Desenha o fundo de listras coloridas dos menus, pausa, etc.
sub DrawBackground
  dim LGrad as integer
  GGrad = (GGrad + 2) mod 256
  for f as integer = 0 to 119
    LGrad = (GGrad + f) mod 256
    if LGrad > 127 then LGrad = 255 - LGrad
    line (0, f * 5)-(799, f * 5 + 9), rgb(LGrad * GRed, LGrad * GGreen, LGrad * GBlue), bf
  next
end sub

' Desenha a barra indicando a carga do programa
sub DrawProgressBar(APercent as integer)
  line (25, 525)-(25 + APercent * 7.51, 549), rgb(127, 127, 255), bf
  sleep 10, 1
end sub

' Desenha a tela
sub Desenha
  ' Declaração de variáveis locais
  dim as integer XR, YR, X1, Y1, X1R, Y1R, BonecoR, Agua0, DF1, DF2, DG1, DG2, FigPt, f, g, h, I
  dim as integer TRX, TRY, TRXa, TRYa, Explodindo
  ' Verifica se há explosão, para tremer a imagem
  for f = 0 to 10
    if explosao(f).Tipo > 0 and explosao(f).tempo < 10 then explodindo = 1
  next
  ' Calcula que parte da tela deve ser mostrada
  if (GJogo.Status = ModoMapa) or (GJogo.status = Top10) or (GJogo.Status = Editor) then
    TRX  = MapX
    TRY  = MapY
    TRXa = 0
    TRYa = 0
  else
    with GBoneco
      ' Calcula o X inicial da tela
      if GMina.Larg < 25 or .X < 12 then
        TRX  = 0
        TRXa = 0
      elseif .X > GMina.Larg - 12 then
        TRX  = GMina.Larg - 24
        TRXa = 0
      elseif .DirAtual = 1 then
        TRX  = .X - 12
        TRXa = -.Passo * GJogo.TamanhoPasso
      elseif .DirAtual = 2 then
        TRX  = .X - 13
        TRXa = (.Passo - GJogo.Passos) * GJogo.TamanhoPasso
      else
        TRX  = .x - 12
        TRXa = 0
      end if
      if .X = 12 and .DirAtual = 2 then
        TRX  = 0
        TRXa = 0
      end if
      if .x = GMina.Larg - 12 and .DirAtual = 1 then TRXa = 0
      ' Calcula o Y inicial da tela
      if GMina.ALT < 17 or .Y < 8 then
        TRY  = 0
        TRYa = 0
      elseif .Y > GMina.ALT - 8 then
        TRY  = GMina.ALT - 16
        TRYa = 0
      elseif .DirAtual > 3 then
        TRY  = .Y - 8
        TRYa = -.Passo * GJogo.TamanhoPasso
      elseif .DirAtual = 3 then
        TRY  = .Y - 9
        TRYa = (.Passo - GJogo.Passos) * GJogo.TamanhoPasso
      else
        TRY  = .Y - 8
        TRYa = 0
      end if
      if .Y = 8 and .DirAtual = 3 then
        TRY  = 0
        TRYa = 0
      end if
      if .Y = GMina.ALT - 8 and .DirAtual > 3 then TRYa = 0
    end with
  end if
  if (GMina.noturno = 0) or (GJogo.Status = Editor) then
    df1 = 0
    df2 = 25
    dg1 = 0
    dg2 = 17
  else
    ' Limpa tela (desnecessário se não for no modo noturno, pois toda a tela é redesenhada)
    cls
    df1 = GBoneco.x - trx - 5
    df2 = GBoneco.x - trx + 5
    dg1 = GBoneco.y - try - 5
    dg2 = GBoneco.y - try + 5
    if df1 < 0  then df1 = 0
    if df2 > 25 then df2 = 25
    if dg1 < 0  then dg1 = 0
    if dg2 > 17 then dg2 = 17
  end if
  ' Grupo de imagens do boneco
  if GBoneco.NoOxigenio = 0 then
    BonecoR = GJogo.Player * 46
  else
    BonecoR = 23
  end if
  if Explodindo > 0 then
    TRXA = trxa + rnd * 11 - 5
    trya = TRYA + rnd * 11 - 5
  elseif GJogo.status = VenceuJogo then
    TRXA = trxa + rnd * 3 - 1
    trya = TRYA + rnd * 3 - 1
  end if
  ' Inicia o desenho
  ' Desenha imagens do fundo (layer 0, pset)
  for f = df1 to df2
    for g = dg1 to dg2
      if fundo (TRX + f, TRY + g) > 0 then
        put (TRXa + f * 32, TRYa + g * 32), GBitmap(fundo (TRX + f, TRY + g)),pset
      else
        put (TRXa + f * 32, TRYa + g * 32), GBitmap(237), pset
      end if
    next
  next
  ' Desenha os Objetos sobre o fundo (layer 1, trans)
  if (GJogo.Status <> Editor) or (EdShow =1 or EdShow = 2) then
    for f = df1 to df2
      for g = dg1 to dg2
        XR = 0
        YR = 0
        ' Calcula posição de objeto caindo
        if GObject(TRX + f,TRY + g).caindo = 1 then
          YR = GObject(TRX + f,TRY + g).Passo * GJogo.TamanhoPasso
        else
          ' Calcula posição de objeto empurrado
          select case GObject(TRX + f,TRY + g).Empurrando
          case 1
            XR = GObject(TRX + f,TRY + g).Passo * GJogo.TamanhoPasso
          case 2
            XR = -GObject(TRX + f,TRY + g).Passo * GJogo.TamanhoPasso
          end select
        end if
        ' Desenha o objeto na sua posição
        put (TRXa + f * 32 + XR, TRYa + g * 32 + YR), GBitmap(GObjectData(GObject(TRX + f,TRY + g).Typ).Img), trans
      next
    next
  end if
  ' Desenha o boneco (layer 1, trans)
  if GJogo.Status <> VenceuJogo and GJogo.Status <> Top10 and GJogo.STATUS <> GameOver and GBoneco.MORREU = 0 then
    ' Calcula Posição
    with GBoneco
      ' Escolhe imagem
      ' Picareta
      if GJogo.Status = Editor then
        .Img = Parado (0)
        .ImgX = .x * 32
        .ImgY = .y * 32
      else
        if .NaPicareta > 0 then
          .Img = Usando(0, .NaPicareta mod 2) + BonecoR
          put (TRXa + .ImgX - (TRX * 32), TRYa + .ImgY - (TRY * 32)+ 32), GBitmap(259 + int((.NaPicareta / GJogo.Passos) * 2.35)), trans
        ' Furadeira
        elseif .NaFuradeira>0 then
          .Img = Usando (.DirFuradeira, .NaFuradeira mod 2) + BonecoR
          if .DirFuradeira = 1 then
            put (TRXa + .ImgX - (TRX * 32) + 32, TRYa + .ImgY - (TRY * 32)), GBitmap(264 + int((.NaFuradeira / GJogo.Passos) * 2.35)), trans
          else
            put (TRXa + .ImgX - (TRX * 32) - 32, TRYa + .ImgY - (TRY * 32)), GBitmap(269 + int((.NaFuradeira / GJogo.Passos) * 2.35)), trans
          end if
        ' Parado
        elseif .DirAtual = 0 then
          .Img = Parado (.UltDir) + BonecoR
        ' Movendo-se
        else
          .Img = Movendo (.diratual + (.empurrando * 5) - 1, .passo mod 4) + BonecoR
        end if
        ' Ajusta posição conforme movimento
        select case .DirAtual
        case 1 ' Direita
          .ImgX = .x * 32 + (.Passo * GJogo.TamanhoPasso)
        case 2 ' Esquerda
          .ImgX = .x * 32 - (.Passo * GJogo.TamanhoPasso)
        case 3 ' Subindo
          .imgY = .y * 32 - (.Passo * GJogo.TamanhoPasso)
        case 4, 5 'Descendo / Caindo
          .imgY = .y * 32 + (.Passo * GJogo.TamanhoPasso)
        case else
          .ImgX = .x * 32
          .ImgY = .y * 32
        end select
      end if
      ' Desenha
      put (TRXa + .ImgX - (TRX * 32), TRYa + .ImgY - (TRY * 32)), GBitmap(.Img), trans
    end with
  end if
  ' Desenha objetos da frente (layer 3, trans)
  if (GJogo.status <> Top10) and (GJogo.Status <> Editor or EdShow >=2) then
    for f = df1 to df2
      for g = dg1 to dg2
        if frente (TRX + f,TRY + g) > 0 then
          put (TRXa + f * 32, TRYa + g * 32), GBitmap(frente (TRX + f, TRY + g) + 24), alpha
        end if
      next
    next
  end if
  ' Desenha água (layer 4, Alpha 95)
  Agua0 = (GJogo.SeqCiclo * 13) mod 20
  for f = df1 to df2
    for g = dg1 to dg2
      ' Desenha, se o fundo for água (0)
      if fundo (TRX + f, TRY + g) = 0 then
        put (TRXa + f * 32, TRYa + g * 32), GBitmap(213 + (Agua0 + f + g * 6) mod 20), alpha, 95
      end if
    next
  next
  ' Desenha Lanterna (layer 5, Alpha variável)
  if GJogo.Status <> Editor then
    if GMina.noturno = 1 then
      put (TRXa + GBoneco.ImgX - (TRX * 32) - 208, TRYa + GBoneco.ImgY - (TRY * 32) - 208), GBitmap(275), (0, 0) - (443, 443), alpha
    end if
    ' Desenha explosões (layer 6, trans)
    for f = 0 to 10
      with Explosao(f)
        if .Tipo > 0 then
          for g = (.Tipo = 2) to - (.Tipo = 2)
            for h = -1 to 1
              put(TRXa + (.x - TRX + h) * 32, TRYa + (.y - TRY + g) * 32), GBitmap(185 + int(.tempo / 3)), alpha
            next
          next
        else
          .Tempo = 0
        end if
        ' Incrementa contador
        .tempo += 1
        if .tempo >= 35 then
          .tempo = 0
          .Tipo  = 0
        endif
      end with
    next
    ' Mensagens de pontos na tela
    for I = 0 to 9
      with GMessage (I)
        if .Ciclo > 0 then
          EscrevePT (.Pontos, TRXa + (.X -TRX) * 32 + 16, TRYa + (.Y - TRY) * 32 - 12 + int(.Ciclo/4), int((127 - .Ciclo) / 16))
          .Ciclo -= 1
        end if
      end with
    next
  else
    select case edgrid
    case 6, 7
      for f=0 to 23
        line(f*32+32,0)-(f*32+32,543),rgb(255,0,255)
      next
      for f=0 to 15
        line(0,f*32+32)-(799,f*32+32),rgb(255,0,255)
      next
    case 2, 3
      for f=0 to 23
        line(f*32+32,0)-(f*32+32,543),rgb(255,255,255)
      next
      for f=0 to 15
        line(0,f*32+32)-(799,f*32+32),rgb(255,255,255)
      next
    case 0, 1
      for f=0 to 23
        line(f*32+32,0)-(f*32+32,543),rgb(31,31,31)
      next
      for f=0 to 15
        line(0,f*32+32)-(799,f*32+32),rgb(31,31,31)
      next
    end select
    if edgrid mod 2 = 0 then
      for f=0 to 24
        EscreveNumeroPeq (MapX + f, 11+f*32,0)
      next
      for f=0 to 16
        EscreveNumeroPeq (Mapy + f, 0, 11+f*32)
      next
    end if
  end if
  if GJogo.Status <> Editor then
    ' Desenha a barra inferior
    put (0, 544), GBitmap(210), pset
    with GBoneco
      ' Pontuação
      EscreveNumero .Pontos, 6, 7, 577, 0
      ' Núm. mina
      'If GJogo.Status <> ModoDemo Then
        EscreveNumero .Mina, 3, 96, 577, 0
      'end if
      ' Oxigenio
      put( 151, 576), GBitmap(209), (0, 0)-step(.Oxigenio, 15), pset
      ' Qtde Itens Garrafa de Oxigenio
      EscreveNumero .ItOxigenio, 1, 296, 575, 0
      ' Qtde Itens Suporte Pedra
      EscreveNumero .ItSuporte, 1, 347, 575, 0
      ' Qtde Itens Picareta
      EscreveNumero .ItPicareta, 1, 393, 575, 0
      ' Qtde Itens Furadeira
      EscreveNumero .ItFuradeira, 1, 445, 575, 0
      ' Qtde Itens Bombinha
      EscreveNumero .ItBombinha, 1, 489, 575, 0
      ' Qtde Itens Bombona
      EscreveNumero .ItBombona, 1, 532, 575, 0
      ' Quantidade de pedras a recolher
      EscreveNumero GMina.Tesouros, 2, 550, 575, 0
      ' Vidas
      EscreveNumero .Vidas, 2, 582, 576, 0
    end with
    ' Tempo Maximo
    if GMina.Tempo > 0 then
      EscreveNumero GMina.Tempo \ 60, 2, 655, 556, 1
      EscreveNumero GMina.Tempo mod 60, 2, 683, 556, 1
      if GMina.tempo - GBoneco.tempo >= 20 or GJogo.Status <> Jogando then
        put (642, 578), GBitmap(238), (48, 0)-step(9, 14), trans
      else
        if (GJogo.SeqCiclo mod 2 = 1) or (GJogo.status = VenceuJogo) then put (642, 578), GBitmap(238), (int ((GMina.tempo - GBoneco.tempo) / 5) * 12, 0)-step(9, 14), trans
      end if
    end if
    if GJogo.SeqCiclo mod 2 = 1 and GBoneco.morreu = 0 and iniciado > 0 and GJogo.status <> VenceuJogo then
      line (679, 582) - (680, 590), point (679, 581), bf
    end if
    EscreveNumero GBoneco.Tempo \ 60, 2, 655, 578, 1
    EscreveNumero GBoneco.Tempo mod 60, 2, 683, 578, 1
    if GJogo.Status = ModoDemo then
      DemoCiclo = DemoCiclo + 1
      select case MensDemo
      case 1
        EscreveCentro GText(11), 430, 1, 0
        EscreveCentro GText(12), 460, 1, 0
      case 2
        EscreveCentro GText(13), 445, 1, 0
      case 3
        EscreveCentro GText(14), 430, 1, 0
        EscreveCentro GText(15), 460, 1, 0
      case 4
        EscreveCentro GText(16), 430, 1, 0
        EscreveCentro GText(17), 460, 1, 0
      case 5
        EscreveCentro GText(18), 445, 1, 0
      case 6
        EscreveCentro GText(19), 430, 1, 0
        EscreveCentro GText(20), 460, 1, 0
      case 7
        EscreveCentro GText(21), 430, 1, 0
        EscreveCentro GText(22), 460, 1, 0
      case 8
        EscreveCentro GText(23), 445, 1, 0
      case 9
        EscreveCentro GText(24), 445, 1, 0
      case 10
        EscreveCentro GText(25), 430, 1, 0
        EscreveCentro GText(26), 460, 1, 0
      case 11
        EscreveCentro GText(27), 430, 1, 0
        EscreveCentro GText(28), 460, 1, 0
      case 12
        EscreveCentro GText(29), 430, 1, 0
        EscreveCentro GText(30), 460, 1, 0
      case 13
        EscreveCentro GText(31), 430, 1, 0
        EscreveCentro GText(32), 460, 1, 0
      case 14
        EscreveCentro GText(33), 430, 1, 0
        EscreveCentro GText(34), 460, 1, 0
      case 15
        EscreveCentro GText(35), 430, 1, 0
        EscreveCentro GText(36), 460, 1, 0
      case 16
        EscreveCentro GText(37), 430, 1, 0
        EscreveCentro GText(38), 460, 1, 0
      case 17
        EscreveCentro GText(39), 430, 1, 0
        EscreveCentro GText(40), 460, 1, 0
      case 18
        EscreveCentro GText(41), 445, 1, 0
      case 19
        EscreveCentro GText(42), 430, 1, 0
        EscreveCentro GText(43), 460, 1, 0
      case 20
        EscreveCentro GText(44), 430, 1, 0
        EscreveCentro GText(45), 460, 1, 0
      case 21
        EscreveCentro GText(46), 430, 1, 0
        EscreveCentro GText(47), 460, 1, 0
      case 22
        EscreveCentro GText(48), 430, 1, 0
        EscreveCentro GText(49), 460, 1, 0
        for f = 0 to 4
          line (480 + f, 480)-(533 + f, 533), &HFFA000
          line (515, 529 + f)-(533, 529 + f), &HFFA000
          line (533 + f, 515)-(533 + f, 533), &HFFA000
        next
      end select
    end if
  else
    line (0, 543) - (799, 543), &H000000
    select case GJogo.EdStatus
    case Editando
      line (1, 545) - (609, 563), &HA0A0A0, BF
      line (0, 565) - (610, 599), &H000000, BF
      line (611, 544) - (611, 599), &H606060
      line (612, 544) - (612, 599), &H000000
      line (614, 545) - (798, 598), &HA0A0A0, BF
      line (667, 544) - (667 , 599), &H000000
      line (718, 544) - (718 , 599), &H000000
      select case PosMouse
      case EdForaTela
        ' Nada a fazer
      case EdTela
        Dlinha EDX1 * 32 - 3, EDY1 * 32 - 3, EDX1 * 32 + 34, EDY1 * 32 + 34, 0
      case EdInicio
        line (1, 545) - (21, 563), &HFFFFFF, BF
      case EdEsquerda
        line (24, 545) - (44, 563), &HFFFFFF, BF
      case EdDireita
        line (565, 545) - (585, 563), &HFFFFFF, BF
      case EdFim
        line (588, 545) - (608, 563), &HFFFFFF, BF
      case EdBarra
        line (47, 545) - (563, 563), &HFFFFFF, BF
      case EdItem
        line (int (GMX / 34) * 34 - 1, 565)-step(35, 34), &HFFFFFF, BF
      case EdNovo
        line (614, 545) - (638, 570), &HFFFFFF, BF
      case EdAbre
        line (641, 545) - (665, 570), &HFFFFFF, BF
      case EdMove
        line (614, 573) - (638, 598), &HFFFFFF, BF
      case EdSalva
        line (641, 573) - (665, 598), &HFFFFFF, BF
      case EdVisao
        line (669, 545) - (716, 598), &HFFFFFF, BF
      case EdMudaGrid
        line (720, 545) - (744, 570), &HFFFFFF, BF
      case EdApaga
        line (747, 545) - (771, 570), &HFFFFFF, BF
      case EdTesta
        line (774, 545) - (798, 570), &HFFFFFF, BF
      case EdUndo
        line (720, 573) - (744, 598), &HFFFFFF, BF
      case EdRedo
        line (747, 573) - (771, 598), &HFFFFFF, BF
      case EdExit
        line (774, 573) - (798, 598), &HFFFFFF, BF
      end select
      ' Se mouse estiver sobre qualquer área, fazer um hilight em amarelo ou verde
      put (0, 544), GBitmap(279), trans
      ' Calcula posiçao da barra e mostra
      put (46 + Primeiroitem * 4.48, 545), GBitmap(278), alpha
      put (613, 544), GBitmap(280), trans
      if ItemSel >= PrimeiroItem and ItemSel <= PrimeiroItem + 17 then
        line (int (ItemSel - PrimeiroItem) * 34 - 1, 565)-step(35, 34), &H40ff40, BF
      end if
      for f = 0 to 17
        DesenhaItem f * 34 + 1, 568, PrimeiroItem + f
      next
      if EdShow = 0 or Edshow = 1 then put (670, 547), GBitmap(281), trans
      if EdShow = 0 or Edshow = 3 then put (670, 564), GBitmap(281), trans
    case Selecionando
      DesBox 24, 1, 4, 400, 572
      EscreveCentro GText(109), 562
      Dlinha EDXX1 * 32 - 3, EDYY1 * 32 - 3, EDXX2 * 32 + 34, EDYY2 * 32 + 34, 1
    case EdMovendo
      DesBox 24, 1, 4, 400, 572
      EscreveCentro GText(110), 562
    case Apagando0, Apagando1
      DesBox 24, 1, 4, 400, 572
      EscreveCentro GText(111), 562
      if GJogo.EdStatus = Apagando0 then
        Dlinha EDX1 * 32 - 3, EDY1 * 32 - 3, EDX1 * 32 + 34, EDY1 * 32 + 34, 3
      else
        Dlinha EDXX1 * 32 - 3, EDYY1 * 32 - 3, EDXX2 * 32 + 34, EDYY2 * 32 + 34, 2
      end if
    end select
  end if
end sub

' Escreve a pontuação ganha na tela
sub EscrevePT (Pontos as  integer, X as integer, Y as integer, CJCarac as integer)
  dim as string StrNum, NumTxt
  dim as integer X1, NumVal, f
  ' Passa o número para texto
  StrNum= str(Pontos)
  X1 = X - len(StrNum) * 6
  for f = 1 to len(StrNum)
    NumTxt = mid(StrNum, f, 1)
    NumVal = val (NumTxt)
    put (x1 + f * 12 - 12, Y), GBitmap(239 + CJCarac), (NumVal * 9, 0)-step(8,14), alpha
  next
end sub

' Escreve um número (caracteres especiais)
sub EscreveNumero (byval Numero as long, Comprimento as  integer, X1 as integer, Y1 as integer, Preenche as integer)
  dim as string StrNum, NumTxt
  dim as integer NumVal, f
  if Preenche=0 then
    StrNum= right(space (Comprimento) & str(Numero), Comprimento)
  else
    StrNum= right("0000000000" & str(Numero), Comprimento)
  end if
  if len(StrNum) < len(str(Numero)) then StrNum = string (Comprimento, "+")
  for f= 1 to Comprimento
    NumTxt= mid(StrNum,f,1)
    if NumTxt =" " then
      NumVal=0
    elseif NumTxt ="+" then
      NumVal=11
    else
      NumVal=val(NumTxt)+1
    end if
    put (x1+f*12-12, Y1), GBitmap(197 + NumVal), pset
  next
end sub

' Escreve textos
sub Escreve (byval Texto as string, x1 as integer, y1 as integer, Bold as integer = 0, BoldV as integer = 0)
  dim as integer LF, PosL, LG, LV
  for LF = 1 to len(Texto)
    PosL = instr(Lt_, mid(Texto, LF, 1)) - 1
    if PosL = -1 then
      X1 += 8
    else
      for LV = 0 to BoldV
        for LG = 0 to Bold
          put(X1 + LG, Y1 + LV), GBitmap(247), (PosLetra (PosL, 0), 0) - (PosLetra (PosL, 1), 21), alpha
        next
      next
      x1 += PosLetra (PosL, 1) - PosLetra (PosL, 0) + Bold + 2
    end if
  next
end sub

' Escreve textos centralizados
sub EscreveCentro (byval Texto as string, Y1 as integer, Bold as integer = 0, BoldV as integer = 0)
  Escreve Texto, 399-LargTexto(Texto, Bold)/2, Y1, Bold, BoldV
end sub

' Calcula a largura que um texto ocupa em pixels
function LargTexto (byval Texto as string, Bold as integer = 0) as integer
  dim as integer LF, PosL, LArg
  for LF = 1 to len(Texto)
    PosL = instr(Lt_,mid(Texto,LF,1)) - 1
    if PosL = -1 then
      Larg += 8
    else
      Larg += PosLetra (PosL, 1) - PosLetra (PosL, 0) + Bold + 2
    end if
  next
  Larg = Larg - Bold - 1
  return Larg
end function

' Inicializa dados para nova partida
sub IniciaJogo
  randomize
  ' Inicializa as variáveis principais
  with GJogo
    .UltExplosao=0
    .Encerra=0
    .player=int(rnd * 2)
    .Ciclo=0
  .SeqCiclo=0
  end with
  with GBoneco
    .Mina = 1
    .Vidas = GJogo.NumVidas
    .Pontos = 0
  end with
end sub

' Inicia dados da vida (zera status do boneco)
sub IniciaVida
  dim f as integer
  with GBoneco
    .Morreu=0
    .Empurrando =0
    .Passo =0
    .Img =116
    .ImgX =0
    .ImgY =0
    .UltDir = 0
    .DirAtual = 0
    .Oxigenio =10
    .NoOxigenio=0
    .ItOxigenio =0
    .ItSuporte =0
    .ItPicareta = 0
    .ItFuradeira = 0
    .ItBombinha = 0
    .ItBombona = 0
    .NaPicareta = 0
    .NaFuradeira = 0
    .DirFuradeira = 0
    .VirouFuradeira =0
    .Tempo=0
  end with

  Iniciado=0
  GTimeStart = Clock + 5
  GJogo.UltExplosao=0
  for f = 0 to 10
    Explosao (f).Tipo=0
    Explosao (f).Tempo=0
  next
end sub

' Le arquivo e monta uma mina
sub LoadCustomMine(NMina as integer, Editando as integer)
  dim as string Linha, NArq
  LimpaMina
  ' Zera contador de tesouros para iniciar a contagem
  GMina.Tesouros = 0
  ' Abre arquivo
  if NMina = -1 then
    NArq = "minas/teste.map"
  else
    ClearEditorMine
    NArq = "minas/m" + right("000" & str(NMina), 3) + ".map"
  end if
  ' Verifica se o arquivo existe
  if fileexists (Narq) then
    if NMina > -1 then GMina.numero = NMina
    open Narq for binary as #1
    get #1,, GMina.Larg
    get #1,, GMina.Alt
    get #1,, GMina.Noturno
    get #1,, GMina.Tempo
    LeMinaDet Editando
    close #1
  else ' Arquivo não existe
    Mensagem 4, 8, GText(0), GText(50), ""
    if GKey <> "" and GKey <> GKeyBefore then
      MudaStatus NoMenu
    end if
    MudaStatus NoMenu
    IniciaJogo
    IniciaVida
    LimpaMina
    ClearEditorMine
  end if
end sub

sub Joga
  dim as integer Emp1, Emp2, Emp3, SeqDemo, f, g, h, I
  dim as integer ConfirmDel = 0
  DEBUG_LOG("Enter game procedure")
  ATimer = int(Clock * 1000)
  if GRed + GGreen + GBlue = 0 then GBlue = 1
  TeclasDemo = _ 
  "R01M01R15M22R23M02R24M03L23M04L16M05L12M06L08M07L05M08L04M09D04L00R01W20L00M10R24D06M11L22IC L20ICLL18ICLL16M12IV R18W50L14IV R16W50L12ICLL10" & _
  "IV R12W50L08ICLL06IV R08W50L04ICLL02IV R04W50L01M13L00IX M14D08R04M15IB L02W50R06IB L04W50R08IB L06W50R10IB L08W50R12IB L10W50R14IB L12W50R16IB L14W50" & _
  "R17M16R20IZ R21M17R22M18IB L19W20L01M19D10L00M20R24U09M21###"
  GKey = ""
  while GJogo.Encerra = 0
    GJogo.Status0 = GJogo.Status
    ' Silencia canais que terminaram de reproduzir sons
    Silencia
    if inkey = chr(255) + "k" then
      GJogo.Encerra = 1
      goto TerminaCiclo
    end if
    ' Não há som a reproduzir
    for f =1 to 6
      for g = 1 to 4
        Toca(f, g) = 0
      next
    next
    ' Incrementa Contador de ciclos
    with GJogo
      .Ciclo = (.Ciclo + 1) mod .passos
      if .Ciclo = 0 then
        .SeqCiclo = (.SeqCiclo + 1) mod 1500
        if .SeqCiclo mod 10 = 0 then windowtitle CAppName
      end if
    end with
    GKeyBefore = GKey
    GKey = ""
    ' Controles
    for f = 0 to 127
      if multikey(f) then GKey = "?"
    next
    if multikey(FB.SC_ENTER) then GKey ="["
    if multikey(FB.SC_ESCAPE) then GKey ="ESC"
    if multikey(FB.SC_SPACE) then GKey = "]"
    if multikey(FB.SC_DELETE) then GKey = "<"
    if multikey(FB.SC_P) then GKey ="P"
    if multikey(FB.SC_A) then GKey = "A"
    if multikey(FB.SC_B) then GKey = "B"
    if multikey(FB.SC_C) then GKey = "C"
    if multikey(FB.SC_M) then GKey = "M"
    if multikey(FB.SC_Q) then GKey = "Q"
    if multikey(FB.SC_V) then GKey = "V"
    if multikey(FB.SC_X) then GKey = "X"
    if multikey(FB.SC_Z) then GKey = "Z"
    if multikey(SC_TAB) then GKey = "TAB"
    if multikey(SC_PAGEUP) then GKey = "@"
    if multikey(SC_PAGEDOWN) then GKey = "#"
    ' Movimento
    if multikey(FB.SC_DOWN) then GKey = "D"
    if multikey(FB.SC_LEFT) then GKey = "L"
    if multikey(FB.SC_RIGHT) then GKey = "R"
    if multikey(FB.SC_UP) then GKey = "U"
    GetMouseState
    select case GJogo.Status
    case NoMenu ' Mostra as opções até uma ser escolhida
      DrawBackground
      PutLogo 290, 40
      ' Opções
      MouseSobre = -1
      for f = 0 to 8
        if (GMY > 300) and (GMY < 363) and (GMX > 48 + f * 80) and (GMX < 111 + f * 80) then
          MouseSobre = f
          if (GMMove = 1) and (OpMenu <> f) then
            Sound01(OpMenu, f)
            OpMenu = f
          end if
        end if
        if OpMenu = f then
          put (32 + f * 80, 284), GBitmap(277), (0, 0)-(95, 95), alpha
          put (48 + f * 80, 300), GBitmap(276), (f * 64, 64)-step(63, 63), trans
        else
          put (48 + f * 80, 300), GBitmap(276), (f * 64, 0)-step(63, 63), trans
        end if
      next
      EscreveCentro GText(OpMenu + 2), 380, 1, 1
      if (GKey <> "") or (GMMove = 1) then GDemoTimer = Clock
      if MouseSobre > -1 and GMBDown = 1 then OpMenu = MouseSobre : GKey = "["
      if GKeyBefore <> GKey then
        if GKey = "D" or GKey = "R" then
          Sound01(OpMenu, (Opmenu + 1) mod (Sair + 1))
          OpMenu = (Opmenu + 1) mod (Sair + 1)
        elseif GKey = "U" or GKey = "L" then
          Sound01(OpMenu, (OpMenu + Sair) mod (Sair + 1))
          OpMenu = (OpMenu + Sair) mod (Sair + 1)
        elseif GKey = "ESC" then
          GJogo.encerra = 1
        elseif GKey = "[" or GKey = "]" then
          select case OpMenu  ' Jogar, IrPara, VerTop, Sobre, Volume, EscIdioma, Custom, Editar, Sair
          case Jogar
            Opcao1 = 0
            MudaStatus Jogando
            IniciaJogo
            IniciaVida
            GMina.Tipo = 0
            LoadMine 1
            Iniciado=0
            GTimeStart = Clock + 5
          case IrPara, Volume
            Opcao1 = 0
            MudaStatus Configs
          case VerTop
            MudaStatus Top10
            PosTop10 = 0
          case Sobre
            MudaStatus Instruc
          case EscIdioma
            GJogo.Status = SelIdioma
            LoadLanguageNames
          case CustomMines
            Opcao1 = 0
            GBoneco.Mina = 0
            cls
            TrocaTelas
            cls
            Mensagem 7, 8, GText(92), GText(93), " "
            SearchCustomMines
            TrocaTelas
            cls
            MudaStatus Configs
          case Editar
            Opcao1 = 0
            GBoneco.Mina = 0
            cls
            TrocaTelas
            cls
            Mensagem 7, 8, GText(92), GText(93), " "
            SearchCustomMines
            TrocaTelas
            cls
            MudaStatus Configs
          case Sair
            GJogo.encerra = 1
          end select
        end if
      end if
      if Clock > GDemoTimer + 8 then
        MudaStatus ModoDemo
        GMina.Tipo = 0
        IniciaJogo
        IniciaVida
        LoadMine 0
        Iniciado = 0
        MensDemo = 0
        TempMens = 0
        GKey = ""
        PositDemo = 0
        DemoW1 = 0
        DemoW2 = 0
        DemoCiclo = 0
      end if
    case SelIdioma  'troca o idioma do programa
      DrawBackground
      PutLogo 290, 40
      if GLangCount = 0 then
        Mensagem 5, 8, "Só há o idioma português instalado.", "", ""
        if GKey <> "" and GKeyBefore <> GKey then
          MudaStatus NoMenu
        end if
      else
        DesBox 10, GLangCount + 3, 0, 400, 370
        EscreveCentro GText(7), 374 - (GLangCount + 3) * 16, 1, 1
        MouseSobre = -1
        for f = 0 to GLangCount
          if (GMX > 252) and (GMX < 547) and (abs(GMY - (444 - (GLangCount + 3) * 16 + f * 32)) < 16) then
            MouseSobre = f
            if GMMove = 1 then GCurrLangIndex = f
          end if
          EscreveCentro GLangName (f), 434 - (GLangCount + 3) * 16 + f * 32, 1, 0
        next
        line (250, 426 - (GLangCount + 3) * 16 + GCurrLangIndex * 32)-step(300, 35), rgb(0, 127, 255), b
        line (251, 427 - (GLangCount + 3) * 16 + GCurrLangIndex * 32)-step(298, 33), rgb(0, 127, 255), b
        if MouseSobre > -1 and GMBDown = 1 then GCurrLangIndex = MouseSobre : GKey = "["
        if GKeyBefore <> GKey then
          if (GKey = "U" or GKey ="L") and GCurrLangIndex > 0 then GCurrLangIndex -= 1
          if (GKey = "D" or GKey ="R") and GCurrLangIndex < GLangCount then GCurrLangIndex += 1
          if GKey = "[" or GKey = "]" then
            GCurrLangName = GLangName (GCurrLangIndex)
            LoadLanguage (GCurrLangName)
            RegravaConfig
            MudaStatus NoMenu
          end if
          if GKey = "ESC" then MudaStatus NoMenu
        end if
      end if
    case Configs ' Trata algumas opções do menu
      ' Desenha fundo e LOGO
      DrawBackground
      PutLogo 290, 40
      select case OpMenu
      case IrPara ' Ir para mina...
        if GBoneco.Mina < 1 or GBoneco.Mina > GJogo.NumMinas then GBoneco.Mina = 1
        EscreveCentro GText(51), 140, 1, 0
        EscreveCentro GText(52), 575, 1, 0
        Mina1 = int((GBoneco.mina - 1) / 100) * 100 + 1
        if Mina1 > GJogo.NumMinas - 100 then
          Mina2 = GJogo.NumMinas - Mina1 + 1
        else
          Mina2 = 100
        end if
        MouseSobre = -1
        for f = 0 to Mina2 - 1
          XM = (f mod 10) * 65 + 80
          YM = int (f / 10) * 40 + (370 - int((Mina2 + 9) / 10) * 20)
          if Mina1 + f > GJogo.MaxAlcancada then
            put (XM, YM + 2), GBitmap(276), (576, 33) - (630, 65), trans
          else
            put (XM, YM + 2), GBitmap(276), (576, 0) - (630, 32), trans
          end if
          if (GMX > XM) and (GMX < XM + 54) and (GMY > YM + 2) and (GMY < YM + 35) then
            MouseSobre = Mina1 + f
          end if
          if Mina1 + f > GJogo.MaxAlcancada then
            put (XM, YM + 6), GBitmap(276), (576, 103) - (630, 127), trans
          elseif Mina1 + f < 10 then
            Escreve str(Mina1 + f), XM + 23, YM + 8, 1, 0
          elseif Mina1 + f < 100 then
            Escreve str(Mina1 + f), XM + 17, YM + 8, 1, 0
          else
            Escreve str(Mina1 + f), XM + 11, YM + 8, 1, 0
          end if
        next
        if (GMMove = 1) and (MouseSobre > -1) then GBoneco.Mina = MouseSobre
        if MouseSobre > -1 and GMBDown = 1 then GBoneco.Mina = MouseSobre : GKey = "["
        XM = ((GBoneco.Mina - Mina1) mod 10) * 65 + 80
        YM = int ((GBoneco.Mina - Mina1) / 10) * 40 + (370 - int((Mina2 + 9) / 10) * 20)
        put (XM, YM), GBitmap(276), (576, 66)-(630, 102), trans
        if MouseWDir = -1 then GKey = "#"
        if MouseWDir = 1 then GKey = "@"
        if GKey <>"" and GKey <> GKeyBefore then
          select case GKey
          case "D"
            if GBoneco.Mina <= GJogo.NumMinas - 10 then GBoneco.Mina += 10
          case "L"
            if GBoneco.Mina > 1 then GBoneco.Mina -= 1
          case "U"
            if GBoneco.Mina > 10 then GBoneco.Mina -= 10
          case "R"
            if GBoneco.Mina < GJogo.NumMinas then GBoneco.Mina += 1
          case "@"
            if GBoneco.Mina > 100 then GBoneco.Mina -= 100 else GBoneco. Mina = 1
          case "#"
            if GBoneco.Mina < GJogo.NumMinas - 100 then GBoneco.Mina += 100 else GBoneco.Mina = GJogo.NumMinas
          case "ESC"
            MudaStatus NoMenu
          case "[", "]"
            if GBoneco.Mina <= GJogo.MaxAlcancada then
              XM = GBoneco.Mina
              IniciaJogo
              IniciaVida
              GBoneco.Mina = XM
              GMina.Tipo = 0
              LoadMine XM
              Iniciado = 0
              GTimeStart = Clock + 5
              MudaStatus Jogando
            end if
          end select
        end if
      case Volume ' Ajuste do Volume
        put (364, 250), GBitmap(276), (256,0)-step(63, 63), trans
        MouseSobre = -1
        if (GMY > 330) and (GMY < 400) and (GMX > 270) and (GMX < 530) then
          MouseSobre = (GMX - 275) / 2
          if MouseSobre <0 then MouseSobre = 0
          if MouseSobre > 127 then MouseSobre = 127
        end if
        if GMBDown = 1 then
          if MouseSobre > -1 then
            GJogo.Volume = mousesobre
          else
            GKey = "["
          endif
        endif
        'Barras
        if MouseSobre = - 1 then
          CorRGB = &H60ff00
          CorRGB2 = &H205000
        else
          CorRGB = &H60ff90
          CorRGB2 = &H205030
          line (270, 405) - (530, 325), &H909090, b
          line (269, 406) - (531, 324), &H909090, b
        end if
        for f = 0 to 15
          if GJogo.Volume >= f * 8 then
            line (275 + f * 16, 400)-step(10, -10 - f * 4), CorRGB, BF
          else
            line (275 + f * 16, 400)-step(10, -10 - f * 4), CorRGB2, BF
          end if
        next
        if GJogo.Volume = 0  then line (275,400)-step(10, -10 ), rgba(180, 0, 0, 0), BF
        if GJogo.Volume = 127  then line (515,400)-step(10, -70 ), rgba(200, 200, 0, 0), BF
        EscreveCentro GText(53), 440, 1, 0
        EscreveCentro GText(54), 500, 1, 0
        if GKey = "D" or GKey = "L" then
          if GJogo.Volume > 0 then GJogo.Volume -= 1
        elseif GKey = "U" or GKey = "R" then
          if GJogo.Volume < 127 then GJogo.Volume += 1
        elseif (GKey = "[" or GKey = "]" or GKey = "ESC") and GKeyBefore <> GKey then
          RegravaConfig
          MudaStatus NoMenu
        elseif MouseWDir = -1 then
          if GJogo.Volume > 8 then
            GJogo.Volume -= 8
          else
            GJogo.Volume = 0
          end if
        elseif MouseWDir = 1 then
          GJogo.Volume += 8
          if GJogo.Volume > 127 then GJogo.Volume = 127
        end if
        'midiOutSetVolume(0, (GJogo.Volume shl 9) Or (GJogo.Volume shl 1))
      case CustomMines, Editar
        MouseSobre = -1
        if (QuantPers = 0) then
          if OpMenu = Editar then
            LimpaMina
            ClearEditorMine
            MudaStatus Editor
            GJogo.EdStatus = Editando
          else
            Mensagem 7, 8, GText(55), GText(56), ""
            if (GKey <> "" and GKey <> GKeyBefore) or (GMBDown = 1) then
              MudaStatus NoMenu
            end if
          end if
        else
          if GBoneco.Mina < 0 or GBoneco.Mina > QuantPers -1 then GBoneco.Mina = 0
          EscreveCentro GText(51), 140, 1, 0
          if OpMenu = Editar then
            EscreveCentro GText(97), 575, 1, 0
          else
            EscreveCentro GText(52), 575, 1, 0
          end if
          Mina1 = int((GBoneco.mina) / 100) * 100
          if Mina1 > QuantPers - 100 then
            Mina2 = QuantPers - Mina1
          else
            Mina2 = 100
          end if
          for f = 0 to Mina2 - 1
            XM = (f mod 10) * 65 + 80
            YM = int (f / 10) * 40 + (370 - int((Mina2 + 9)/10) * 20)
            put (XM, YM+2), GBitmap(276), (576, 0)-(630, 32), trans
            if (GMX > XM) and (GMX < XM + 54) and (GMY > YM + 2) and (GMY < YM + 35) then
              MouseSobre = Mina1 + f
            end if
            PersTemp = MinaPers (Mina1 + f)
            if PersTemp < 10 then
              Escreve str(PersTemp), XM + 23, YM + 8, 1, 0
            elseif PersTemp < 100 then
              Escreve str(PersTemp), XM + 17, YM + 8, 1, 0
            else
              Escreve str(PersTemp), XM + 11, YM + 8, 1, 0
            end if
          next
          if (GMMove = 1) and (MouseSobre > -1) then GBoneco.Mina = MouseSobre
          if MouseSobre > -1 and GMBDown = 1 then GBoneco.Mina = MouseSobre : GKey = "["
          XM = ((GBoneco.Mina - Mina1) mod 10) * 65 + 80
          YM = int ((GBoneco.Mina - Mina1) / 10) * 40 + (370 - int((Mina2 + 9)/10) * 20)
          put (XM, YM), GBitmap(276), (576,66)-(630, 102), trans
          if MouseWDir = -1 then GKey = "#"
          if MouseWDir = 1 then GKey = "@"
          if GKey <>"" and GKey <> GKeyBefore then
            select case GKey
            case "D"
              GBoneco.Mina += 10
              if GBoneco.Mina >= QuantPers then GBoneco.Mina -= 10
            case "L"
              GBoneco.Mina -= 1
              if GBoneco.Mina < 0 then GBoneco.Mina = 0
            case "U"
              GBoneco.Mina -= 10
              if GBoneco.Mina < 0 then GBoneco.Mina += 10
            case "R"
              GBoneco.Mina += 1
              if GBoneco.Mina >= QuantPers then GBoneco.Mina = QuantPers - 1
            case "@"
              GBoneco.Mina -= 100
              if GBoneco.Mina < 0 then GBoneco.Mina = 0
            case "#"
              GBoneco.Mina += 100
              if GBoneco.Mina >= QuantPers then GBoneco.Mina = QuantPers - 1
            case "TAB"
              if OpMenu = Editar then
                LimpaMina
                ClearEditorMine
                MudaStatus Editor
              end if
            case "ESC"
              GBoneco.Mina = 1
              MudaStatus NoMenu
            case "[", "]"
              XM = MinaPers(GBoneco.Mina)
              IniciaJogo
              IniciaVida
              GBoneco.Mina = XM
              GMina.Tipo = 1
              Iniciado = 0
              GTimeStart = Clock + 5
              if OpMenu = Editar then
                LoadCustomMine XM, 1
                MudaStatus Editor
                while GMB = 1 and GMX <> -1
                  sleep 1, 1
                  GetMouseState
                wend
              else
                LoadCustomMine XM, 0
                MudaStatus Jogando
              end if
            end select
          end if
        end if
      end select
    case Jogando, ModoDemo, Testando
      if GJogo.Status = ModoDemo then
        ' No modo demo, qualquer tecla faz voltar pro menu
        for f= 1 to 127
          if (multikey(f)) then MudaStatus NoMenu
        next
        ' Busca comandos ou direções para modo demo
        if GBoneco.NaFuradeira = 0 and GBoneco.NaPicareta = 0 then
          GKey = ProximaTeclaDemo ()
          if GKey = "ESC" then
            MudaStatus NoMenu
          end if
        end if
      end if
      ' Verifica se acabou o tempo
      if (GJogo.SeqCiclo mod 8 = 0) and (GJogo.Ciclo = 0) and (iniciado > 0) and (GBoneco.morreu = 0) then
        GBoneco.Tempo += 1
        if (GBoneco.tempo >= GMina.tempo) and (GMina.tempo > 0) and (GJogo.Status = Jogando) then
          GBoneco.morreu = 1
        end if
      end if
      ' Verifica Comandos: PAUSAR, MAPA, QUIT e ESC
      if GBoneco.morreu = 0 and iniciado = 1 and (GJogo.Status = Jogando or GJogo.Status = Testando) and GKeyBefore <> GKey then
        select case GKey
        case "M"  'Mapa
          with GBoneco
            if (GMina.Larg > 24 or GMina.Alt > 16) then
              ' Calcula o X inicial da tela
              if (GMina.Larg < 25) or (.X <= 12) then
                MapX=0
              elseif .X >= GMina.Larg - 12 then
                MapX = GMina.Larg - 24
              else
                MapX = .X - 12
              end if 
              ' Calcula o Y inicial da tela
              if (GMina.Alt < 17) or (.Y <= 8) then
                MapY = 0
              elseif .Y> GMina.Alt-8 then
                MapY = GMina.Alt-16
              else
                MapY = .Y-8
              end if
              MudaStatus ModoMapa
            else
              ' Som DAME
              Sound02
              SomEx(6).Tempo = 4
            end if
          end with
        case "P" ' Pausa
          MudaStatus Pausado
        case "ESC"
          if GJogo.Status = Testando then
            GLMKey = ""
            LimpaTeclado
            opcao1 = 0
            TurnOffSounds
            while (GLMKey <> " ") and (GLMKey <> chr(13)) and (GLMKey <> chr(27))
              cls
              Mensagem 4, 5, GText(95), "", "", 400, 300, Opcao1
              GLMKey = inkey
              GetMouseState
              if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
              if (GMBDown = 1) and (MouseSimNao > 0) then GLMKey = " "
              if (GLMKey = c255 + "H") or (GLMKey = c255 + "K") or (GLMKey = c255 + "M") or (GLMKey = c255 + "P") then Opcao1 = 1 - Opcao1
              TrocaTelas
            wend
            cls
            if (GLMKey <> chr(27)) and (Opcao1 = 0) then EncerraTeste
            LimpaTeclado 1
          else
            GBoneco.Morreu = 1
          end if
        case "Q" ' Quit
          GLMKey = ""
          LimpaTeclado
          opcao1 = 0
          while (GLMKey <> " ") and (GLMKey <> chr(13)) and (GLMKey <> chr(27))
            cls
            Mensagem 4, 5, GText(57), "", "", 400, 300, Opcao1
            GLMKey = inkey
            GetMouseState
            if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
            if (GMBDown = 1) and (MouseSimNao > 0) then GLMKey = " "
            if (GLMKey = c255 + "H") or (GLMKey = c255 + "K") or (GLMKey = c255 + "M") or (GLMKey = c255 + "P") then Opcao1 = 1 - Opcao1
            TrocaTelas
            GJogo.SeqCiclo = (GJogo.SeqCiclo + 1) mod 360
          wend
          cls
          if (GLMKey <> chr(27)) and (Opcao1 = 0) then
            GJogo.encerra = 1
          end if
          LimpaTeclado 1
        end select
      end if
      if (GJogo.Status0 = GJogo.Status) and (GJogo.Encerra <> 1) then
        ' Conclui movimentação de objetos empurrados
        if GBoneco.Empurrando = 1 then
          if GBoneco.DirAtual = 1 then
            Emp1 = GMina.Larg
            Emp2 = 0
            Emp3 = -1
          else
            Emp1 = 0
            Emp2 = GMina.Larg
            Emp3 = 1
          end if
          for f = Emp1 to Emp2 step Emp3
            with GObject(f, GBoneco.Y)
              if .Empurrando > 0 and .Passo >= GJogo.Passos -1 then
                GObject(f + 3 - .Empurrando * 2, GBoneco.y).Typ = .Typ
                GObject(f + 3 - .Empurrando * 2, GBoneco.y).Passo = 0
                GObject(f + 3 - .Empurrando * 2, GBoneco.y).Empurrando = 0
                GObject(f + 3 - .Empurrando * 2, GBoneco.y).Caindo = 0
                GObject(f + 3 - .Empurrando * 2, GBoneco.y).AntCaindo = 0
                .Passo = 0
                .Empurrando = 0
                .Caindo = 0
                .AntCaindo=0
                .Typ = 0
              end if
            end with
          next
        else
          Sound03
        end if
        'Verifica e conclui movimentação e outros comportamentos do boneco
        with GBoneco
          'Se concluiu movimento nesta passagem, zera movimento
          if .DirAtual > 0 and .Passo = GJogo.Passos then
            'Pega ultimo movimento que estava fazendo
            .UltDir= .DirAtual
            'Reposiciona boneco, conforme movimento concluido
            select case .DirAtual
            'Direita
            case 1
              .x += 1
            'Esquerda
            case 2
              .x -= 1
            'Subindo
            case 3
              .y -= 1
            'Caindo / Descendo
            case 4,5
              .y += 1
            end select
            'Não está mais andando, nem empurrando
            .DirAtual = 0
            .Empurrando = 0
            .Passo = 0
          end if
          if Iniciado = 0 then
            if ((GKey <> "") and (GKey <> GKeyBefore)) or ((Clock >= GTimeStart) and (GJogo.Status <> Testando)) then
              Iniciado = 1
            end if
          elseif .Morreu = 1 then
            Explode (.x, .y, 2)
            .Morreu = 2
            if GJogo.Status = ModoDemo then
              .Morreu = 0
              MudaStatus NoMenu
            end if
          elseif .Morreu > 1 then
            .Morreu = (.Morreu + 1) mod 100
            if .Morreu < 2 then .Morreu = 2
            'Verifica se terminou movimento
            if GKey <> "" and GKey <> GKeyBefore then
              'Zera contadores de ciclos
              GJogo.Ciclo = 0
              GJogo.SeqCiclo = 0
              if GJogo.Status = Testando then
                LoadCustomMine -1, 0
                Iniciado = 0
                IniciaVida
              elseif GBoneco.Vidas < 1 then
                MudaStatus GameOver
              else
                GBoneco.Vidas -= 1
                if GMina.Tipo = 0 then
                  LoadMine GBoneco.Mina
                else
                  LoadCustomMine GBoneco.Mina, 0
                end if
                Iniciado = 0
                IniciaVida
              end if
            end if
          'Se não pressionou ESC nem estava morto, verifica se está parado em posição de cair
              '(1-parado; 2-não está na escada; 3-não está sobre objeto que o apoie, ou o objeto de baixo está caindo, ou o objeto de baixo mata)
          elseif Iniciado = 1 and .DirAtual = 0 and .y < GMina.Alt and comport(GObjectData(GObject(.x, .y).Typ).Tipo).sobe = 0 and _
            (comport(GObjectData (GObject(.x, .y + 1).Typ).Tipo).apoia = 0 or GObject(.x, .y + 1).caindo = 1 or comport(GObjectData(GObject(.x, .y + 1).Typ).Tipo).mata = 1) then

            'Informa queda, eliminando outros movimentos ou ações (ficam perdidas)
            .DirAtual   = 5
            .UltDir     = 5
            .NaFuradeira  = 0
            .NaPicareta   = 0
            .Passo      = 1
            if comport(GObjectData(GObject(.x, .y + 1).Typ).Tipo).mata = 1 then .morreu = 1

          'Se não está morto, nem pediu pra morrer, nem vai cair, verifica se está usando a picareta
          elseif .NaPicareta > 0 then
            if .NaPicareta mod 3 =1 then
              Sound04
            end if

            .NaPicareta += 1
            if .Napicareta >= GJogo.Passos * 2 then
              .NaPicareta = 0
              GObject(.x, .y + 1).Typ = 0
            end if

          'Se não morreu nem pediu, não vai cair nem está usando a picareta, verifica se está usando a furadeira
          elseif .NaFuradeira > 0 then
            .NaFuradeira += 1
            if (.DirFuradeira = 1 and GObject(.x + 1, .y).caindo = 1)  or (.DirFuradeira = 2 and GObject(.x - 1, .y).caindo = 1) then
              .Nafuradeira = 0
            end if
            if .NaFuradeira >= GJogo.Passos * 2 then
              if .dirfuradeira = 1 then
                GObject(.x + 1, .y).Typ = 0
              else
                GObject(.x - 1, .y).Typ = 0
              end if
              .NaFuradeira = 0
              .VirouFuradeira = 0
            elseif .VirouFuradeira = 0 and .Nafuradeira <= GJogo.Passos then
              if .DirFuradeira = 1 and GKey = "L" and comport(GObjectData(GObject(.x - 1, .y).Typ).Tipo).destroi = 2 and GObject(.x - 1, .y).caindo = 0 then
                .VirouFuradeira = 1
                .DirFuradeira = 2
              elseif .dirfuradeira = 2 and GKey = "R" and comport(GObjectData(GObject(.x + 1, .y).Typ).Tipo).destroi = 2 and GObject(.x + 1, .y).caindo = 0 then
                .viroufuradeira = 1
                .dirfuradeira = 1
              end if
            end if
          'Se não está morto, não pediu, não vai cair, não está usando a picareta nem a furadeira, verifica se está no meio de um movimento e dá sequencia ao mesmo
          elseif Iniciado = 1 and .DirAtual > 0 then
            .Passo += 1
          elseif Iniciado = 1 then
            'Se não morreu nem pediu, não vai cair nem está usando nada, nem está no meio de nenhum movimento, verifica se foi solicitado novo movimento, e se ele é possível
            select case GKey
            'Tecla para cima
            case "U"
              'Se não está no topo e está em uma escada
              .UltDir = 3
              if .y > 0 and Comport(GObjectData(GObject(.x, .y).Typ).Tipo).sobe = 1 then
                if comport(GObjectData(GObject(.x, .y - 1).Typ).Tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto de cima está livre
                  if Comport(GObjectData(GObject(.x, .y - 1).Typ).Tipo).anda > 0 then
                    'Atualiza direção e inicia movimento
                    .DirAtual = 3
                    .Passo    = 1
                    'Pega e limpa objeto do destino, se for o caso
                    PegaObj .x, .y - 1
                    'Atenção: se 2 posições acima for pedra, vai cair na cabeça!
                  end if
                end if
              end if
            'Tecla para baixo
            case "D"
              'Se não está no fundo
              .UltDir = 5
              if .y < GMina.Alt then
                  if comport(GObjectData(GObject(.x, .y + 1).Typ).Tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto de baixo for uma escada, então desce
                  if Comport(GObjectData(GObject(.x,.y + 1).Typ).Tipo).sobe = 1 then
                    'Atualiza direção e inicia movimento
                    .DirAtual = 4
                    .UltDir   = 4
                    .Passo    = 1
                  'Se abaixo não for escada, verifica se permite andar
                  elseif comport(GObjectData(GObject(.x, .y + 1).Typ).Tipo).anda > 0 then
                    'Atualiza direção e inicia movimento (queda)
                    .DirAtual = 5
                    .UltDir   = 5
                    .Passo    = 1
                    'Pega e limpa objeto do destino, conforme o caso
                    PegaObj .x, .y + 1
                  end if
                end if
              end if
            'Tecla para esquerda
            case "L"
              .UltDir = 2
              .DirFuradeira = 2
              'Se não está no extremo esquerdo
              if .X > 0 then
                'Verifica se foi na direção de objeto que mata
                if comport(GObjectData(GObject(.x - 1, .y).Typ).Tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto da esquerda permite andar e objeto da esquerda acima não está caindo
                  if comport(GObjectData(GObject(.x - 1, .y).Typ).Tipo).anda > 0 and GObject(.x - 1, .y - 1).caindo = 0 then
                    'Atualiza direção e inicia movimento (queda)
                    .DirAtual = 2
                    .Passo    = 1
                    'Pega e limpa objeto do destino, conforme o caso
                    PegaObj .x - 1, .y
                  'Se objeto da esquerda não permite andar, testa se tem condições de ser empurrado
                  elseif EmpurraObj (.x - 1, .y, 2, 0, 1) < 3 then
                    .Empurrando = 1
                    .DirAtual = 2
                    .Passo    = 1
                    Sound05
                  end if
                end if
              end if
            'Tecla para Direita
            case "R"
              .UltDir = 1
              .DirFuradeira = 1
              'Se não está no extremo direito
              if .x < GMina.Larg then
                if comport(GObjectData(GObject(.x + 1, .y).Typ).Tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto da direita permite andar e objeto da direita acima não está caindo
                  if comport(GObjectData(GObject(.x + 1, .y).Typ).Tipo).anda > 0 and GObject(.x + 1, .y - 1).caindo = 0 then
                    .DirAtual = 1
                    .Passo    = 1
                    'Pega e limpa objeto do destino, conforme o caso
                    PegaObj .x + 1, .y
                  'Se objeto da direita não permite andar, testa se tem condições de ser empurrado
                  elseif EmpurraObj (.x + 1, .y, 1, 0, 1) < 3 then
                    .Empurrando = 1
                    .DirAtual = 1
                    .UltDir   = 1
                    .Passo    = 1
                    Sound05
                  end if
                end if
              end if
            'Usar Suporte
            case "Z"
            if GKeyBefore <> "Z" then
              if Comport(GObjectData(GObject(.x, .y).Typ).Tipo).apoia = 0 and .ItSuporte > 0 then
                GObject(.x, .y).Typ = 81
                .ItSuporte -= 1
              else
                PlaySoundImpossibleAction
              end if
            end if
            'Usar Picareta
            case "X"
              if GKeyBefore <> "X" then
                if Comport(GObjectData(GObject(.x, .y + 1).Typ).Tipo).Destroi = 2 and .ItPicareta > 0 then
                  .ItPicareta -= 1
                  .NaPicareta  = 1
                else
                  PlaySoundImpossibleAction
                end if
              end if
            'Usar Furadeira
            case "C"
              if GKeyBefore <> "C" then
                if .ItFuradeira > 0 and ((Comport(GObjectData(GObject(.x - 1, .y).Typ).Tipo).Destroi = 2 and GObject(.x - 1, .y).caindo=0) or (Comport(GObjectData(GObject(.x + 1, .y).Typ).Tipo).Destroi = 2) and GObject(.x + 1, .y).caindo = 0) then
                  if .DirFuradeira = 1 and Comport(GObjectData(GObject(.x + 1, .y).Typ).Tipo).Destroi = 2 and GObject(.x + 1, .y).caindo = 0 then
                    .DirFuradeira  = 1
                    .ItFuradeira  -= 1
                    .NaFuradeira   = 1
                    .VirouFuradeira  = 0
                    Sound07(comport(GObjectData(GObject(.x + 1, .y).Typ).Tipo).som)
                  elseif Comport(GObjectData(GObject(.x - 1, .y).Typ).Tipo).Destroi = 2 and GObject(.x - 1,.y).caindo = 0 then
                    .DirFuradeira  = 2
                    .ItFuradeira  -= 1
                    .NaFuradeira   = 1
                    .VirouFuradeira  = 0
                    Sound07(comport(GObjectData(GObject(.x - 1, .y).Typ).Tipo).som)
                  end if
                else
                  PlaySoundImpossibleAction
                end if
              end if
            'Aciona bomba pequena
            case "V"
              if GKeyBefore <> "V" then
                if .Itbombinha > 0 and Comport(GObjectData(GObject(.x, .y).Typ).Tipo).vazio = 1 then
                  .ItBombinha       -= 1
                  GObject(.x, .y).Typ    = 77
                  GObject(.x, .y).Passo   = 1
                else
                  PlaySoundImpossibleAction
                end if
              end if
            'Aciona bomba grande
            case "B"
              if GKeyBefore <> "B" then
                if .Itbombona > 0 and Comport(GObjectData(GObject(.x, .y).Typ).Tipo).vazio = 1 then
                  .ItBombona      -= 1
                  GObject(.x,.y).Typ   = 79
                  GObject(.x,.y).Passo  = 1
                else
                  PlaySoundImpossibleAction
                end if
              end if
            ' Pula a mina
            case "TAB"
              /'
              if GKeyBefore <> "TAB" and GJogo.Status = Jogando then
                GJogo.SeqCiclo = 0
                MudaStatus VenceuMina
                CalculaBonusTempo
              end if
              '/
            end select
          end if
          ' Atualizar oxigenio - Se estiver vivo e no momento de atualizar (GJogo.Ciclo=0)
          if (Iniciado = 1) and (GJogo.Ciclo = 0) and (.morreu = 0) then
            if ((Fundo(.X, .Y) = 0) and ((.DirAtual <> 3) or (Fundo(.X, .Y - 1) = 0) or (.Passo < GJogo.Passos / 2))) _
            or ((fundo(.x, .Y + 1) = 0) and (.DirAtual > 3) and (.Passo >= GJogo.Passos / 2)) then
              if .Oxigenio > 10 then .NoOxigenio = 1
              .Oxigenio -= 1
              if .Oxigenio < 0 then
                if .ItOxigenio > 0 then
                  .ItOxigenio -= 1
                  .Oxigenio  = 99
                  .NoOxigenio  = 1
                else
                  .Oxigenio = 0
                  .Morreu   = 1
                end if
              end if
            else
              .NoOxigenio = 0
              if .Oxigenio < 10 then .Oxigenio += 1
            end if
          end if
        end with ' GBoneco
        ' Verifica Movimentação dos objetos
        if Iniciado = 1 then
          with GBoneco
            ' Se estiver indo para a direita, faz a leitura ao contrário
            if (.diratual = 1) or (.DirAtual = 0) and (.UltDir = 1) then
              Emp1 = GMina.Larg
              Emp2 = 0
              Emp3 = -1
            else
              Emp1 = 0
              Emp2 = GMina.Larg
              Emp3 = 1
            end if
          end with
          ' Roda todos os objetos verificando-os   (1 a 1)
          for f = Emp1 to Emp2 step Emp3
            for g = GMina.Alt to 0 step -1
              with GObject(f, g)
                ' Verifica se há movimento
                if (.Passo > 0) or (.empurrando > 0) then
                  ' Dá sequencia
                  .Passo += 1
                  if (.Typ >= 77) and (.Typ <= 80) then
                    .Typ = 77 + 2 * ((.Typ - 77) \ 2) + (.passo mod 2)
                    if .Passo >= GJogo.Passos * 6 then
                      Explode (f, g, (.Typ - 77) \ 2)
                    end if
                  end if
                  ' Verifica se é queda e se com esse passo atingiu o boneco, que estava subindo
                  if (.Caindo = 1) and (GBoneco.X = f) and (GBoneco.Y = g + 2) and (GBoneco.DirAtual = 3) and (GBoneco.Passo + .Passo >= GJogo.Passos) then
                    if GBoneco.Morreu = 0 then
                      GBoneco.Morreu = 1
                      .Passo -= 1
                    end if
                  end if
                  ' Verifica se concluiu movimento (exceto bombas)
                  if (.Passo = GJogo.Passos) and (.Typ < 77) or (.Typ > 80) then
                    if .Caindo = 1 then
                      GObject(f, g + 1).AntCaindo  = 1 ' Informa que ciclo terminou, mas era queda
                      GObject(f, g + 1).Typ        = .Typ
                      GObject(f, g + 1).Passo      = 0
                      GObject(f, g + 1).Empurrando = 0
                      GObject(f, g + 1).Caindo     = 0
                      .AntCaindo  = 0
                      .Passo      = 0
                      .Empurrando = 0
                      .Caindo     = 0
                      .Typ        = 0
                      ' Verifica se a queda do objeto terminou, ou seja, chocou-se sobre outro objeto
                      if (GObject(f, g + 2).caindo = 0) and (comport(GObjectData(GObject(f, g + 2).Typ).Tipo).vazio = 0) then
                        Toca(comport(GObjectData(GObject(f, g + 1).Typ).Tipo).som, comport(GObjectData(GObject(f, g + 2).Typ).Tipo).som) = 1
                      end if
                    end if
                  end if
                'Trata queda de objetos:
                'Verifica se o objeto já estava caindo
                elseif .AntCaindo = 1 then
                  'Verifica se para de cair (cai sobre apoio)
                  if Comport(GObjectData(GObject(f, g + 1).Typ).Tipo).Apoia = 1 then
                    .AntCaindo = 0
                  'Verifica se cai sobre o boneco
                  elseif GBoneco.Morreu = 0 and (GBoneco.Y = g + 1 and ((GBoneco.X = f and GBoneco.DirAtual < 4 and (GBoneco.DirAtual = 0 or GBoneco.Passo < int((GJogo.Passos - 1) * .8))) or _
                  (GBoneco.X = f - 1 and GBoneco.DirAtual = 1) or (GBoneco.X = f + 1 and GBoneco.DirAtual = 2))) then
                    GBoneco.Morreu = 1
                  else  'Se não cai sobre apoio nem sobre o boneco, continua caindo
                    .Caindo = 1
                    .Passo  = 1
                  end if
                'Se não estava caindo, verifica se começa a cair (se não está apoiado por objeto ou pelo boneco)
                elseif Comport(GObjectData(.Typ).Tipo).Cai = 1 and g < GMina.Alt and Comport(GObjectData(GObject(f, g + 1).Typ).Tipo).Apoia = 0 and _
                GObject(f - 1,g + 1).Empurrando <> 1 and GObject(f + 1, g + 1).Empurrando <> 2 then
                  if GBoneco.morreu = 0 and (GBoneco.Y = g + 1 and (GBoneco.X = f or (GBoneco.X = f - 1 and GBoneco.DirAtual = 1) or _
                  (GBoneco.X = f + 1 and GBoneco.DirAtual = 2))) then
                    .AntCaindo = 0
                  else  'Não cai
                    .Caindo = 1
                    .Passo  = 1
                  end if
                end if
              end with
            next
          next
        end if
        if Iniciado = 0 and GMina.tesouros > 0 then
          Desenha
          if GJogo.Status = Testando then
            Mensagem 1, 2, GText(60), GText(96), ""
          else
            Mensagem 1, 2, GText(60), GText(61) & " . . . " & str(int (GTimeStart - Clock + 1)), ""
          end if
          for f = 0 to 9
            GMessage(f).Ciclo = 0
          next
        else
          Sound08
          Desenha
        end if
      else
        TurnOffSounds
      end if
    case Pausado
      DrawBackground
      Mensagem 7, 2, GText(62), GText(63), ""
      if GKey <> "" and GKey <> GKeyBefore then
        GJogo.status = GJogo.StatusAnt
      end if
    case GameOver
      Desenha
      PlaySoundGameOver
      if XM < 30 then
        put ( 240 + XM * 3, XM * 8.5), GBitmap(212), (0, 0) - (112, 28), trans
        put ( 452 - xm * 3, 580- xm * 8.5), GBitmap(212), (18, 33) - (127, 63), trans
        XM += 1
      elseif XM < 60 then
        put (334 + rnd * (60 - XM), 268 + rnd * (60 - XM)), GBitmap(212), trans
        XM += 1
      elseif XM < 2000 then
        put (334 + rnd * (260-XM) / 75, 268 + rnd * (260 - XM) / 75), GBitmap(212), trans
        XM += 1
      else
        PlaySoundTop10
        GKey = "A"
      end if
      if GKey <> "" and GKey <> GKeyBefore then
        PlaySoundTop10
        PosTop10 = EntersTop10
        if PosTop10 > 0 then
          MudaStatus Top10
        else
          MudaStatus NoMenu
        end if
        IniciaJogo
        IniciaVida
        GDemoTimer = Clock
        GRed = int(rnd * 2)
        GGreen = int(rnd * 2)
        GBlue = int(rnd * 2)
        if GRed + GGreen + GBlue = 0 then GBlue = 1
      end if

    case ModoMapa 'Modo de MAPA
      select case GKey
      case "U"
        MapY -= 1
        if MapY < 0 then MapY = 0
      case "D"
        MapY += 1
        if MapY > GMina.Alt - 16 then MapY -= 1
      case "R"
        Mapx += 1
        if MapX > GMina.Larg - 24 then MapX -= 1
      case "L"
        MapX -= 1
        if MapX < 0 then MapX = 0
      case ""
        'Não faz nada
      case else
        if GKeyBefore <> GKey then GJogo.Status = GJogo.StatusAnt
      end select
      'Verifica se acabou o tempo
      if (GJogo.SeqCiclo mod 5=0) and (GJogo.Ciclo=0) and (iniciado > 0) and (GBoneco.morreu = 0) then
        GBoneco.Tempo += 1
        if (GBoneco.tempo>=GMina.tempo) and (GMina.tempo>0) then
          GBoneco.morreu = 1
          GJogo.status = GJogo.StatusAnt
        end if
      end if
      Desenha
      line(2,551)-(545,596),point(2,551),b
      line(3,552)-(544,595), point(3,552),b
      line(4,553)-(543,594), point(4,553),b
      line (5,554)-(542,593),point(5,554),bf
      line(2,597)-(545,597),point(2,597)
      line(110,554)-(110,593),point(2,551)
      Escreve GText(64), 10, 560, 0, 0
      Escreve GText(65), 127, 552, 0, 0
      Escreve GText(66), 115, 572, 0, 0
      if int (Clock * 10) mod 5 <=2 then
        Mensagem 2, 0, GText(64), "", "", 750 - LargTexto (GText(64), 1)/2, 500
      end if

    case Instruc
      DrawBackground
      line (0, 565) - (799, 599), rgb(48 * GRed, 48 * GGreen, 48 * GBlue), BF
      if (GKeyBefore <> GKey and GKey <>"") or (GMBDown = 1) then
        MudaStatus NoMenu
        GJogo.Ciclo=0
        GJogo.SeqCiclo=0
      end if
      PutLogo 290, 40
      EscreveCentro GText(67), 570, 1, 1
      EscreveCentro GText(68), 150
      EscreveCentro GText(69), 180
      EscreveCentro GText(70), 210
      EscreveCentro GText(71), 240
      EscreveCentro GText(72), 270
      EscreveCentro GText(73), 305
      EscreveCentro GText(74), 340,1
      put (370,430), GBitmap(252), trans
      EscreveCentro GText(75), 480, 1, 1

    case VenceuMina 'CONCLUIU A MINA
      Desenha
      if GJogo.StatusAnt = Testando then
        f = EndOfTestConfirmation
      else
        if GMina.Tipo = 0 then
          if GBoneco.Mina < GJogo.NumMinas then
            Mensagem 2, 6, GText(76), GText(77) & ": " & str(GBonus), ""
          else
            Mensagem 2, 6, GText(76), GText(77) & ": " & str(GBonus), GText(94) & ": " & str(GBoneco.Vidas) & " x 1000 = " & str(GBoneco.Vidas * 1000)
          end if
        else
          Mensagem 2, 6, GText(78), GText(77) & ": " & str(GBonus), GText(79) & str(GBoneco.Pontos + GBonus)
        end if
        if GKey <> "" and GKey <> GKeyBefore then
          if GMina.Tipo = 0 then
            if GBoneco.Mina = GJogo.NumMinas then
              MudaStatus VenceuJogo
              QtdNotasVenceu = 0
              UltNotaGameOver = 0
              GJogo.SeqCiclo =- 1
            else
              GBoneco.Mina +=1
              if GBoneco.Mina > GJogo.MaxAlcancada then
                GJogo.MaxAlcancada  = GBoneco.Mina
                RegravaConfig
              end if
              IniciaVida
              MudaStatus Jogando
              LoadMine GBoneco.Mina
              Iniciado=0
              GTimeStart = Clock + 5
            end if
            GBoneco.Pontos += GBonus
            if GBoneco.Mina = GJogo.NumMinas then GBoneco.Pontos += GBoneco.Vidas * 1000
          else
            MudaStatus NoMenu
          end if
        end if
      end if

    case VenceuJogo
      for f = 0 to 19
        g = int(rnd * 100)
        h = int(rnd * 60)
        Frente (g, h) = 0
        Fundo(g, h) = 1
        GObject(g,h).Typ = 40 + int(rnd * 16)
      next
      PlaySoundGameWon
      Desenha
      GJogo.Ciclo=GJogo.passos-1
      Mensagem 0, 12, GText(80), GText(81), ""
      if GKey <> "" and GKey <> GKeyBefore then
        Sound10
        PosTop10 = EntersTop10
        if PosTop10 > 0 then
          MudaStatus Top10
        else
          MudaStatus NoMenu
        end if
        IniciaJogo
        IniciaVida
        LimpaMina
        GDemoTimer = Clock
        GRed = int(rnd * 2)
        GGreen = int(rnd * 2)
        GBlue = int(rnd * 2)
        if GRed + GGreen + GBlue = 0 then GBlue = 1
        GJogo.SeqCiclo = 0
      end if

    case Top10 'TOP 10
      DrawBackground
      DesBox 14, 11, 3, 400, 310
      'Logo
      PutLogo 290, 40
      'Opções:
      EscreveCentro "Top 10", 140, 2, 1
      for f = -1 to 9
        line(197, 200 + f * 30)-step(394, 0), rgb(128, 128, 128)
      next
      if PosTop10 > 0 then
        line(187, 175 + (PosTop10 - 1) * 30)-step(413, 31), rgb(80 + 80 * GRed, 80 + 80 * GGreen, 80 + 80 * GBlue), bf
        line(190, 178 + (PosTop10 - 1) * 30)-step(407, 25), rgb(48 + 48 * GRed, 48 + 48 * GGreen, 48 + 48 * GBlue), bf
      end if
      for f=0 to 9
        g = len(GBestScore(f).Nome)
        while LargTexto (left(GBestScore(f).Nome, g), 1) > 399 - ((largTexto ("0",1)+2) * (1+len(str(GBestScore(f).Pontos))))
          g -= 1
        wend
        Escreve left(GBestScore(f).Nome, g), 198, 180 + f * 30, 1, 0
        Escreve str(GBestScore (f).Pontos), 602 - ((largTexto ("0",1) +2)* ( 1 + len(str(GBestScore(f).Pontos)))), 180 + f * 30, 1, 0
      next

      if ConfirmDel = 0 then
        EscreveCentro GText(82), 520, 1, 0
      elseif ConfirmDel = 1 then
        Mensagem 1, 5, GText(83), GText(84), "", , , Opcao1
      elseif ConfirmDel = 2 then
        Mensagem 0, 5, GText(90), GText(91), "", , , Opcao1
      end if

      if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1

      if (GKey <> GKeyBefore and GKey <> "") or (GMBDown = 1) then
        if ConfirmDel = 0 then
          if GKey = "<" then
            ConfirmDel = 1
            Opcao1 = 1
          else
            PosTop10 = 0
            MudaStatus NoMenu
          end if
        else
          if GKey = "ESC" then
            ConfirmDel = 0
          elseif (GKey = "U") or (GKey = "D") or (GKey = "R") or (GKey = "L") then
            Opcao1 = 1 - Opcao1
          elseif (GKey ="[") or (GKey = "]") or (GMBDown = 1) then
            select case ConfirmDel
            case 1
              if Opcao1 = 0 then
                LimpaTopDez
                PosTop10 = 0
              end if
              ConfirmDel = 2
              Opcao1 = 1

            case 2
              if Opcao1 = 0 then
                GJogo.MaxAlcancada = 1
                RegravaConfig
                ConfirmDel = 0
              else
                ConfirmDel = 0
              end if
            end select
          end if
        end if
      end if

    case Editor
      Edita
      if GJogo.Status = Editor then Desenha

    end select
    'Calcula e mostra FPS
    Quadros += 1
    GTimer2 = Clock
    'Escreve Right ("0000" + str(UltQuadros), 4) , 0, 0, 1, 1
    if int(GTimer2) <> int (GTimer1) then
      GTimer1 = GTimer2
      UltQuadros = Quadros
      Quadros = 0
    end if
    'FLIP + temporizador
    TrocaTelas
TerminaCiclo:
  wend
  DEBUG_LOG("Exit game procedure")
end sub

' Boneco recolhe pedras ou outros objetos
sub PegaObj(POX as integer, POY as integer)
  with GBoneco
    select case GObjectData(GObject(POX, POY).Typ).Item
    case 1
      .ItOxigenio += 1
      Sound11
    case 2
      .ItSuporte += 1
      Sound11
    case 3
      .ItPicareta += 1
      Sound11
    case 4
      .ItFuradeira += 1
      Sound11
    case 5
      .ItBombinha += 1
      Sound11
    case 6
      .ItBombona += 1
      Sound11
    'Recolhe tesouros:
    case 7 to 22
      Sound12
      ConvertPointsToExtraLife PontoTesouro(GObjectData(GObject(POX, POY).Typ).Item)
      MarcaPt(PontoTesouro(GObjectData(GObject(POX, POY).Typ).Item), POX, POY)
      .Pontos += PontoTesouro(GObjectData(GObject(POX, POY).Typ).Item)
      GMina.Tesouros -= 1
      if GMina.Tesouros = 0 then
        GJogo.SeqCiclo = 0
        if GJogo.status = Jogando or GJogo.Status = Testando then 'Termina a fase
          GJogo.StatusAnt = GJogo.Status
          MudaStatus VenceuMina
          CalculaBonusTempo
        else ' Termina a demonstração
          MudaStatus NoMenu
          GRed = int(rnd * 2)
          GGreen = int(rnd * 2)
          GBlue = int(rnd * 2)
          if GRed + GGreen + GBlue = 0 then GBlue = 1
        end if
      end if
    end select
  end with
  'Limpa o objeto
  if GObject(POX, POY).Typ < 77 or GObject(POX, POY).Typ > 80 then
    if Comport(GObjectData(GObject(POX, POY).Typ).Tipo).Anda = 1 then
      GObject(POX,POY).Typ = 0
    end if
    GObject(POX,POY).Caindo = 0
    GObject(POX,POY).AntCaindo = 0
    GObject(POX,POY).Empurrando = 0
    GObject(POX,POY).Passo = 0
  end if
end sub

' Verifica possibilidade e inicia o empurrar de objetos
function EmpurraObj (byval POX as integer, byval POY as integer, byval MDir as integer, byval Peso as integer, byval Quant as integer) as integer
  dim as integer Resultado, XR, PesoTemp
  Resultado= Comport(GObjectData(GObject(POX, POY).Typ).Tipo).PEmpurra
  XR = 3 - (MDir * 2)
  'Antes, verifica se o objeto não está caindo nem vai começar a cair agora
  if (Comport(GObjectData(GObject(POX, POY).Typ).Tipo).Cai = 1 and POY < GMina.Alt and Comport(GObjectData(GObject(POX, POY + 1).Typ).Tipo).Apoia = 0) or GObject(POX, POY).Caindo = 1 then
    Resultado = 5
  else
    'Só faz verificação se ainda não tiver chegado ao canto da mina
    if POX > 0 and POX < GMina.Larg then
      if Resultado + Peso > 2 then
        Resultado = 3
      elseif Resultado = 2 then
        if Quant = 1 and Comport(GObjectData(GObject(POX + XR, POY).Typ).Tipo).Vazio = 1 and GObject(POX + XR, POY - 1).caindo = 0 then
          Resultado = 2
        else
          Resultado = 3
        end if
      elseif Resultado = 1 then
        if Quant = 1 then
          if Comport(GObjectData(GObject(POX + XR, POY).Typ).Tipo).Vazio = 1 and GObject(POX + XR, POY - 1).caindo = 0 then
            Resultado = 1
          else
            PesoTemp = EmpurraObj (POX + XR, POY, MDir, 1, 2)
            if PesoTemp <= 1 then
              Resultado = PesoTemp + 1
            else
              Resultado = 3
            end if
          end if
        elseif quant = 2 and peso < 2 then
          if Comport(GObjectData(GObject(POX + XR, POY).Typ).Tipo).Vazio = 1 and GObject(POX + XR, POY - 1).caindo = 0 then
            Resultado = 1
          else
            Resultado = 3
          end if
        else
          Resultado = 3
        end if
      elseif Resultado = 0 then
        if Peso > 0 and Quant > 2 then
          Resultado = 3
        else
          if Comport(GObjectData(GObject(POX + XR, POY).Typ).Tipo).Vazio = 1 and GObject(POX + XR, POY - 1).caindo = 0 then
            Resultado = Peso
          else
            PesoTemp = EmpurraObj (POX + XR, POY, MDir, Peso, Quant + 1)
            if PesoTemp <= 1 then
              Resultado = Peso
            else
              Resultado=3
            end if
          end if
        end if
      end if
    else
      Resultado = 3
    end if
  end if
  if Resultado < 3 then
    GObject(POX,POY).Empurrando = MDir
    GObject(POX,POY).Passo = 0
  end if
  return Resultado
end function

' Inicia uma explosao (bomba ou morte do boneco)
sub Explode(byval EXX as integer, byval EXY as integer, byval XTam as integer)
  dim as integer LF, LG, NTam
  NTam=XTam
  Sound13(XTam+1)
  if XTam=2 then XTam=1
  GObject(EXX, EXY).Typ = 0
  for LF = -1 to 1
    for lg = -XTam to XTam
      with GObject(EXX+LF,EXY+LG)
        if .Typ >=77 and .Typ<=80 then
          Explode (EXX+LF, EXY+LG, int((.Typ-77)/2))
        elseif Comport(GObjectData(.Typ).Tipo).Destroi>0 then
          .Typ=0
        end if
      end with
    next
  next
  with GBoneco
    if .morreu=0 and .x >= EXX-2 and .X <=EXX+2 then
      if (.X =EXX-2 and .DirAtual=1 and .Passo>=GJogo.Passos * .4) or (.X=EXX-1 and (.dirAtual<>2 or .Passo<=GJogo.Passos * .6)) or .x=EXX or (.x=EXX+1 and (.diratual<>1 or .Passo<=GJogo.Passos * .6)) or (.X =EXX+2 and .DirAtual=2 and .Passo>=GJogo.Passos * .4) then
        if XTam=0 then
          if (.Y =EXY-1 and .DirAtual>3 and .Passo>=GJogo.Passos * .4) or (.Y=EXY and (.dirAtual<3 or .Passo<=GJogo.Passos * .6)) or (.Y =EXY+1 and .DirAtual=3 and .Passo>=GJogo.Passos *.3) then .Morreu=1
        else
          if (.Y =EXY-2 and .DirAtual>3 and .Passo>=GJogo.Passos * .4) or (.Y=EXY-1 and (.dirAtual<>3 or .Passo<=GJogo.Passos * .6)) or .Y=EXY or (.Y=EXY+1 and (.diratual<4 or .Passo<=GJogo.Passos * .6)) or (.Y =EXY+2 and .DirAtual=3 and .Passo>=GJogo.Passos * .4) then .Morreu=1
        end if
      end if
    end if
  end with
  GJogo.UltExplosao = (GJogo.UltExplosao + 1) mod 11
  with Explosao(GJogo.UltExplosao)
    .X=EXX
    .Y=EXY
    .Tipo=XTam+1
    .Tempo=1
  end with
end sub

' Esvazia o conteúdo da matriz da mina
sub LimpaMina
  dim as integer f, g
  for f = -1 to 100
    for g = -1 to 60
      Frente (f, g) = 0
      Fundo (f, g) = 1
      GObject(f, g).Typ = 0
      GObject(f, g).Caindo = 0
      GObject(f, g).AntCaindo = 0
      GObject(f, g).Empurrando = 0
      GObject(f, g).Passo = 0
    next
  next
  GMina.Larg = 99
  GMina.Alt = 59
  GMina.X = 0
  GMina.Y = 0
  GBoneco.X = 0
  GBoneco.Y = 0
  MAPX = 0
  MAPY = 0
end sub

' Reinicia tabela de recordes
sub LimpaTopDez
  kill "top10.min"
  MontaTopDez
  open "top10.min" for output as #1
  for f as integer = 0 to 9
    print #1, GBestScore(f).Nome; ", " ; str(GBestScore(f).Pontos)
  next
  close #1
end sub

' Verifica se está entre os top 10, solicita nome e inclui na tabela
function EntersTop10 as integer
  dim as integer f, LRank = 10
  dim LKey as string
  for f = 9 to 0 step -1
    if GBoneco.Pontos > GBestScore(f).Pontos then LRank = f
  next
  if LRank < 10 then
    for f = 9 to LRank step -1
      GBestScore(f + 1).Pontos = GBestScore(f).Pontos
      GBestScore(f + 1).Nome = GBestScore(f).Nome
    next
    GBestScore(LRank).Pontos = GBoneco.Pontos
    LimpaTeclado
    LKey = ""
    while LKey <> chr(13)
      LKey = inkey
      if len(LKey) > 0 then
        if instr(" " + Lt_, LKey) > 0 and len(GBoneco.Nome) < 20 and LKey <> "," then GBoneco.Nome += LKey
        if (LKey = chr(8) or LKey = chr(255) + chr(83)) and len(GBoneco.Nome) > 0 then GBoneco.Nome = left(GBoneco.Nome, len(GBoneco.Nome) - 1)
      end if
      DrawBackground
      Mensagem 4, 10, GText(85), GText(86), "",, 220
      if GBoneco.Nome = "" then
        Mensagem 2, 10, " ", chr(32 + 63 * (int(Clock * 2) mod 2)), " ",, 360
      else
        Mensagem 2, 10, " ", GBoneco.Nome & chr(32 + 63 * (int(Clock * 2) mod 2)), " ",, 360
      end if
      TrocaTelas
    wend
    cls
    GKeyBefore = "["
    GKey = "["
    if GBoneco.Nome = "" then GBoneco.Nome = "?"
    GBestScore(LRank).Nome = GBoneco.Nome
    LimpaTeclado
    kill "top10.min"
    open "top10.min" for output as #1
    for f = 0 to 9
      print #1, GBestScore(f).Nome; ", " ; str(GBestScore(f).Pontos)
    next
    close #1
  end if
  if LRank < 10 then return LRank + 1 else return 0
end function

' Le a tabela dos TOP 10
sub LeTopDez
  if fileexists("top10.min") then
    open "top10.min" for input as #1
    for f as integer = 0 to 9
      input #1, GBestScore(f).Nome, GBestScore(f).Pontos
    next
    close #1
  else
    MontaTopDez
  end if
end sub

' Reinicia tabela de TOP 10
sub MontaTopDez
  GBestScore(0).Nome = "...." : GBestScore(0).Pontos = 0
  GBestScore(1).Nome = "...." : GBestScore(1).Pontos = 0
  GBestScore(2).Nome = "...." : GBestScore(2).Pontos = 0
  GBestScore(3).Nome = "...." : GBestScore(3).Pontos = 0
  GBestScore(4).Nome = "...." : GBestScore(4).Pontos = 0
  GBestScore(5).Nome = "...." : GBestScore(5).Pontos = 0
  GBestScore(6).Nome = "...." : GBestScore(6).Pontos = 0
  GBestScore(7).Nome = "...." : GBestScore(7).Pontos = 0
  GBestScore(8).Nome = "...." : GBestScore(8).Pontos = 0
  GBestScore(9).Nome = "...." : GBestScore(9).Pontos = 0
end sub

' Faz a troca de screens e ajusta o FPS
sub TrocaTelas
  dim as integer tempo, Falta
  screenset 1 - ScrAtiva,  ScrAtiva
  ScrAtiva = 1 - ScrAtiva
  ATimer = NTimer
  NTimer = int(Clock * 1000)
  Falta = 1
  Tempo = NTimer - ATimer
  Falta = GJogo.DelayMSec - Tempo
  if Falta < 1 then Falta = 1
  if multikey(SC_LSHIFT) or multikey(SC_RSHIFT) then
    sleep 1, 1
  else
    sleep Falta, 1
  end if
 end sub

'Manda desenhar o quadro e escreve as mensagens
sub Mensagem(QCor as integer, Tipo as integer, T1 as string, T2 as string, T3 as string, OX as integer, OY as integer, Opcao as integer)
' Tipos:
' 00 - Sem ícone + pressiona qq tecla
' 01 - Sem ícone + Sim / Não
' 02 - Exclamação + Pressiome qq tecla
' 03 - Exclamação + Sim / Não
' 04 - Interrogação + pressiona qq tecla
' 05 - Interrogação + Sim / Não
' 06 - Ok + pressiona qq tecla
' 07 - Ok + Sim / Não
' 08 - Dame + pressiona qq tecla
' 09 - Dame + Sim / Não
' 10 - Medalha + pressiona qq tecla
' 12 - ByNIZ + pressiona qq tecla
  dim as integer Larg, Alt, v, f
  dim as string Tex(2)
  if T2 = "" then
    Alt = 1
  elseif T3 = "" then
    Alt = 2
  else
    Alt = 3
  end if
  v = Alt
  Tex(0) = T1
  Tex(1) = T2
  Tex(2) = T3
  Larg = 10
  for f = 0 to 2
    if LargTexto(Tex(f), -(f = 0)) > Larg then Larg = LargTexto(Tex(f), -(f = 0))
  next
  Larg = Larg \ 32 + 1
  if Tipo > 1 then Larg += 2
  if (Tipo mod 2 = 1) and (Larg < 7) then Larg = 7
  if Tipo mod 2 = 1 then Alt += 2
  if Tipo > 1 and Alt < 2 then Alt = 2
  DesBox Larg, Alt, QCor, OX, OY
  for f = 0 to v - 1
    Escreve Tex(f), OX - 24 * (Tipo > 1) - LargTexto(Tex(f), -(f = 0)) \ 2, OY - Alt * 16 + f * 32 + 4, -(f = 0), 0
  next
  if Tipo > 1 then put (OX - Larg * 16, OY - Alt * 16), GBitmap(252 + Tipo \ 2),trans
  MouseSimNao = 0
  if Tipo mod 2 = 1 then
    put (OX - 66 + Opcao * 76, Oy + Alt * 16 - 38), GBitmap(276), (576, 0)-(630, 32), trans
    put (OX + 10 - 76 * Opcao, Oy + Alt * 16 - 38), GBitmap(276), (576, 33)-(630, 65), trans
    Escreve GText(58), OX - 38 - LargTexto (GText(58), 0)/2, Oy + Alt * 16 - 32, 0, 0
    Escreve GText(59), OX + 38 - LargTexto (GText(59), 0)/2, Oy + Alt * 16 - 32, 0, 0
    put (OX - 66 + Opcao * 76, Oy + Alt * 16 - 40), GBitmap(276), (576, 66)-(630, 102), trans
    if (GMY > OY + Alt * 16 - 39) and (GMY < Oy + Alt * 16 - 4) then
      if GMX > OX - 67 and GMX < OX - 9 then MouseSimNao = 1
      if GMX > OX + 9 and GMX < OX + 67 then MouseSimNao = 2
    end if
  end if
end sub

'Desenha o quadro (para mensagens)
sub DesBox(h as integer, V as integer, QCor as integer, OX as integer = 400, OY as integer = 300)
  dim as integer f, g
  if QCor < 4 then
    put (OX - 16 - h * 16, OY - 16 - V * 16), GBitmap(248 + QCor), (0, 0)-step(15, 15), alpha
    put (OX - 16 - h * 16, OY + V * 16), GBitmap(248 + QCor), (0, 48)-step(15, 15), alpha
    put (OX + h * 16, OY - 16 - V * 16), GBitmap(248 + QCor), (48, 0)-step(15, 15), alpha
    put (OX + h * 16, OY + V * 16), GBitmap(248 + QCor), (48, 48)-step(15, 15), alpha
    for f = 0 to h - 1
      put (OX - h * 16 + f * 32, OY - 16 - V * 16), GBitmap(248 + QCor), (16, 0)-step(31, 15), alpha
      put (OX - h * 16 + f * 32, OY + V * 16), GBitmap(248 + QCor), (16, 48)-step(31, 15), alpha
      for g = 0  to V - 1
        put (OX - h * 16 + f * 32, OY - V * 16 + g * 32), GBitmap(248 + QCor), (16, 16)-step(31, 31), alpha
      next
    next
    for g = 0  to V - 1
      put (OX - 16- h * 16, OY - V * 16 + g * 32), GBitmap(248 + QCor), (0, 16)-step(15, 31), alpha
      put (OX + h * 16, OY - V * 16 + g * 32), GBitmap(248 + QCor), (48, 16)-step(15, 31), alpha
    next
  else
    QCor -= 4
    put (OX - 16 - h * 16, OY - 16 - V * 16), GBitmap(248 + QCor), (0, 0)-step(15, 15), trans
    put (OX - 16 - h * 16, OY + V * 16), GBitmap(248 + QCor), (0, 48)-step(15, 15), trans
    put (OX + h * 16, OY - 16 - V * 16), GBitmap(248 + QCor), (48, 0)-step(15, 15), trans
    put (OX + h * 16, OY + V * 16), GBitmap(248 + QCor), (48, 48)-step(15, 15), trans
    for f = 0 to h - 1
      put (OX - h * 16 + f * 32, OY - 16 - V * 16), GBitmap(248 + QCor), (16, 0)-step(31, 15), trans
      put (OX - h * 16 + f * 32, OY + V * 16), GBitmap(248 + QCor), (16, 48)-step(31, 15), trans
      for g = 0  to V - 1
        put (OX - h * 16 + f * 32, OY - V * 16 + g * 32), GBitmap(248 + QCor), (16, 16)-step(31, 31), trans
      next
    next
    for g = 0  to V - 1
      put (OX - 16- h * 16, OY - V * 16 + g * 32), GBitmap(248 + QCor), (0, 16)-step(15, 31), trans
      put (OX + h * 16, OY - V * 16 + g * 32), GBitmap(248 + QCor), (48, 16)-step(15, 31), trans
    next
  end if
end sub

sub PutLogo (LX as integer, LY as integer)
  put (LX, LY), GBitmap(211), trans
end sub

function CTRX as integer
  with GBoneco
    if .X < 12 then
      return .X * 32 + 16
    elseif .X > GMina.Larg - 12 then
      return 784 - (GMina.Larg - .X) * 32
    else
      return 399
    end if
  end with
end function

function CTRY as integer
  with GBoneco
    if .Y < 8 then
      return .Y * 32 + 16
    elseif .Y > GMina.Alt - 8 then
      return 500 - (GMina.Alt - .Y) * 32
    else
      return 240
    end if
  end with
end function

sub MarcaPt(Pontos as integer, X as integer, Y as integer)
  with GMessage(ProxMsg)
    .Ciclo = 63
    .Pontos = Pontos
    .X = X
    .Y = Y
  end with
  ProxMsg = (ProxMsg + 1) mod 10
end sub

'Simula pressionamento de teclas no modo demo
function ProximaTeclaDemo as string
  dim TecTemp as string
  dim as integer ValTemp, BX, BY
  BX = GBoneco.X
  BY = GBoneco.Y
  if GBoneco.Passo = GJogo.Passos then
    select case GBoneco.DirAtual
    case 1
      bx = bx + 1
    case 2
      bx = bx - 1
    case 3
      by = by - 1
    case 4, 5
      by = by + 1
    end select
  end if
  if TempMens > 0 then
    TempMens = TempMens-1
    if TempMens > 0 then
      return " "
      goto SaiDaqui
    end if
  end if
  MensDemo = 0
Proximo:
  if PositDemo > len(TeclasDemo)/3 then
    PositDemo = 0
    return "ESC"
  else
    TecTemp = mid(teclasdemo, positdemo * 3 + 1, 1)
    select case TecTemp
    case "M"
      MensDemo = val(mid(teclasdemo, positdemo * 3 + 2, 2))
      TempMens = 250
      PositDemo = PositDemo + 1
      return " "
    case "#"
      return "ESC"
      PositDemo = 0
    case "W"
      ValTemp=val(mid(teclasdemo, positdemo * 3 + 2, 2))
      if DemoW1 = 0 then
        DemoW1 = ValTemp
        DemoW2 = 0
      else
        DemoW2 = DemoW2 + 1
        if DemoW2 >= DemoW1 then
          DemoW1 = 0
          DemoW2 = 0
          PositDemo = PositDemo + 1
          goto Proximo
        end if
      end if
      return ""
    case "I"
      TecTemp = mid(teclasdemo, positdemo * 3 + 2, 1)
      if TecTemp="D" then TecTemp="V"
      if TecTemp="C" then
        if mid(teclasdemo, positdemo * 3 + 3, 1) = "R" then
          GBoneco.DirFuradeira = 1
        elseif mid(teclasdemo, positdemo * 3 + 3, 1) = "L" then
          GBoneco.DirFuradeira = 2
        end if
      end if
      PositDemo = PositDemo + 1
      return TecTemp
    case "R"
      ValTemp=val(mid(teclasdemo, positdemo * 3 + 2, 2))
      if bX < ValTemp then
        return TecTemp
      else
        PositDemo = PositDemo + 1
        goto Proximo
      end if
    case "L"
      ValTemp=val(mid(teclasdemo, positdemo * 3 + 2, 2))
      if bX > ValTemp then
        return TecTemp
      else
        PositDemo = PositDemo + 1
        goto Proximo
      end if
    case "U", "D"
      ValTemp=val(mid(teclasdemo, positdemo * 3 + 2, 2))
      if bY <> ValTemp then
        return TecTemp
      else
        PositDemo = PositDemo + 1
        goto Proximo
      end if
    end select
  end if
SaiDaqui:
end function

' Le mina do arquivo (padrão)
sub LoadMine(NMina as integer, SoQuant as integer)
  dim as longint FilePos, FileTam
  dim as ushort MinaTemp, TotMinas
  dim as ubyte Temporary1
  LimpaMina
  GMina.Tesouros = 0
  if fileexists("minas.bin") then
    open "minas.bin" for binary as #1
    FileTam = lof(1)
    if FileTam > 20 then
      get #1,, TotMinas
      GJogo.NumMinas = TotMinas
      FilePos = 3
      if SoQuant = 0 then
        get #1,, MinaTemp
        get #1,, GMina.Larg
        get #1,, GMina.Alt
        get #1,, GMina.Noturno
        get #1,, GMina.Tempo
        while MinaTemp < NMina
          FilePos = FilePos + ((GMina.Alt * GMina.Larg) * 3) + 9
          get #1, FilePos, MinaTemp
          get #1,, GMina.Larg
          get #1,, GMina.Alt
          get #1,, GMina.Noturno
          get #1,, GMina.Tempo
        wend
        LeMinaDet 0
      end if
    else
      Mensagem 4, 8, GText(87), GText(0), ""
      MudaStatus NoMenu
    end if
    close #1
  else ' Arquivo não existe
    Mensagem 4, 8, GText(88), GText(0), ""
    MudaStatus NoMenu
  end if
end sub

'Le o desenho da mina (tiles)
sub LeMinaDet(Editando as integer)
  dim as integer MXR, MYR, f, g
  MXR = 0
  MYR = 0
  if Editando = 0 then
    if GMina.Larg < 24 then MXR = (25 - GMina.Larg) \ 2
    if GMina.alt < 16 then MYR = (17 - GMina.Alt) \ 2
    for f = -1 to GMina.Larg
      for g = -1 to GMina.alt
        GObject(mxr + f, myr + g).Typ = 31
      next
    next
  end if
  GMina.Larg -= 1
  GMina.Alt -= 1
  ' Lê cada linha
  for g = 0 to GMina.Alt
    ' Le linha
    for f = 0 to GMina.Larg
      get #1,, Fundo(MXR + f, MYR + g)
      get #1,, Frente(MXR + f, MYR + g)
      get #1,, GObject(MXR + f, MYR + g).Typ
      ' Posição inicial do boneco
      if GObject(MXR + f, MYR + g).Typ = 85 then
        GMina.X = MXR + f
        GMina.Y = MYR + g
        GBoneco.X = GMina.X
        GBoneco.Y = GMina.Y
        GObject(MXR + f, MYR + g).Typ = 0
      elseif GObjectData(GObject(MXR + f, MYR + g).Typ).Tipo = 5 then
        GMina.Tesouros +=1
      end if
    next
  next
  sleep 1, 1
  GMina.Larg += MXR
  GMina.Alt += MYR
  GJogo.UltExplosao = 0
  GJogo.Ciclo = 0
  Iniciado = 0
end sub

' Faz levantamento e contagem das minas personalizadas
sub SearchCustomMines
  dim as string Narq
  dim as integer Ordem, f
  screenset ScrAtiva, ScrAtiva
  Ordem = 0
  line (298, 320)-(502, 344), &HFFFFFF, b
  for f = 0 to 999
    line (300 + f \ 5, 322)-step(0, 20), &H7080F0
    NArq = "minas/m" + right("000" & str(f), 3) + ".map"
    if fileexists(Narq) then
      MinaPers(Ordem) = f
      Ordem +=1
    end if
  next
  if Ordem < 999 then
    for f = Ordem to 999
      MinaPers(f) = 0
    next
  end if
  GBoneco.Mina = MinaPers(0)
  QuantPers = Ordem
end sub

sub PlaySoundGameOver
  dim Nota as integer
  if GJogo.Status <> GameOver or (rnd * 500) < 10 then
    Nota = (int(rnd * 32) + 64) shl 8
    PlaySoundGameOver(Nota)
  end if
end sub

sub PlaySoundGameWon
  dim Nota as integer
  if (QtdNotasVenceu = 0) or (QtdNotasVenceu < 6) and (Clock - TimerNotaVenceu >= .11) then
    QtdNotasVenceu += 1
    if QtdNotasVenceu = 1 then
      Nota = (int(rnd * 32) + 36) shl 8
    else
      Nota = (int(rnd * 6) + (UltNotaGameOver shr 8) - 1) shl 8
      if Nota = ultNotaGameOver then Nota -= 512
    end if
    PlaySoundGameWon(Nota)
    TimerNotaVenceu = Clock
  elseif Clock - TimerNotaVenceu >= .6 then
    QtdNotasVenceu = 0
  end if
end sub

' Regrava configurações: Volume e maior mina alcançada
sub RegravaConfig
  kill "config.min"
  open "config.min" for output as #1
  print #1, GJogo.Volume
  print #1, GJogo.MaxAlcancada
  print #1, GCurrLangName
  close #1
end sub

' Le textos do programa, no idioma selecionado
function LoadLanguage(ALang as string) as integer
  dim as integer f
  if fileexists ("lang/" + ALang + ".lng") then
    open "lang/" + ALang + ".lng" for input as #1
    f = 0
    while not eof (1)
      input #1, GText(f)
      f += 1
    wend
    close #1
    return 0
  else
    return 1
  end if
end function

sub LoadLanguageNames
  dim as string Arquivo = dir("lang/*.lng")
  GLangCount = 0
  while len(Arquivo) > 0 and GLangCount < 9
    GLangName(GLangCount) = left(Arquivo, len(Arquivo) - 4)
    GLangCount += 1
    Arquivo = dir()
  wend
  GCurrLangIndex = 0
  for f as integer = 0 to GLangCount
    if GLangName(f) = GCurrLangName then GCurrLangIndex = f
  next
end sub

sub ConvertPointsToExtraLife(APoints as integer)
  if (GBoneco.Pontos) \ 1000 < (GBoneco.Pontos + APoints) \ 1000 then
    GBoneco.Vidas += 1
  end if
end sub

' Calcula o bonus de acordo com o tempo para concluir a mina
sub CalculaBonusTempo
  if GMina.Tempo = 0 then
    GBonus = (300 - GBoneco.Tempo)
    if GBonus > 100 then GBonus = 100
  else
    GBonus = (GMina.Tempo - GBoneco.Tempo)
    if GBonus > 100 then GBonus = 100
  end if
  ConvertPointsToExtraLife GBonus
end sub

'ROTINAS REFERENTES AO EDITOR DE MINAS

'Escreve um número pequeno e de 2 algarismos como cabeçalho de linha e coluna
sub EscreveNumeroPeq (byval Numero as integer, X1 as integer, Y1 as integer)
  put (x1, Y1), GBitmap(274), ((Numero \ 10) * 6, 0)-step(5, 7), trans
  put (x1 + 6, Y1), GBitmap(274), ((Numero mod 10) * 6, 0)- step(5, 7), trans
end sub

'Desenha um quadro
sub Dlinha (x1 as integer, y1 as integer, x2 as integer, y2 as integer, QualCor as integer)
  select case QualCor
  case 0
    CorRGB = &H00FF00
  case 1
    CorRGB = &HFFFF00
  case 2
    CorRGB = &HFF4040
  case 3
    CorRGB = &H9F0000
  end select
  line (x1, y1)-(x2, y1 + 2), CorRGB, BF
  line (x1, y1)-(x1 + 2, y2), CorRGB, BF
  line (x1, y2 - 2)-(x2, y2), CorRGB, BF
  line (x2 - 2, y1)-(x2, y2), CorRGB, BF
end sub

'Conta as pedras existentes na mina
function ContaTesouros as integer
  dim as integer f, g
  dim Contagem as integer
  Contagem = 0
  for f=0 to 99
    for g =0 to 59
      if (GObject(f, g).Typ >= 40) and (GObject(f, g).Typ <= 55) then Contagem += 1
    next
  next
  return Contagem
end function

'Acha a coluna do objeto mais abaixo
function MaiorLinha as integer
  dim as integer LMax, f, g
  LMax = 1
  for f = 0 to 99
    for g = 0 to 59
      if GObject(f,g).Typ > 0 or fundo (f, g) <> 1 or frente (f,g )>0 then
        if g > LMaX then LMaX = g
      end if
    next
  next
  return LMax
end function

'Acha a coluna do objeto mais à direita
function MaiorColuna as integer
  dim as integer LMax, f, g
  LMax = 1
  for f = 0 to 99
    for g = 0 to 59
      if GObject(f,g).Typ > 0 or fundo (f, g) <> 1 or frente (f,g )>0 then
        if f > LMaX then LMaX = f
      end if
    next
  next
  return LMax
end function

'Salva a mina em arquivo
sub SalvaMina (ParaTestar as integer = 0)
  dim as string Linha, NArq, LMNum, GLMKey
  dim as integer nmina, MaiorX, MaiorY, ValTemp, f, g
  'zera contador de tesouros para verificar se tem
  GMina.Tesouros = ContaTesouros ()
  cls
  TrocaTelas
  if GMina.tesouros = 0 then
    LimpaTeclado
    cls
    Mensagem 5, 8, GText(100), "", ""
    TrocaTelas
    cls
    while inkey <> ""
      sleep 1, 1
    wend
    while inkey = ""
      sleep 1, 1
    wend
    LimpaTeclado
  else
    if ParaTestar = 0 then
      LMNum= str(GMina.numero)
      LimpaTeclado
      GLMKey = ""
      while (GLMKey <> chr(27)) and (GLMKey <> chr(13))
        cls
        Mensagem 5, 4, GText(101), GText(102), LMNum & chr (32 + 63 * (int(Clock * 2) mod 2))
        if GLMKey >= "0" and GLMKey <= "9" and len(LMNum) < 3 then
          if LMNum = "0" then LMNum = "0"
          LMNum += GLMKey
        elseif GLMKey = chr(8) or GLMKey = c255 + chr(83) then
          lMNum = left (LMNum, len(LMNum) - 1)
        end if
        TrocaTelas
        GLMKey = inkey
      wend
      cls
      TrocaTelas
      NArq = "minas/m" + right("000" & str(LMNum), 3) + ".map"
      GMina.numero= val(LMNum)
    else
      NArq = "minas/teste.map"
    end if
    cls
    if (ParaTestar <> 0) or (GLMKey = chr(13)) then
      if ParaTestar = 0 then
        GLMKey = ""
        while inkey <> ""
          sleep 10, 1
        wend
        Opcao1 = GMina.Noturno
        while (GLMKey <> " ") and (GLMKey <> chr(27)) and (GLMKey <> chr(13))
          cls
          Mensagem 5, 5, GText(103), GText(104), "",,, Opcao1
          GLMKey = inkey
          GetMouseState
          if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
          if (GMBDown = 1) and (MouseSimNao > 0) then GLMKey = " "
          if (GLMKey = c255 + "H") or (GLMKey = c255 + "K") or (GLMKey = c255 + "M") or (GLMKey = c255 + "P") then Opcao1 = 1 - Opcao1
          TrocaTelas
        wend
        cls
      end if
      if (ParaTestar <> 0) or (GLMKey <> chr(27)) then
        if ParaTestar = 0 then
          GMina.Noturno = Opcao1
          LMNum=str(GMina.Tempo)
          while inkey <> ""
            sleep 10
          wend
          GLMKey = ""
          while GLMKey <> chr(27) and GLMKey <> chr(13)
            cls
            Mensagem 5, 4, GText(106), GText(107), LMNum & chr(32 + 63 * (int(Clock * 2) mod 2))
            if (GLMKey >= "0") and (GLMKey <= "9") and (len(LMNum) < 5) then
              if LMNum = "0" then LMNum = ""
              LMNum += GLMKey
            elseif (GLMKey = chr(8)) or (GLMKey = c255 + chr(83)) then
              lMNum = left(LMNum, len(LMNum) - 1)
            end if
            GLMKey = inkey
            TrocaTelas
          wend
          cls
        end if
        if (ParaTestar <> 0) or (GLMKey = chr(13)) then
          if ParaTestar = 0 then
            GMina.Tempo = val(LMNum)
            GMina.Alterada = 0
            EdShow = 2
          end if
          ' Inicia gravação da mina
          GMina.Larg = MaiorColuna + 1
          GMina.Alt = MaiorLinha + 1
          ' Salva dimensões, se é noturno/diurno e o tempo (0=livre)
          kill Narq
          open NArq for binary as #1
          put #1,, GMina.Larg
          put #1,, GMina.Alt
          put #1,, GMina.Noturno
          put #1,, GMina.Tempo
          'Escreve cada linha
          for g = 0 to GMina.Alt - 1
            for f = 0 to GMina.Larg - 1
              put #1,, fundo(f, g)
              put #1,, frente(f, g)
              if GBoneco.x = f and GBoneco.y = g then
                GObject(f, g).Typ = 85
                put #1,, GObject(f, g).Typ
                GObject(f, g).Typ = 0
              else
                put #1,, GObject(f, g).Typ
              end if
            next
          next
          close #1
          cls
          TrocaTelas
          cls
          if ParaTestar = 0 then
            Mensagem 6, 6, GText(112), "", ""
            TrocaTelas
            while inkey <> ""
              sleep 1, 1
            wend
            while inkey = ""
              sleep 1, 1
            wend
            cls
          end if
          LimpaTeclado
        else
          GKeyBefore = "ESC"
        end if
      else
        GKeyBefore = "ESC"
      end if
    else
      GKeyBefore = "ESC"
    end if
  end if
  LimpaTeclado
end sub

' Rotina principal do EDITOR - pode ser mudada para um item dentro de "Joga"
sub Edita
  dim as integer f, g
  PosMouse = PosMouseEd
  select case GJogo.EdStatus
  case Editando
    EdX1 = GMX \ 32
    EdY1 = GMY \ 32
    select case GKey
    case "ESC"
      if GKey <> GKeyBefore then GJogo.EdStatus = RespExit
    case "U"
      MapY -= 1
      if MapY < 0 then MapY = 0
    case "D"
      MapY += 1
      if MapY > 43 then MapY = 43
    case "R"
      Mapx += 1
      if MapX > 75 then MapX = 75
    case "L"
      MapX-=1
      if MapX < 0 then MapX = 0
    end select
    if (GMBDown = 1) or ((GMB > 0) and ((PosMouse = EdBarra) or (PosMouse = EdEsquerda) or (PosMouse = EdDireita))) then
      select case PosMouse
      case EdForaTela
        ' Nada a fazer
      case EdTela
        EdX2 = EDX1
        EdY2 = EDY1
        EdXX1 = EDX1
        EdXX2 = EDX2
        EdYY1 = EDY1
        EdYY2 = EDY2
        if ItemSel = 0 then
          if (GBoneco.x <> Mapx + edx1) or (GBoneco.y <> Mapy + edy1) then
            GravaUndo
            GBoneco.x = Mapx + edx1
            GBoneco.y = Mapy + edy1
            GMina.Alterada = 1
          end if
        else
          GJogo.EdStatus = Selecionando
        end if
      case EdInicio
        PrimeiroItem = 0
      case EdEsquerda
        PrimeiroItem -= 1
        if PrimeiroItem < 0 then PrimeiroItem = 0
      case EdDireita
        PrimeiroItem += 1
        if PrimeiroItem > 100 then PrimeiroItem = 100
      case EdFim
        PrimeiroItem = 100
      case EdBarra
        PrimeiroItem = int((GMX - 80) / 4.48)
        if PrimeiroItem < 0 then PrimeiroItem = 0
        if PrimeiroItem > 100 then PrimeiroItem = 100
      case EdItem
        ItemSel = PrimeiroItem + GMX \ 34
      case EdNovo
        GJogo.EdStatus = RespNovo
      case EdAbre
        GJogo.EdStatus = RespAbrindo
      case EdMove
        GJogo.EdStatus = EdMovendo
        EdMovendoUndo = 0
      case EdSalva
        GJogo.EdStatus = RespSalvar
        GUMKey = str(GMina.Numero)
      case EdVisao
        EdShow = (Edshow + 1) mod 4
      case EdMudaGrid
        EdGrid = (EdGrid + 1) mod 8
      case EdApaga
        EdXX1 = -1
        EdXX2 = -1
        EdYY1 = -1
        EdYY2 = -1
        EdX1 = -1
        EdY1 = -1
        GJogo.EdStatus = Apagando0
      case EdTesta
        GJogo.EdStatus = RespTesta
      case EdUndo
        FazUndo
      case EdRedo
        FazRedo
      case EdExit
        GJogo.EdStatus = RespExit
      end select
    end if
  case Selecionando
    if PosMouse = EdTela then
      EdX2 = GMX \ 32
      EdY2 = GMY \ 32
      SwapEDXY
      if (GKey = "ESC") and (GKeyBefore <> GKey) then
        GJogo.EdStatus = Editando
      else
        if GMBUp = 1 then
          GJogo.EdStatus = Editando
          GravaUndo
          GMina.Alterada = 1
          for f = EDXX1 to EDXX2
            for g = EDYY1 to EDYY2
              select case ItemSel
              case 1 to 25
                Fundo(MAPX + f, MAPY + g) = ItemSel - 1
              case 26 to 37
                Frente(MAPX + f, MAPY + g) = ItemSel - 26
              case 38 to 114
                GObject(MAPX + f, MAPY + g).Typ = ItemSel - 38
              case else
                GObject(MAPX + f, MAPY + g).Typ = ItemSel - 33
              end select
            next
          next
        end if
      end if
    end if
  case RespNovo
    if CloseUnsavedMineConfirmation () = 1 then
      GravaUndo
      for f = -1 to 100
        for g = -1 to 60
          GObject(f, g).Typ = 0
          fundo  (f, g) = 1
          frente (f, g) = 0
        next
      next
      GBoneco.x = 0
      GBoneco.y = 0
    end if
    GJogo.EdStatus = Editando
  case RespAbrindo
    if CloseUnsavedMineConfirmation = 1 then
      Opcao1 = 0
      GBoneco.Mina = 0
      cls
      TrocaTelas
      cls
      Mensagem 7, 8, GText(92), GText(93), " "
      SearchCustomMines
      TrocaTelas
      cls
      MudaStatus Configs
    else
      GJogo.EdStatus = Editando
    end if
  case EdMovendo
    if GKeyBefore <> GKey then
      select case GKey
      case "U"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        GMina.Alterada = 1
        for f = 0 to 99
          for g = 0 to 59
            GObject(f, g) = GObject(f, g + 1)
            fundo  (f, g) = fundo  (f, g + 1)
            frente (f, g) = frente (f, g + 1)
          next
        next
        if GBoneco.y > 0 then GBoneco.y -= 1
        GObject(GBoneco.x, GBoneco.y).Typ = 0
      case "D"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        GMina.Alterada = 1
        for f = 0 to 99
          for g = 59 to 0 step -1
            GObject(f, g) = GObject(f, g - 1)
            fundo  (f, g) = fundo  (f, g - 1)
            frente (f, g) = frente (f, g - 1)
          next
        next
        if GBoneco.y < 59 then GBoneco.y += 1
        GObject(GBoneco.x, GBoneco.y).Typ = 0
      case "R"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        GMina.Alterada = 1
        for f = 99 to 0 step -1
          for g = 0 to 59
            GObject(f, g) = GObject(f - 1, g)
            fundo(f, g)  = fundo  (f - 1, g)
            frente(f, g) = frente (f - 1, g)
          next
        next
        if GBoneco.x < 99 then GBoneco.x += 1
        GObject(GBoneco.x, GBoneco.y).Typ = 0
      case "L"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        GMina.Alterada = 1
        for f = 0 to 99
          for g = 0 to 59
            GObject(f, g) = GObject(f + 1, g)
            fundo  (f, g) = fundo  (f + 1, g)
            frente (f, g) = frente (f + 1, g)
          next
        next
        if GBoneco.x > 0 then GBoneco.x -= 1
        GObject(GBoneco.x, GBoneco.y).Typ = 0
      case "[", "]", "ESC"
        GJogo.EdStatus = Editando
        EdMovendoUndo = 0
      end select
    end if
  case RespSalvar
    SalvaMina
    GJogo.EdStatus = Editando
  case Apagando0
    if PosMouse = EdTela then
      EdX1 = int (GMX / 32)
      EdY1 = int (GMY / 32)
    end if
    if GKey = "ESC" and GKeyBefore <> GKey then
      GJogo.EdStatus = Editando
    end if
    if GMBDown = 1 then
      if PosMouse = EdTela then
        EdMon = 1
        EdX2 = EDX1
        EdY2 = EDY1
        EdXX1 = EDX1
        EdXX2 = EDX2
        EdYY1 = EDY1
        EdYY2 = EDY2
        GJogo.EdStatus = apagando1
      end if
    end if
  case Apagando1
    if PosMouse = EdTela then
      EdX2 = int (GMX / 32)
      EdY2 = int (GMY / 32)
      SwapEDXY
      if (GKey = "ESC") and (GKeyBefore <> GKey) then
        GJogo.EdStatus = Editando
      else
        if GMBUp = 1 then
          GJogo.EdStatus = Editando
          GravaUndo
          GMina.Alterada = 1
          for f = EDXX1 to EDXX2
            for g = EDYY1 to EDYY2
              Fundo (MAPX + f, MAPY + g) = 1
              Frente (MAPX + f, MAPY + g) = 0
              GObject(MAPX + f, MAPY + g).Typ = 0
            next
          next
        end if
      end if
    end if
  case RespTesta
    Opcao1 = 0
    GLMKey = ""
    if ContaTesouros () = 0 then
      cls
      TrocaTelas
      cls
      Mensagem 5, 8, GText(100), "", ""
      GJogo.EdStatus = Editando
      TrocaTelas
      cls
      while inkey = ""
        sleep 1, 1
      wend
      LimpaTeclado
    else
      while (GLMKey <> " ") and (GLMKey <> chr(13)) and (GLMKey <> chr(27))
        cls
        Mensagem 4, 5, GText(108), "", "", 400, 300, Opcao1
        GLMKey=inkey
        GetMouseState
        if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
        if (GMBDown = 1) and (MouseSimNao > 0) then GLMKey = " "
        if (GLMKey = c255 + "H") or (GLMKey = c255 + "K") or (GLMKey = c255 + "M") or (GLMKey = c255 + "P") then Opcao1 = 1 - Opcao1
        TrocaTelas
        GJogo.SeqCiclo=(GJogo.SeqCiclo + 1) mod 360
      wend
      cls
      if (Opcao1 = 1) or (GLMKey = chr(27)) then
        GJogo.EdStatus = Editando
      else
        SalvaMina -1
        LoadCustomMine -1, 0
        IniciaVida
        MudaStatus Testando
      end if
      LimpaTeclado 1
    end if
  case RespExit
    Opcao1 = 1
    GLMKey = ""
    while (GLMKey <> " ") and (GLMKey <> chr(13)) and (GLMKey <> chr(27))
      cls
      if GMina.Alterada = 1 then
        Mensagem 4, 5, GText(98), GText(105), "", 400, 300, Opcao1
      else
        Mensagem 4, 5, GText(105), "", "", 400, 300, Opcao1
      end if
      GLMKey = inkey
      GetMouseState
      if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
      if (GMBDown = 1) and (MouseSimNao > 0) then GLMKey = " "
      if (GLMKey = c255 + "H") or (GLMKey = c255 + "K") or (GLMKey = c255 + "M") or (GLMKey = c255 + "P") then Opcao1 = 1 - Opcao1
      TrocaTelas
      GJogo.SeqCiclo=(GJogo.SeqCiclo+1) mod 360
    wend
    cls
    if (Opcao1 = 1) or (GLMKey = chr(27)) then
      GJogo.EdStatus = Editando
    else
      MudaStatus NoMenu
    end if
    LimpaTeclado 1
  end select
  GObject(GBoneco.x, GBoneco.y).Typ = 0
end sub

sub EncerraTeste
  LoadCustomMine -1, 1
  MudaStatus Editor
  kill "minas/teste.map"
end sub

' Desenha um item na tela do editor, conforme seu tipo
sub DesenhaItem(ITX as integer, ITY as integer, ITN as integer)
  if ITN = 0 then ' Boneco (ITN = 0)
    put (ITX, ITY), GBitmap(116), trans
  elseif ITN = 1 then ' Fundo 0 = água (ITN = 1)
    put (ITX, ITY), GBitmap(213), pset
  elseif ITN = 2 then ' Fundo 1 = vazio
    line (ITX, ITY)-step(31, 31), &HFFFFFF, B
    Escreve "Fu", ITX + 7, ITY - 1
    Escreve "vz", ITX + 7, ITY + 13
    line (ITX, ITY + 31)-step(31, -31), &HFFFFFF
  elseif ITN  < 26 then ' Fundos 1 a 24 (ITN = 2 a 25)
    put (ITX, ITY), GBitmap(ITN - 1), pset
  elseif ITN = 26 then  ' Frente 0 = vazio
    line (ITX, ITY)-step(31, 31), &HFFFFFF, B
    Escreve "Fr", ITX + 7, ITY - 1
    Escreve "vz", ITX + 7, ITY + 13
    line (ITX, ITY + 31)-step(31, -31), &HFFFFFF
  elseif ITN < 38 then  ' Frentes 0 a 10
    put (ITX, ITY), GBitmap(ITN - 2), trans
  elseif ITN = 38 then  ' GObject 0 = vazio
    line (ITX, ITY)-step(31, 31), &HFFFFFF, B
    Escreve "Obj", ITX + 3, ITY - 1
    Escreve "vz", ITX + 7, ITY + 13
    line (ITX, ITY + 31)-step(31, - 31), &HFFFFFF
  elseif ITN < 115 then
    put (ITX, ITY), GBitmap(GObjectData(ITN - 38).Img), trans
  elseif ITN < 123 then
    put (ITX, ITY), GBitmap(GObjectData(ITN - 33).Img), trans
  else
    Escreve "?", ITX + 10, ITY + 7
  end if
end sub

' Encontra a posição do mouse (sobre qual comando ele está)
function PosMouseEd as integer
  dim LResult as integer
  if GMY >= 544 then
    if GMX < 611 then
      if GMY > 564 then
        LResult = EdItem
      else
        if GMX < 23 then
          LResult = EdInicio
        elseif GMX < 46 then
          LResult = EdEsquerda
        elseif GMX < 565 then
          LResult = EdBarra
        elseif GMX < 588 then
          LResult = EdDireita
        else
          LResult = EdFim
        end if
      end if
    elseif GMX > 612 then
      if GMX < 640 then
        if GMY < 572 then
          LResult = EdNovo
        else
          LResult = EdMove
        end if
      elseif GMX < 667 then
        if GMY < 572 then
          LResult = EdAbre
        else
          LResult = EdSalva
        end if
      elseif GMX < 719 then
        LResult = EdVisao
      elseif GMX < 746 then
        if GMY < 572 then
          LResult = EdMudaGrid
        else
          LResult = EdUndo
        end if
      elseif GMX < 773 then
        if GMY < 572 then
          LResult = EdApaga
        else
          LResult = EdRedo
        end if
      else
        if GMY < 572 then
          LResult = EdTesta
        else
          LResult = EdExit
        end if
      end if
    end if
  elseif (GMY > 0) and (GMX > 0) and (GMX <= 799) then
    LResult = EdTela
  else
    LResult = EdForaTela
  end if
  return LResult
end function

sub ClearEditorMine
  dim as integer f, g, h
  for h = 0 to MaxUndo
    for f = -1 to 100
      for g = -1 to 60
        UndoFrente(h, f, g) = 0
        UndoFundo (h, f, g) = 1
        UndoObjeto(h, f, g) = 0
      next
    next
    BonecoX(h) = 0
    BonecoY(h) = 0
  next
  GMina.Alterada = 0
  GLMKey = ""
  GUMKey = ""
  PrimeiroItem = 0
  ItemSel = 0
  EdShow = 2
  EdGrid = 0
  MatrizAtual = 0
  MatrizRedoLimite = 0
  MatrizUndoLimite = 0
  EdMovendoUndo = 0
  GMina.Tempo = 0
  GMina.Numero = 0
  GMina.Noturno = 0
end sub

' Pergunta se pode fechar mina não salva
function CloseUnsavedMineConfirmation as integer
  dim i as integer
  if GJogo.EdStatus = RespNovo then
    i = 99
  elseif GJogo.EdStatus = RespAbrindo then
    i = 113
  end if
  Opcao1 = 1
  GLMKey = ""
  while (GLMKey <> " ") and (GLMKey <> chr(13)) and (GLMKey <> chr(27))
    cls
    if GMina.Alterada = 1 then
      Mensagem 4, 5, GText(98), GText(i), "", 400, 300, Opcao1
    else
      Mensagem 4, 5, GText(i), "", "", 400, 300, Opcao1
    end if
    GLMKey = inkey
    GetMouseState
    if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
    if (GMBDown = 1) and (MouseSimNao > 0) then GLMKey = " "
    if (GLMKey = c255 + "H") or (GLMKey = c255 + "K") or (GLMKey = c255 + "M") or (GLMKey = c255 + "P") then Opcao1 = 1 - Opcao1
    TrocaTelas
    GJogo.SeqCiclo = (GJogo.SeqCiclo + 1) mod 360
  wend
  cls
  LimpaTeclado 1
  if (Opcao1 = 1) or (GLMKey = chr(27)) then
    return 0
  else
    return 1
  end if
end function

' Coloca coordenadas em ordem crescente
sub SwapEDXY
  if EDX2 > EDX1 then
    EDXX1 = EDX1
    EDXX2 = EDX2
  else
    EDXX1 = EDX2
    EDXX2 = EDX1
  end if
  if EDY2 > EDY1 then
    EDYY1 = EDY1
    EDYY2 = EDY2
  else
    EDYY1 = EDY2
    EDYY2 = EDY1
  end if
end sub

' Grava situação para possível futuro UNDO
sub GravaUndo
  dim as integer f, g
  for f = -1 to 100
    for g = -1 to 60
      UndoFrente(MatrizAtual, f, g) = Frente (f, g)
      UndoFundo (MatrizAtual, f, g) = Fundo  (f, g)
      UndoObjeto(MatrizAtual, f, g) = GObject(f, g).Typ
    next
  next
  BonecoX(MatrizAtual) = GBoneco.X
  BonecoY(MatrizAtual) = GBoneco.Y
  if MatrizAtual = MaxUndo then
    MatrizAtual = 0
  else
    MatrizAtual += 1
  end if
  MatrizRedoLimite = MatrizAtual
  if MatrizAtual = MatrizUndoLimite then
    if MatrizUndoLimite = MaxUndo then
      MatrizUndoLimite = 0
    else
      MatrizUndoLimite += 1
    end if
  end if
end sub

' Faz um undo no editor
sub FazUndo
  dim as integer f, g
  if MatrizAtual = MatrizRedoLimite then
    for f = -1 to 100
      for g = -1 to 60
        UndoFrente(MatrizAtual, f, g) = Frente (f, g)
        UndoFundo (MatrizAtual, f, g) = Fundo  (f, g)
        UndoObjeto(MatrizAtual, f, g) = GObject(f, g).Typ
      next
    next
    BonecoX(MatrizAtual) = GBoneco.X
    BonecoY(MatrizAtual) = GBoneco.Y
  end if
  if MatrizAtual <> MatrizUndoLimite then
    if MatrizAtual = 0 then
      MatrizAtual = MaxUndo
    else
      MatrizAtual -= 1
    end if
    for f = -1 to 100
      for g = -1 to 60
        Frente (f, g)    = UndoFrente (MatrizAtual, f, g)
        Fundo  (f, g)    = UndoFundo  (MatrizAtual, f, g)
        GObject(f, g).Typ = UndoObjeto (MatrizAtual, f, g)
      next
    next
    GBoneco.X = BonecoX (MatrizAtual)
    GBoneco.Y = BonecoY (MatrizAtual)
  end if
end sub

' Faz um redo no editor
sub FazRedo
  dim as integer f, g
  if MatrizAtual <> MatrizRedoLimite then
    if MatrizAtual = MaxUndo then
      MatrizAtual = 0
    else
      MatrizAtual += 1
    end if
    for f = -1 to 100
      for g = -1 to 60
        Frente (f, g)    = UndoFrente(MatrizAtual, f, g)
        Fundo  (f, g)    = UndoFundo (MatrizAtual, f, g)
        GObject(f, g).Typ = UndoObjeto(MatrizAtual, f, g)
      next
    next
    GBoneco.X = BonecoX(MatrizAtual)
    GBoneco.Y = BonecoY(MatrizAtual)
  end if
end sub

sub LimpaTeclado (IncLMTec as integer = 0)
  dim as integer EsperaMais, f
  if IncLMTec <> 0 then
    if GLMKey = " " then
      GKeyBefore = "]"
      GKey = "]"
    elseif GLMKey = chr(13) then
      GKeyBefore = "["
      GKey = "["
    elseif GLMKey = chr(27) then
      GKeyBefore = "ESC"
      GKey = "ESC"
    end if
  end if
  EsperaMais = 1
  while EsperaMais = 1
    EsperaMais = 0
    for f = 0 to 127
      if multikey(f) then EsperaMais = 1
    next
    sleep 1, 1
  wend
  while inkey <> ""
    sleep 1, 1
  wend
end sub

' Faz a leitura do mouse
sub GetMouseState
  GMXOld = GMX
  GMYOld = GMY
  GMBOld = GMB
  GMWOld = GMW
  getmouse(GMX, GMY, GMW, GMB)
  GMB = GMB and 1
  if GMB = 1 and GMBOld = 0 then GMBDown = 1 else GMBDown = 0
  if GMB = 0 and GMBOld = 1 then GMBUp = 1 else GMBUp = 0
  if (GMXOld <> GMX) or (GMYOld <> GMY) then GMMove = 1 else GMMove = 0
  MouseWDir = sgn(GMW - GMWOld)
end sub

' Faz a mudança de um status para outro, arranjando os parametros necessários
sub MudaStatus(NovoStatus as integer)
  GJogo.StatusAnt = GJogo.Status
  select case NovoStatus
  case NoMenu
    LimpaTeclado
    GDemoTimer = Clock
  case GameOver
    PlaySoundGameOver
    XM =0
  case Instruc
    GJogo.TelaInstr = 0
  case Top10
    LeTopDez
  case Editor
    GJogo.EdStatus = Editando
    EdShow = 2
    EdMOn=0
    EdGrid=0
  case Configs
    '
  case Jogando
    '
  case ModoDemo
    '
  case Testando
    '
  case Pausado
    '
  case ModoMapa
    '
  case VenceuMina
    Opcao1 = 0
  case VenceuJogo
    '
  case SelIdioma
    '
  end select
  GJogo.Status = NovoStatus
end sub

' Pede confirmação se é pra encerrar o teste da mina sendo editada
function EndOfTestConfirmation as integer
  Mensagem 0, 5, GText(95), "", "", 400, 300, Opcao1
  if (GKey <> GKeyBefore) and ((GKey = "R") or (GKey = "U") or (GKey = "D") or (GKey = "L")) then
    Opcao1 = 1 - Opcao1
  end if
  if ((GMMove = 1) or (GMBDown = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
  if ((Opcao1 = 1) and ((GMBDown = 1) or ((GKey <> GKeyBefore) and ((GKey = "[") or (GKey = "]"))))) _
  or ((GKey = "ESC") and (GKeyBefore <> GKey)) then
    MudaStatus Testando
    LoadCustomMine -1, 0
    Iniciado = 0
    IniciaVida
    return 1
  elseif Opcao1 = 0 then
    if (GMBDown = 1) or ((GKey <> GKeyBefore) and (GKey = "[" or GKey = "]")) then
      EncerraTeste
      return 2
    end if
  else
    return 0
  end if
end function
