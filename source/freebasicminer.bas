
' FreeBasic Miner 1.0 - 2011
' Modified by Roland Chastain

#include once "fbgfx.bi"
#include once "file.bi"
#ifdef __FB_WIN32__
#include once "windows.bi"
#include once "win\mmsystem.bi"
#else
#define DWord uinteger
#endif
#if __fb_lang__ = "fb"
using FB
#endif

function Clock() as double
/' https://www.freebasic.net/forum/viewtopic.php?p=276085#p276085 '/
  static as integer init = 0
  static as double startTimer
  if init = 0 then
    init = 1
    startTimer = timer
  end if
  return timer - startTimer
end function

sub LogLn(AText as string, ARewrite as boolean = false)
#ifdef DEBUG
  const as string CFileName = "freebasicminer.log"
  dim as integer LFile = freefile
  if ARewrite then kill CFileName
  open CFileName for append as LFile
  print #LFile, time & " " & AText
  close LFile
#endif
end sub

#define DEBUG_LINE_ID __FILE__ & " " & __FUNCTION__ & "(" & __LINE__ & ") "
#define DEBUG_LOG(_X_) LogLn(DEBUG_LINE_ID & (_X_))
#define DEBUG_LOG_REWRITE(_X_) LogLn(DEBUG_LINE_ID & (_X_), true)

#define RGBA_A(c) (cuint(c) shr 24)
#define RGBA_R(c) (cuint(c) shr 16 and 255)
#define RGBA_G(c) (cuint(c) shr 8 and 255)
#define RGBA_B(c) (cuint(c) and 255)
#define Magenta &HFFFF00FF
#define LargArqFonte 838
#define MaxUndo 49
#define DefaultLanguage "Portuguese"

const C255 = chr (255)

enum  'opções do menu
  Jogar
  IrPara
  VerTop
  Sobre
  Volume
  EscIdioma
  Custom_
  Editar
  Sair
end enum

enum  'status do programa
  NoMenu
  Configs
  Jogando
  ModoDemo
  Testando
  Pausado
  GameOver
  ModoMapa
  Instruc
  VenceuMina
  VenceuJogo
  Top10
  SelIdioma
  Editor
end enum

enum  'Posição do mouse no editor
  EdForaTela
  EdTela
  EdInicio
  EdEsquerda
  EdDireita
  EdFim
  EdBarra
  EdItem
  EdNovo
  EdAbre
  EdMove
  EdSalva
  EdVisao
  EdMudaGrid
  EdApaga
  EdTesta
  EdUndo
  EdRedo
  EdEXIT
end enum

enum  'Status do editor
  Editando
  Selecionando
  RespNovo
  RespAbrindo
  EdMovendo
  RespSalvar
  Apagando0
  Apagando1
  RespTesta
  RespExit
end enum

'Som
type TSons
  COn1  as DWord
  COn2  as DWord
  COff  as DWord
  Tempo as ubyte
end type

'Jogo
type TJogo
  Status       as integer  'Status do programa
  Status0      as integer  'Status no início do ciclo, para comparar abaixo
  StatusAnt    as integer  'Idem acima
  EdStatus     as integer  'Status do editor de minas
  UltExplosao  as integer  'Ponto para incluir nova explosão
  Passos       as integer  'Número de ciclos para concluir um movimento
  TamanhoPasso as integer  'Espaço percorrido em cada passo
  Ciclo        as integer  'Ciclo atual (0 a passos-1)
  DelayMSec    as integer  'Milisegundos por quardo
  UltTimer     as long     'Marcador de tempo para ajustar FPS
  Encerra      as integer  'Sai do jogo (0=não)
  SeqCiclo     as integer  'Sequencia de ciclos (0-999)
  Player       as integer  '0=Jogador 1;   1=Jogador 2
  TelaInstr    as integer  'Número da tela de instruções
  NumMinas     as integer  'Número de minas disponíveis
  NumVidas     as integer  'Número de vidas ao iniciar partida
  Volume       as ubyte    'Volume dos efeitos sonoros
  MaxAlcancada as uinteger 'Número mais alto de mina alcançado até o momento
end type

'Boneco
type TBoneco
  Mina           as integer  'Número da mina (caverna)
  Vidas          as integer  'Número de vidas
  Pontos         as long     'Pontuação atual
  Morreu         as integer  '0=vivo 1~=passos
  UltDir         as integer  'Ao parar, para onde fica de frente
  DirAtual       as integer  'Para onde está indo (0=parado 1=direita 2=esquerda 3=subindo 4=descendo 5=caindo)
  Empurrando     as integer  'Se está empurrando objetos
  Passo          as integer  'Passo do movimento (0=parado; 1 a jogo.passos)
  Img            as integer  'Número da imagem
  ImgX           as integer  'X da posição absoluta na tela
  ImgY           as integer  'Y da posição absoluta na tela
  X              as integer  'Posição X (quadro)
  Y              as integer  'Posição Y (quadro)
  Oxigenio       as integer  'Oxigenio atual (diminui se estiver na água)
  NoOxigenio     as integer  '0=Não 1=Usando garrafa de oxigênio
  ItSuporte      as integer  'Quantos suportes possui
  ItOxigenio     as integer  'Quantas garrafas de oxigênio possui
  ItPicareta     as integer  'Quantas picaretas possui
  ItFuradeira    as integer  'Quantas furadeiras possui
  ItBombinha     as integer  'Quantas bombas pequenas possui
  ItBombona      as integer  'Quantas bombas grandes possui
  NaPicareta     as integer  'Se está usando a picareta (0=não 1~=passo)
  NaFuradeira    as integer  'Se está usando a furadeira (id. acima)
  DirFuradeira   as integer  'Para que lado está furando (1=direita 2=esquerda)
  VirouFuradeira as integer  '0=Não virou, ainda pode virar; 1=já virou, não pode mais
  Tempo          as long     'Marca o tempo (em segundos)
  Nome           as string   'Nome do jogador
end type

'Mina
type TMina
  Numero   as integer
  Tipo     as ubyte    '0=Normal  1=Personalizada
  Larg     as ubyte    'Largura (Tela=25)
  ALT      as ubyte    'Altura (Tela=17)
  Tesouros as integer  'Quantidade de tesouros a recolher para completar a mina
  X        as integer  'Posição X inicial do boneco
  Y        as integer  'Posição Y inicial do boneco
  Noturno  as ubyte    'Se a mina é noturna ou não
  Tempo    as uinteger 'Tempo para concluir a mina
  Alterada as integer  'Se foi feita alteraçao depois de ler ou de gravar pela ultima vez
end type

'Explosões
type TExplosao
  X         as integer   'X do quadro da explosão
  Y         as integer   'Y do quadro da explosão
  Tipo      as integer   '0=não está em uso; 1=pequena (3 quadros); 2=grande (9 quadros)
  Tempo     as integer   '0=não está em uso; 1~=passos
end type

'Editor
type EdTipo
  Tp      as integer  '0=fundo 1=obj 2=frente
  Cod     as integer  'Código do fundo, objeto ou frente
end type

'Comportamentos dos diferentes objetos (12 diferentes)
type TComportamento
  Vazio     as byte     '0=não vazio; 1=vazio (vão livre para andar e empurrar)
  Sobe      as byte     '0=não sobe; 1=sobe
  Apoia     as byte     '0=não apóia; 1=apoia
  Anda      as byte     '0=Não anda; 1=Anda e some ou pega; 2=Anda e permanece
  Mata      as byte     '0=não mata; 1=mata
  PEmpurra  as integer  '0=empurra inúmeros; 1=empurra 2; 2=empurra 1; 3=não empurra
  Cai       as byte     '0=não cai; 1=cai
  Destroi   as byte     '0=não destrói 1=só com explosão 2=explosão, furadeira ou picareta
  Som       as byte     '0=Vazio 1=Terra 2=Tijolo/Escada/Pedra 3=Diamante/Carrinho/Item 4=Caixa/Feno (5=boneco)
end type

'Objetos (81 diferentes)
type TiposObj
  Tipo as integer    'Índice do tipo de comportamento
  Img  as integer    'Número da imagem
  Item as integer    'Numero do item
end type

'Mensagens na tela
type TMsgPT
  Ciclo  as integer '0=Acabou
  Pontos as integer
  X as integer
  Y as integer
end type

'Tiles
type TObj
  Tp         as ubyte    'Indicador do tipo de objeto
  Caindo     as byte     '0=não; 1=sim
  AntCaindo  as byte     'Se já estava caindo anteriormente
  Empurrando as byte     '0=não; 1=direita; 2=esquerda
  Passo      as integer  'Número do passo no movimento
end type

'Top Score
type Recorde
  Nome   as string    'Nome
  Pontos as uinteger  'Pontuação
end type

declare sub EscreveNumero (byval Numero as long, Comprimento as integer, X1 as integer, Y1 as integer, PReenche as integer)
declare sub Escreve (byval Texto as string, x1 as integer, y1 as integer, Bold as integer = 0, BoldV as integer = 0)
declare sub EscreveCentro (byval Texto as string, x1 as integer, Bold as integer = 0, BoldV as integer = 0)
declare sub EscrevePT (Pontos as  integer, X as integer, Y as integer, CJCarac as integer)
declare function LargTexto (byval Texto as string, Bold as integer = 0) as integer
declare sub IniciaJogo
declare sub IniciaVida
declare sub LeMinaIn (NMina as integer, SoQuant as integer = 0)
declare sub LeMinaOUT (NMina as integer, Editando as integer = 0)
declare sub LeMinaDet (Editando as integer = 0)
declare sub LeMinasPers
declare sub Desenha
declare sub Joga
declare sub PegaObj (POX as integer, POY as integer)
declare function EmpurraObj (byval POX as integer, byval POY as integer, byval MDir as integer, byval Peso as integer, byval Quant as integer) as integer
declare sub Explode (byval EXX as integer, byval EXY as integer, byval XTam as integer)
declare sub LimpaMina
declare function VerificaRecorde as integer
declare sub LeTopDez
declare sub TrocaTelas
declare sub MontaTopDez
declare sub LimpaTopDez
declare sub Mensagem (QCor as integer, Tipo as integer, T1 as string, T2 as string, T3 as string, OX as integer = 400, OY as integer= 300, Opcao as integer = 0)
declare sub DesBox (H as integer, V as integer, QCor as integer, OX as integer = 400, OY as integer = 300)
declare sub PutLogo (LX as integer, LY as integer)
declare sub SorteiaNotaGameOver
declare sub SorteiaNotaVenceu
declare sub MarcaPt (Pontos as integer, X as integer, Y as integer)
declare function CTRX as integer
declare function CTRY as integer
declare function ProximaTeclaDemo () as string
declare sub LoadBar (perc as integer)
declare sub RegravaConfig
declare function LeTXT (Idioma as string) as integer
declare sub ProcIdiomas ()
declare sub DesFundo
declare sub VeSeGanhaVida (Acrescimo as integer)
declare sub CalculaBonusTempo
declare sub LeMouse
declare sub MudaStatus (NovoStatus as integer)
declare sub DesligaSons
declare sub LimpaTeclado (IncLMTec as integer = 0)

'Editor:
declare sub Edita
declare sub EscreveNumeroPeq (byval Numero as integer, X1 as integer, Y1 as integer)
declare sub SalvaMina (ParaTestar as integer = 0)
declare sub Dlinha (x1 as integer, y1 as integer, x2 as integer, y2 as integer, QualCor as integer)
declare sub CopiaMMinEd
declare sub CopiaMEdMin
declare sub EncerraTeste
declare sub DesenhaItem (ITX as integer, ITY as integer, ITN as integer)
declare function MaiorColuna as integer
declare function MaiorLinha as integer
declare function ContaTesouros as integer
declare function PosMouseEd () as integer
declare sub FazRedo
declare sub FazUndo
declare sub LimpaMinaEditor
declare function PergFecha () as integer
declare sub SwapEDXY
declare sub GravaUndo
declare function PerguntaSeEncerraTeste() as integer


'Variáveis compartilhadas
'--------------------------------------------------

'Armazenamento das Imagens
dim shared Carregou as integer
dim shared as any ptr Grafx, GrafX2, BMP (281)

'Mensagens de pontos na tela
dim shared as TMsgPT MSG (20)

'Recordes
dim shared TopPt (10) as Recorde
dim shared as integer ConfirmDel

'Sons
#ifdef __FB_WIN32__
dim shared hMidiOut as HMIDIOUT
#else
#endif
dim shared as TSons Som (1 to 6, 1 to 4), SomEx (1 to 7)
dim shared as ubyte Toca (1 to 6, 1 to 4), QtdNotasVenceu
dim shared as DWord UltNotaGameOver, resposta
dim shared as double TimerNotaVenceu

'Menu
dim shared as integer OpMenu, XM, YM, Mina1, Mina2, PosTop10, Opcao1

'Genéricas
dim shared as integer Iniciado, MapX, MapY, ProxMsg, LenMSG, EncerraEditor
dim shared as string Tecla, UltTecla
dim shared as uinteger CorRGB, CorRGB2

'Fonte
dim shared as string Lt_, XTemp
dim shared as integer PosLetra (100, 1)

'Screen
dim shared ScrAtiva as integer

'Idiomas
dim shared as string Idioma (15), IAtual
dim shared as integer IQuant, NAtual

'Timer
dim shared as uinteger ATimer, NTimer
dim shared NumFPS(5) as integer
dim shared NomFPS(5) as string
dim shared as double TIMESTART

'Jogo
dim shared Jogo as TJogo
dim shared Boneco as TBoneco
dim shared as TMina Mina
dim shared PontoTesouro (7 to 22) as integer
dim shared as integer TmpSleep, PtBonus, Quadros, ultQuadros
dim shared as double timer1, Timer2

'Explosões
dim shared Explosao (10) as TExplosao

'Comportamentos de objetos
dim shared Comport (13) as TComportamento

'Tipos de objetos
dim shared TpObjeto (84) as TiposObj

'Tiles: fundo - layer 0 (0 = água)
dim shared as ubyte Fundo (-1 to 100, -1 to 60)

'Tiles: objetos - layer 1
dim shared as TObj Objeto (-1 to 100, -1 to 60)

'Tiles: frente - layer 2
dim shared as ubyte Frente (-1 to 100, -1 to 60)

'Imagens do boneco
dim shared Parado (5) as integer
dim shared Movendo (7,3) as integer
dim shared Usando (2,1) as integer

'Tela inicial
dim shared as integer CRed, CGreen, CBlue, VRed, VGreen, VBlue, CRed2, CGreen2, CBlue2

'Modo Demonstração
dim shared as string TeclasDemo
dim shared as integer PositDemo, DemoW1, DemoW2, DemoCiclo, MensDemo, TempMens
dim shared as double TTDemo1, TTDemo2

'Minas personalizadas
dim shared as integer MinaPers (999), SelPers (999), QuantPers, PersTemp

'Textos (todos)
dim shared as string TXT (159)

'Mouse:
dim shared as integer MouseX, MouseY, MouseB, MouseXAnt, MouseYAnt, MouseBAnt, MouseDisparou, MouseLiberou, MouseSimNao, MouseMoveu, MouseSobre, MouseW, MouseWAnt, MouseWDir

'Editor:
dim shared as TMina MinaEd
dim shared as string LMTec, UMTec

dim shared as integer EdX1, EdX2, EdY1, EdY2, EdMOn, EdShow, PrimeiroItem, ItemSel
dim shared as integer EDXX1, EDXX2, EDYY1, EDYY2, EdGrid, PosMouse

'Undo:
dim shared as integer MatrizAtual, MatrizRedoLimite, MatrizUndoLimite, EdMovendoUndo, BonecoX (MaxUndo), BonecoY (MaxUndo)
dim shared as ubyte UndoFundo (MaxUndo, -1 to 100, -1 to 60), UndoFrente (MaxUndo, -1 to 100, -1 to 60), UndoObjeto (MaxUndo, -1 to 100, -1 to 60)


'--------------------------------------------------

'Fonte
Lt_ = "ABCDEFGHIJKLMNOPQRSTUVWXYZÇÁÉÍÓÚÂÊÔÃÕÀabcdefghijklmnopqrstuvwxyzçáéíóúâêôãõà.,:?!0123456789-+'/()=_>|"
'*FT* Lt = " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZÇÁÉÍÓÚÂÊÔÃÕÀabcdefghijklmnopqrstuvwxyzçáéíóúâêôãõà-_=+(*)&%$#@!?,.<>;:|"

'Vairáveis locais
dim as integer F, G, H, I

'Inicializa a tela
windowtitle "FreeBasic Miner"
screen 19, 32, 2  '800x600, Cores de 32 bits, 2 páginas
CRed = 0
randomize
VRed = int(rnd*2)
VGreen = int(rnd*2)
VBlue = int(rnd*2)
DesFundo
CRed = 0

draw string (25,500), "Carregando FreeBasic Miner..."
line (20,520) - (779,554), rgb(200,200,200), bf
line (21,519) - (778,555), rgb(200,200,200), b
line (23,523) - (776,551), rgb(16,16,48),bf

LoadBar 5
Idioma (0) = DefaultLanguage
DEBUG_LOG_REWRITE("Application start")

sleep 2, 1

'Definição das imagens do boneco
'--------------------------------------------------

'Parado (depende do último movimento)
Parado (0) = 116
Parado (1) = 119
Parado (2) = 122
Parado (3) = 117
Parado (4) = 117
Parado (5) = 116

'Andando p/ direita
Movendo (0, 0) = 119
Movendo (0, 1) = 118
Movendo (0, 2) = 120
Movendo (0, 3) = 118

'Andando p/ esquerda
Movendo (1, 0) = 122
Movendo (1, 1) = 121
Movendo (1, 2) = 123
Movendo (1, 3) = 121

'Subindo
Movendo (2, 0) = 124
Movendo (2, 1) = 117
Movendo (2, 2) = 125
Movendo (2, 3) = 117

'Descendo
Movendo (3, 0) = 124
Movendo (3, 1) = 117
Movendo (3, 2) = 125
Movendo (3, 3) = 117

'Caindo
Movendo (4, 0) = 126
Movendo (4, 1) = 126
Movendo (4, 2) = 126
Movendo (4, 3) = 126

'Empurrando p/ direita
Movendo (5, 0) = 128
Movendo (5, 1) = 127
Movendo (5, 2) = 129
Movendo (5, 3) = 127

'Empurrando para esquerda
Movendo (6, 0) = 131
Movendo (6, 1) = 130
Movendo (6, 2) = 132
Movendo (6, 3) = 130

'Morrendo
Movendo (7, 0) = 116
Movendo (7, 1) = 119
Movendo (7, 2) = 117
Movendo (7, 3) = 122

'Usando a picareta
Usando (0, 0) = 133
Usando (0, 1) = 134

'Usando a furadeira p/ direita
Usando (1, 0) = 135
Usando (1, 1) = 136

'Usando a furadeira p/ esquerda
Usando (2, 0) = 137
Usando (2, 1) = 138

LoadBar 10
sleep 2, 1

'Definição dos comportamentos
'--------------------------------------------------

'Vazio (inclui água)
with Comport (0)
  .Vazio = 1
  .Sobe = 0
  .Apoia = 0
  .Anda = 2
  .Mata = 0
  .PEmpurra = 3 'Não pode ser empurrado
  .Cai = 0
  .Destroi = 0
  .Som = 1
end with

'Terra (pode ser eliminada)
with Comport (1)
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

'Parede destrutível
with Comport (2)
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

'Parede indestrutível
with Comport (3)
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

'Escada
with Comport (4)
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

'Diamante
with Comport (5)
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

'Pedra
with Comport (6)
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

'Carrinho
with Comport (7)
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

'Caixa
with Comport (8)
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

'Feno
with Comport (9)
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

'Item
with Comport (10)
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

'Bomba acionada
with Comport (11)
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

'Suporte em uso
with Comport (12)
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

'Espetos
with Comport (13)
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

LoadBar 15
sleep 2, 1


'Definição dos tipos de objetos:
'--------------------------------------------------

'Vazio (0):
with TpObjeto (0)
  .Tipo = 0
  .Img  = 0
  .Item = 0
end with

'Terras (1-14):
for f = 0 to 13
  with TpObjeto (f + 1)
    .Tipo = 1
    .Img  = f + 36
    .Item = 0
  end with
next

'Paredes destrutíveis (15-25):
for f = 0 to 10
  with TpObjeto (f + 15)
    .Tipo = 2
    .Img  = f + 50
    .Item = 0
  end with
next

'Paredes indestrutíveis (26-37):
for f = 0 to 11
  with TpObjeto (f + 26)
    .Tipo = 3
    .Img  = f + 61
    .Item = 0
  end with
next

'Escadas (38-39):
for f = 0 to 1
  with TpObjeto (f + 38)
    .Tipo = 4
    .Img  = f + 73
    .Item = 0
  end with
next

'Diamantes (40-55):
for f = 0 to 15
  with TpObjeto (f + 40)
    .Tipo = 5
    .Img  = f + 75
    .Item = f + 7
  end with
next

'Pedras (56-63):
for f = 0 to 7
  with TpObjeto (f + 56)
    .Tipo = 6
    .Img  = f + 91
    .Item = 0
  end with
next

'Carrinhos (64-66):
for f = 0 to 2
  with TpObjeto (f + 64)
    .Tipo = 7
    .Img  = f + 99
    .Item = 0
  end with
next

'Caixas (67-68):
for f = 0 to 1
  with TpObjeto (f + 67)
    .Tipo = 8
    .Img  = f + 102
    .Item = 0
  end with
next

'Feno (69-70):
for f = 0 to 1
  with TpObjeto (f + 69)
    .Tipo = 9
    .Img  = f + 104
    .Item = 0
  end with
next

'Itens para pegar (71-76):
for f = 0 to 5
  with TpObjeto (f + 71)
    .Tipo = 10
    .Img  = f + 106
    .Item = f + 1
    end with
next

'Bombas em Uso (77-78: Pequena; 79-80: Grande):
for f = 0 to 3
  with TpObjeto (f + 77)
    .Tipo = 11
    .Img  = f + 112
    .Item = 0
  end with
next

'Suporte em Uso (81):
with TpObjeto (81)
  .Tipo = 12
  .Img  = 236
  .Item = 0
end with

'Espetos (82-84)
for f = 0 to 2
  with TpObjeto(f + 82)
    .tipo = 13
    .img  = 233 + f
    .item = 0
  end with
next

LoadBar 20
sleep 2, 1

'Pontos por tesouro
PontoTesouro (7)  = 1
PontoTesouro (8)  = 2
PontoTesouro (9)  = 3
PontoTesouro (10) = 4
PontoTesouro (11) = 5
PontoTesouro (12) = 6
PontoTesouro (13) = 7
PontoTesouro (14) = 8
PontoTesouro (15) = 9
PontoTesouro (16) = 10
PontoTesouro (17) = 12
PontoTesouro (18) = 15
PontoTesouro (19) = 17
PontoTesouro (20) = 20
PontoTesouro (21) = 25
PontoTesouro (22) = 30

'Inicializa MIDI
#ifdef __FB_WIN32__
if midiOutOpen( @hMidiOut, MIDI_MAPPER, 0, 0, CALLBACK_NULL) then
  cls
  draw string (10, 20), TXT (1)
  draw string (10, 50), TXT (50)
  LimpaTeclado
  if hMidiOut <> 0 then midiOutClose hMidiOut
  end
end if
#else
#endif

LoadBar 25
sleep 2, 1
'Prepara imagens
Grafx = imagecreate (800, 440, 0, 32)
sleep 10, 1
BMP (275) = imagecreate (448, 444, rgba (0, 0, 0, 255), 32)
for f = 0 to 79
  circle BMP (275), (222, 222), 144 - f, rgba (0, 0, 0, 255 - f * 3.17), , , , f
next
circle BMP (275), (222, 222), 64, rgba (0, 0, 0, 0), , , , f
Carregou = bload ("res/sprites.bmp", Grafx)
LoadBar 27

'Posições das figuras no arquivo de imagem
'0-184 = fundos, frentes, objetos, bonecos...
for f = 0 to 184
  BMP (f) = imagecreate (32, 32, 0, 32)
  put BMP (f), (0,0), GrafX, ((f mod 25) * 32, int (f/25) * 32) - step (31, 31), pset
next

LoadBar 30

'185-196 = Explosoes
for f = 0 to 11
  BMP (185 + f) = imagecreate (32, 32, 0, 32)

  'transparência gradativa
  for G = 0 to 31
    for H = 0 to 31
      CorRGB = point (320 + F * 32 + G, 224 + H, GrafX)
      if CorRGB = Magenta then
        pset BMP(185 + F), (G, H), rgba (255, 0, 255, 0)
      else
        pset BMP(185 + F), (G, H), rgba (rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 255 - f * 21)
      end if
    next
  next
next

LoadBar 33

'197 - 208 = Algarismos (fundo opaco)
for f = 0 to 11
  BMP (197 + f) = imagecreate (10, 15, 0, 32)
  put BMP (197 + f), (0,0), GrafX, (f * 10 + 672, 256) - step (9, 14), pset
next

LoadBar 35

'209 = Medidor do oxigênio
BMP (209) = imagecreate (100, 16, 0, 32)
put BMP (209), (0,0), GrafX, (672, 272) - (771, 287), pset

'210 = Barra de informações - (210)
BMP (210) = imagecreate (800, 56, 0, 32)
put BMP (210), (0,0), GrafX, (0, 352) - (799, 407), pset

'211 = Logo do Jogo (211)
BMP (211) = imagecreate (220, 96, 0, 32)
put BMP (211), (0,0), GrafX, (0, 256) - (219, 351), pset

'212 = Game over (212)
BMP (212) = imagecreate (128, 64, 0, 32)
put BMP (212), (0,0), GrafX, (672, 288) - (799, 351), pset

'213 - 237 = Agua (213 a 237); espetos (233-235); suporte em uso (236); fundo para água (237)
for f = 0 to 24
  BMP (213 + f) = imagecreate (32, 32, 0, 32)
  put BMP (213 + f), (0,0), GrafX, (F * 32, 408) - step (31, 31), pset
next

'238 = Setinhas: vermelha, laranja, amarela, verde e azul
BMP (238) = imagecreate (58, 15, 0, 32)
put BMP (238), (0, 0), Grafx, (7, 385) - (64, 399), pset

LoadBar 40

'239 - 246 = Números (esmaecendo)
for F = 0 to 7
  BMP (239 + f) = imagecreate (90, 15, 0, 32)
  for H = 0 to 89
    for I = 0 to 14
      CorRGB = (point (288 + H, 320 + I, GrafX) and 255) * (1 - F * .1)
      pset BMP (239 + f), (H, I), rgba (255, 255, 0, CorRGB)
    next
  next
next

LoadBar 45

'247 = Fonte (LETRAS)

Grafx2 = imagecreate(LargArqFonte, 23, 0, 32)
BMP (247)= imagecreate(LargArqFonte, 22, 0, 32)
Carregou = bload ("res/fonte.bmp", Grafx2)

h=0
PosLetra (0,0) = 0
for g = 0 to LargArqFonte - 1
  for f = 0 to 21
    CorRGB = point (g, f, grafx2) and 255
    pset BMP (247), (g, f), rgba (255, 255, 255, CorRGB)
  next
  if (point(g, 22, Grafx2) and 1) = 0 then
    PosLetra (h, 1)= G
    h += 1
    if g < LargArqFonte - 1 then PosLetra (h, 0) = g + 1
  end if
next

LoadBar 50

'248 - 251 = Quadros para mensagem
for h = 0 to 3
  BMP (248 + h) = imagecreate (64, 64, 0, 32)
  for F = 0 to 63
    for G = 0 to 63
      CorRGB = point (288 + h * 64 + F, 256 + G, GrafX)
      if CorRGB = Magenta then
        pset BMP (248 + h), (F, G), rgba (255, 0, 255, 0)
      else
        pset BMP (248 + h), (F, G), rgba (rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 192)
      end if
    next
  next
next

LoadBar 55

'252 = FreeBasic's HORSE
BMP (252) = imagecreate (59, 47, 0, 32)
put BMP(252), (0, 0), grafx, (225,256) - (283,302), pset

'Objetos de frente
for H = 25 to 36
  for G = 0 to 31
    for F = 0 to 31
      CorRGB = point (F, G, BMP (H))
      if CorRGB = Magenta then
        pset BMP (H), (F, G), rgba (255, 0, 255, 0)
      else
        if H < 32 then
          pset BMP (H), (F, G), rgba (rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 191)
        else
          pset BMP (H), (F, G), rgba (rgba_R(CorRGB), rgba_G(CorRGB), rgba_B(CorRGB), 127)
        end if
      end if
    next
  next
next

LoadBar 60

for h = 0 to 5
  BMP (253 + h) = imagecreate (42, 48, 0, 32)
  put BMP(253 + H), (0, 0), GrafX, (544 + (h mod 3) * 42, 256 + (int (h/3) * 48)) - step (41, 47), pset
next

for F= 259 to 273
  BMP (F) = imagecreate (32, 32, 0, 32)
next

LoadBar 65

for f = 0 to 4
  put BMP (264 + F), (0, 0), GrafX, (378 + F * 32, 320) - step (31, 31), pset
  for g = 0 to 31
    put BMP (269 + f), (g, 0), GrafX, (409 + F * 32 - G, 320) - step (0, 31), pset
    for h = 0 to 31
      pset BMP (259 + F), (31 - H, G), point (378 + F * 32 + G, 320 + H, GrafX)
    next
  next
next

LoadBar 70

'Números pequenos para o editor
BMP (274) = imagecreate (60, 8, 0, 32)
put BMP (274), (0, 0), GrafX, (288, 335) - (347, 342), pset

imagedestroy GrafX

LoadBar 75

'Imagens do Menu
BMP (276) = imagecreate (630, 128, 0, 32)
GrafX = imagecreate (723, 128, 0, 32)
Carregou = bload ("res/menu.bmp", GrafX)
put BMP (276), (0,0), GrafX, (0, 0) - (629, 127), pset
BMP (277) = imagecreate (96, 96, 0, 32)

'Imagens do menu do editor
BMP (278) = imagecreate (73, 19, rgba(255, 0, 255, 0), 32)
for f = 0 to 3
  line bmp (278), (3 - f, f) - (69 +  f, 18 - f), rgba (0, 0, 0, 255), b
next

LoadBar 80

line bmp (278), (4, 4) - (68, 14), rgba (0, 0, 0, 64), Bf
BMP (279) = imagecreate (611, 21, rgba (255, 0, 255, 0), 32)
line bmp (279), (0,0) - (22, 20), rgb (128, 128, 128), b
line bmp (279), (23,0) - (45, 20), rgb (128, 128, 128), b
line bmp (279), (46,0) - (564, 20), rgb (128, 128, 128), b
line bmp (279), (565,0) - (587, 20), rgb (128, 128, 128), b
line bmp (279), (588,0) - (610, 20), rgb (128, 128, 128), b
put bmp (279), (3, 2), GrafX, (688, 66) - (703, 82), pset
put bmp (279), (30, 2), GrafX, (695, 66) - (703, 82), pset
put bmp (279), (572, 2), GrafX, (677, 66) - (685, 82), pset
put bmp (279), (592, 2), GrafX, (677, 66) - (692, 82), pset
line bmp (279), (48, 4) - (562, 17), rgba (255, 255, 255, 255), B
line bmp (279), (48, 4) - (561, 16), rgba (128, 128, 128, 255), B
line bmp (279), (49, 5) - (52, 16), rgba (255, 255, 0, 255), BF
line bmp (279), (53, 5) - (152, 16), rgba (80, 160, 160, 255), BF
line bmp (279), (153, 5) - (208, 16), rgba (185, 106, 106, 255), BF
line bmp (279), (209, 5) - (561, 16), rgba (100, 180, 100, 255), BF

LoadBar 85

BMP (280) = imagecreate (187, 56, rgba (255, 0, 255, 0), 32)
for F = 0 to 1
  for g = 0 to 1
    line bmp (280), (g * 27, F * 28) - step (26, 27), rgba (96, 96, 96, 255), B
    put bmp (280), (2 + g * 27, 3 + F * 28), GrafX, (631 + G * 23, f * 23)- step (22, 22), pset
  next
  for g = 0 to 2
    line bmp (280), (106 + g * 27, F * 28) - step (26, 27), rgba (96, 96, 96, 255), B
    put bmp (280), (108 + g * 27, 3 + F * 28), GrafX, (631 + F * 23, 46 + G * 23)- step (22, 22), pset
  next
next
line bmp (280), (54, 0) - step (51, 55), rgba (0, 0, 0, 255), B
line bmp (280), (55, 0) - step (49, 55), rgba (128, 128, 128, 255), B
'Line bmp (280), (56, 1) - step (47, 53), rgba (160, 160, 160, 255), BF
put bmp (280), (57, 3), Grafx, (677, 0) - (722, 49), pset
BMP (281) = imagecreate (46, 16, rgba (192, 192, 192, 255), 32)
put bmp (281), (0, 0), grafX, (677, 50) - (722, 65), pset

imagedestroy GrafX
LoadBar 90

'Hilight do menu
sleep 10, 1
for F=0 to 15
  circle BMP (277), (f + 15, f + 15), 15, rgba(64, 255, 64, f * 16), , , , f
  circle BMP (277), (f + 15, 80 - f), 15, rgba(64, 255, 64, f * 16), , , , f
  circle BMP (277), (80 - f, f + 15), 15, rgba(64, 255, 64, f * 16), , , , f
  circle BMP (277), (80 - f, 80 - f), 15, rgba(64, 255, 64, f * 16), , , , f
  line BMP (277), (16 + f, f) - (79 - f, 95 - f), rgba(64, 255, 64, f * 16), bf
  line BMP (277), (f , 16 + f) - (95 - f, 79 - f), rgba(64, 255, 64, f * 16), bf
next

LoadBar 95

'Sons: feno caindo:
Som (1, 1).COn1 = &H76c0 : Som (1, 1).COn2 = &H6f3490: Som (1, 1).COff = &H6f3480 'Ok Sobre terra, feno, tijolo ou escada
Som (1, 2).COn1 = &H76c0 : Som (1, 2).COn2 = &H6f2d90: Som (1, 2).COff = &H6f2d80 'Ok Sobre parede indestr., pedra, tesouro, suporte, espeto
Som (1, 3).COn1 = &H76c0 : Som (1, 3).COn2 = &H6f3b90: Som (1, 3).COff = &H6f3b80 'Ok Sobre carro, item, bomba
Som (1, 4).COn1 = &H75c0 : Som (1, 4).COn2 = &H6f3f90: Som (1, 4).COff = &H6f3f80 'Ok Sobre caixa

'Sons: pedra, tesouro ou suporte caindo:
Som (2, 1).COn1 = &H7fc1 : Som (2, 1).COn2 = &H774391: Som (2, 1).COff = &H774381 'Ok Sobre terra, feno, tijolo ou escada
Som (2, 2).COn1 = &H7fc1 : Som (2, 2).COn2 = &H774491: Som (2, 2).COff = &H774481 'Ok Sobre parede indestr., pedra, tesouro, suporte, espeto
Som (2, 3).COn1 = &H7fc1 : Som (2, 3).COn2 = &H774591: Som (2, 3).COff = &H774581 'Ok Sobre carro, item, bomba
Som (2, 4).COn1 = &H7fc1 : Som (2, 4).COn2 = &H774691: Som (2, 4).COff = &H774681 'Ok Sobre caixa

'Sons: carro, item ou bomba caindo:
Som (3, 1).COn1 = &H2fc2 : Som (3, 1).COn2 = &H7f4c92: Som (3, 1).COff = &H7f4c82 'Ok Sobre terra, feno, tijolo ou escada
Som (3, 1).COn1 = &H2fc2 : Som (3, 2).COn2 = &H7f4892: Som (3, 2).COff = &H7f4882 'Ok Sobre parede indestr., pedra, tesouro, suporte, espeto
Som (3, 1).COn1 = &H2fc2 : Som (3, 3).COn2 = &H7f4392: Som (3, 3).COff = &H7f4382 'Ok Sobre carro, item, bomba
Som (3, 1).COn1 = &H2fc2 : Som (3, 4).COn2 = &H7f3c92: Som (3, 4).COff = &H7f3c82 'Ok Sobre caixa

'Sons: caixa caindo:
Som (4, 1).COn1 = &H73c3 : Som (4, 1).COn2 = &H7f3c93: Som (4, 1).COff = &H7f3c83 'Ok Sobre terra, feno, tijolo ou escada
Som (4, 2).COn1 = &H73c3 : Som (4, 2).COn2 = &H7f4393: Som (4, 2).COff = &H7f4383 'Ok Sobre parede indestr., pedra, tesouro, suporte, espet
Som (4, 3).COn1 = &H73c3 : Som (4, 3).COn2 = &H7f4093: Som (4, 3).COff = &H7f4083 'Ok Sobre carro, item, bomba
Som (4, 4).COn1 = &H73c3 : Som (4, 4).COn2 = &H7f3893: Som (4, 4).COff = &H7f3883 'Ok Sobre caixa

'Sons: furadeira
Som (5, 1).COn1 = &H7cc4 : Som (5, 1).COn2 = &H7f5994: Som (5, 1).COff = &H7f5984 'Ok Furando feno ou tijolo
Som (5, 2).COn1 = &H7cc4 : Som (5, 2).COn2 = &H7f5a94: Som (5, 2).COff = &H7f5a84 'Ok Furando pedra ou tesouro
Som (5, 3).COn1 = &H7cc4 : Som (5, 3).COn2 = &H7f5b94: Som (5, 3).COff = &H7f5b84 'Ok Furando carro ou item
Som (5, 4).COn1 = &H7cc4 : Som (5, 4).COn2 = &H7f5c94: Som (5, 4).COff = &H7f5c84 'Ok Furando caixa

'Sons: picareta5
Som (6, 1).COn1 = &H7fc5 : Som (6, 1).COn2 = &H7f5795: Som (6, 1).COff = &H7f5785 'Furando feno ou tijolo
Som (6, 2).COn1 = &H7fc5 : Som (6, 2).COn2 = &H7f5695: Som (6, 2).COff = &H7f5685 'Furando pedra ou tesouro
Som (6, 3).COn1 = &H7fc5 : Som (6, 3).COn2 = &H7f5595: Som (6, 3).COff = &H7f5585 'Furando carro ou item
Som (6, 4).COn1 = &H7fc5 : Som (6, 4).COn2 = &H7f5495: Som (6, 4).COff = &H7f5485 'Furando caixa

'Sons: Explosões
SomEx (1).COn1 = &H7fc6 : SomEx (1).COn2 = &H7f3296: SomEx (1).COff = &H7f3286  'Ok Explosao bomba pequena
SomEx (2).COn1 = &H7fc6 : SomEx (2).COn2 = &H7f2f96: SomEx (2).COff = &H7f2f86  'Ok Explosao bomba grande
SomEx (3).COn1 = &H7fc6 : SomEx (3).COn2 = &H7f2396: SomEx (3).COff = &H7f2386  'Ok Explosao boneco
SomEx (4).COn1 = &H72c6 : SomEx (4).COn2 = &H6f4096: SomEx (4).COff = &H6f4086  'Ok pega item
SomEx (5).COn1 = &H72c6 : SomEx (5).COn2 = &H5f4896: SomEx (5).COff = &H5f4886  'Ok Pega tesouro
SomEx (6).COn1 = &H15c6 : SomEx (6).COn2 = &H6f2996: SomEx (6).COff = &H6f2986  'Ok Dame
SomEx (7).COn1 = &H7ec6 : SomEx (7).COn2 = &H6f4196: SomEx (7).COff = &H6f4186  'Ok Empurrando

'---------------------------------------------------
LeMinaIn 0, 1

LoadBar 100
sleep 2, 1

Jogo.NumVidas = 2
if fileexists("config.min") then
  open "config.min" for input as #1
  input #1, Jogo.Volume
  input #1, Jogo.MaxAlcancada
  input #1, IAtual
  close #1
else
  Jogo.Volume   = 64
  Jogo.MaxAlcancada = 1
  IAtual = DefaultLanguage
end if
LeTXT (IAtual)

if Jogo.MaxAlcancada < 1 then Jogo.MaxAlcancada = 1
if Jogo.Volume < 0 or jogo.Volume > 127 then Jogo. Volume = 64

'midiOutSetVolume(0, (jogo.volume Shl 9) Or (jogo.volume Shl 1))

'FPS / velocidade
Jogo.Passos = 8
Jogo.DelayMSec = 33
Jogo.TamanhoPasso = 4   'pixels

'Le recordes
LeTopDez
ConfirmDel = 0

'Inicia parâmetros
IniciaJogo
IniciaVida
LimpaMina
MudaStatus NoMenu
TmpSleep = 25
sleep 20, 1
Quadros = 0
UltQuadros = 0
timer1 = Clock

cls

screenset 0, 1
ScrAtiva=0

'-----------------------------------------
'Chama o ciclo Principal
'-----------------------------------------

Joga

'-----------------------------------------
'Encerra o Programa
'-----------------------------------------

'Libera canais de som e memória alocada para imagens
#ifdef __FB_WIN32__
if hMidiOut <> 0 then midiOutClose hMidiOut
#else
#endif
for f= 0 to 277
  imagedestroy BMP (f)
next


end

'*****************************************
'*****************************************
'*****************************************
'Procedimentos e Funções
'*****************************************
'*****************************************
'*****************************************


'-------------------------------------------------------------------------------------------

'Desenha o fundo de listras coloridas dos menus, pausa, etc.

sub DesFundo
dim F as integer
  cRed = (Cred + 2) mod 256
  for F = 0 to 119
    CRed2 = (cred + f) mod 256
    if CRed2 > 127 then CRed2 = 255 - cred2
    line (0, f * 5) - (799, f * 5 + 9), rgb(cred2 * VRed, cred2 * VGreen, Cred2 * VBlue), bf
  next
end sub

'-------------------------------------------------------------------------------------------

'Desenha a barra indicando a carga do programa

sub LoadBar (perc as integer)
  line (25,525) - (25 + perc * 7.51,549), rgb(127,127,255),bf
  sleep 2, 1
end sub


'-------------------------------------------------------------------------------------------

'Desenha a tela

sub Desenha

  'Declaração de variáveis locais
  dim as integer XR, YR, X1, Y1, X1R, Y1R, BonecoR, Agua0, DF1, DF2, DG1, DG2, FigPt, F, G, H, I
  dim as integer TRX, TRY, TRXa, TRYa, Explodindo

  'Verifica se há explosão, para tremer a imagem
  for f=0 to 10
    if explosao(f).tipo > 0 and explosao(f).tempo < 10 then explodindo = 1
  next

  'Calcula que parte da tela deve ser mostrada
  if (Jogo.Status = ModoMapa) or (jogo.status = Top10) or (Jogo.Status = Editor) then
    TRX  = MapX
    TRY  = MapY
    TRXa = 0
    TRYa = 0

  else
    with Boneco
      'Calcula o X inicial da tela
      if Mina.Larg < 25 or .X < 12 then
        TRX  = 0
        TRXa = 0
      elseif .X > Mina.Larg - 12 then
        TRX  = Mina.LArg - 24
        TRXa = 0
      elseif .DirAtual = 1 then
        TRX  = .X - 12
        TRXa = -.Passo * Jogo.TamanhoPasso
      elseif .DirAtual = 2 then
        TRX  = .X - 13
        TRXa = (.Passo - Jogo.Passos) * Jogo.TamanhoPasso
      else
        TRX  = .x - 12
        TRXa = 0
      end if

      if .X = 12 and .DirAtual = 2 then
        TRX  = 0
        TRXa = 0
      end if

      if .x = Mina.Larg - 12 and .DirAtual = 1 then TRXa = 0

      'Calcula o Y inicial da tela
      if Mina.ALT < 17 or .Y < 8 then
        TRY  = 0
        TRYa = 0
      elseif .Y > Mina.ALT - 8 then
        TRY  = Mina.ALT - 16
        TRYa = 0
      elseif .DirAtual > 3 then
        TRY  = .Y - 8
        TRYa = -.Passo * Jogo.TamanhoPasso
      elseif .DirAtual = 3 then
        TRY  = .Y - 9
        TRYa = (.Passo - Jogo.Passos) * Jogo.TamanhoPasso
      else
        TRY  = .Y - 8
        TRYa = 0
      end if

      if .Y = 8 and .DirAtual = 3 then
        TRY  = 0
        TRYa = 0
      end if

      if .Y = Mina.ALT - 8 and .DirAtual > 3 then TRYa = 0

    end with
  end if

  if (mina.noturno = 0) or (Jogo.Status = Editor) then
    df1 = 0
    df2 = 25
    dg1 = 0
    dg2 = 17
  else
    'Limpa tela (desnecessário se não for no modo noturno, pois toda a tela é redesenhada)
    cls
    df1 = boneco.x - trx - 5
    df2 = boneco.x - trx + 5
    dg1 = boneco.y - try - 5
    dg2 = boneco.y - try + 5
    if df1 < 0  then df1 = 0
    if df2 > 25 then df2 = 25
    if dg1 < 0  then dg1 = 0
    if dg2 > 17 then dg2 = 17
  end if

  'Grupo de imagens do boneco
  if Boneco.NoOxigenio = 0 then
    BonecoR = Jogo.Player * 46
  else
    BonecoR = 23
  end if

  if Explodindo > 0 then
    TRXA = trxa + rnd * 11 - 5
    trya = TRYA + rnd * 11 - 5
  elseif jogo.status = VenceuJogo then
    TRXA = trxa + rnd * 3 - 1
    trya = TRYA + rnd * 3 - 1
  end if

  'Inicia o desenho
  '----------------

  'Desenha imagens do fundo (layer 0, pset)
  for f = df1 to df2
    for g = dg1 to dg2
      if fundo (TRX + f, TRY + g) > 0 then
        put (TRXa + f * 32, TRYa + g * 32), BMP (fundo (TRX + f, TRY + g)),pset
      else
        put (TRXa + F * 32, TRYa + g * 32), BMP (237), pset
      end if
    next
  next

  'Desenha os Objetos sobre o fundo (layer 1, trans)
  if (Jogo.Status <> Editor) or (EdShow =1 or EdShow = 2) then
    for f = df1 to df2
      for g = dg1 to dg2
        XR = 0
        YR = 0
        'Calcula posição de objeto caindo
        if objeto (TRX + f,TRY + g).caindo = 1 then
          YR = Objeto(TRX + f,TRY + g).Passo * Jogo. TamanhoPasso
        else
          'Calcula posição de objeto empurrado
          select case objeto (TRX + f,TRY + g).Empurrando
          case 1
            XR = Objeto (TRX + f,TRY + g).Passo * Jogo. TamanhoPasso
          case 2
            XR = -Objeto (TRX + f,TRY + g).Passo * Jogo. TamanhoPasso
          end select
        end if
        'Desenha o objeto na sua posição
        put (TRXa + f * 32 + XR, TRYa + g * 32 + YR), BMP (TpObjeto (Objeto (TRX + F,TRY + G).tp).Img), trans
      next
    next
  end if

  'Desenha o boneco (layer 1, trans)
  if Jogo.Status <> VenceuJogo and Jogo.Status <> Top10 and JOGO.STATUS <> GameOver and BONECO.MORREU = 0 then

    'Calcula Posição
    with Boneco

      'Escolhe imagem
      'Picareta
      if jogo.Status = Editor then
        .Img = Parado (0)
        .ImgX = .x * 32
        .ImgY = .y * 32
      else
        if .NaPicareta > 0 then
          .Img = Usando(0, .NaPicareta mod 2) + BonecoR
          put (TRXa + .ImgX - (TRX * 32), TRYa + .ImgY - (TRY * 32)+ 32), BMP (259 + int((.NaPicareta / Jogo.Passos) * 2.35)), trans

        'Furadeira
        elseif .NaFuradeira>0 then
          .img = Usando (.DirFuradeira, .NaFuradeira mod 2) + BonecoR
          if .DirFuradeira = 1 then
            put (TRXa + .ImgX - (TRX * 32) + 32, TRYa + .ImgY - (TRY * 32)), BMP (264 + int((.NaFuradeira / Jogo.Passos) * 2.35)), trans
          else
            put (TRXa + .ImgX - (TRX * 32) - 32, TRYa + .ImgY - (TRY * 32)), BMP (269 + int((.NaFuradeira / Jogo.Passos) * 2.35)), trans
          end if

        'Parado
        elseif .DirAtual = 0 then
          .img = Parado (.UltDir) + BonecoR

        'Movendo-se
        else
          .img = Movendo (.diratual + (.empurrando * 5) - 1, .passo mod 4) + BonecoR
        end if

        'Ajusta posição conforme movimento
        select case .DirAtual
        case 1 'Direita
          .ImgX = .x * 32 + (.Passo * Jogo.TamanhoPasso)
        case 2 'Esquerda
          .ImgX = .x * 32 - (.Passo * Jogo.TamanhoPasso)
        case 3 'Subindo
          .imgY = .y * 32 - (.Passo * Jogo.TamanhoPasso)
        case 4, 5 'Descendo / Caindo
          .imgY = .y * 32 + (.Passo * Jogo.TamanhoPasso)
        case else
          .ImgX = .x * 32
          .ImgY = .y * 32
        end select
      end if

      'Desenha
      put (TRXa + .ImgX - (TRX * 32), TRYa + .ImgY - (TRY * 32)), BMP (.Img), trans
    end with
  end if

  'Desenha objetos da frente (layer 3, trans)
  if (jogo.status <> Top10) and (Jogo.Status <> Editor or EdShow >=2) then
    for f = df1 to df2
      for g = dg1 to dg2
        if frente (TRX + f,TRY + g) > 0 then
          put (TRXa + f * 32, TRYa + g * 32), BMP (frente (TRX + f, TRY + g) + 24), alpha
        end if
      next
    next
  end if

  'Desenha água (layer 4, Alpha 95)
  Agua0 = (Jogo.seqciclo * 13) mod 20
  for f = df1 to df2
    for g = dg1 to dg2
      'Desenha, se o fundo for água (0)
      if fundo (TRX + f, TRY + g) = 0 then
        put (TRXa + f * 32, TRYa + g * 32), BMP (213 + (Agua0 + F + g * 6) mod 20), alpha, 95
      end if
    next
  next

  'Desenha Lanterna (layer 5, Alpha variável)
  if Jogo.Status <> Editor then
    if mina.noturno = 1 then
      put (TRXa + boneco.ImgX - (TRX * 32) - 208, TRYa + boneco.ImgY - (TRY * 32) - 208), BMP (275), (0, 0) - (443, 443), alpha
    end if

    'Desenha explosões (layer 6, trans)
    for f = 0 to 10
      with Explosao(f)

        if .tipo > 0 then
          for G = (.Tipo = 2) to - (.Tipo = 2)
            for H = -1 to 1
              put(TRXa + (.x - TRX + H) * 32, TRYa + (.y - TRY + G) * 32), BMP (185 + int(.tempo / 3)), alpha
            next
          next
        else
          .Tempo = 0
        end if

        'Incrementa contador
        .tempo += 1
        if .tempo >= 35 then
          .tempo = 0
          .tipo  = 0
        endif
      end with
    next

    'Mensagens de pontos na tela
    for I = 0 to 9
      with Msg (I)
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

  if Jogo.Status <> Editor then
    'Desenha a barra inferior
    put (0, 544), BMP (210), pset

    with Boneco

      'Pontuação
      EscreveNumero .Pontos, 6, 7, 577, 0

      'Núm. mina
      'If Jogo.Status <> ModoDemo Then
        EscreveNumero .Mina, 3, 96, 577, 0
      'end if

      'Oxigenio
      put( 151, 576), BMP (209), (0, 0) - step (.Oxigenio, 15), pset

      'Qtde Itens Garrafa de Oxigenio
      EscreveNumero .ItOxigenio, 1, 296, 575, 0

      'Qtde Itens Suporte Pedra
      EscreveNumero .ItSuporte, 1, 347, 575, 0

      'Qtde Itens Picareta
      EscreveNumero .ItPicareta, 1, 393, 575, 0

      'Qtde Itens Furadeira
      EscreveNumero .ItFuradeira, 1, 445, 575, 0

      'Qtde Itens Bombinha
      EscreveNumero .ItBombinha, 1, 489, 575, 0

      'Qtde Itens Bombona
      EscreveNumero .ItBombona, 1, 532, 575, 0

      'Quantidade de pedras a recolher
      EscreveNumero Mina.Tesouros, 2, 550, 575, 0

      'Vidas
      EscreveNumero .Vidas, 2, 582, 576, 0

    end with

    'Tempo Maximo
    if Mina.Tempo > 0 then
      EscreveNumero int(mina.Tempo/60), 2, 655,556, 1
      EscreveNumero Mina.Tempo mod 60, 2, 683,556, 1
      if mina.tempo - boneco.tempo >= 20 or Jogo.Status <> Jogando then
        put (642, 578), BMP(238), (48, 0) - step (9, 14), trans
      else
        if (jogo.seqciclo mod 2 = 1) or (jogo.status = VenceuJogo) then put (642, 578), BMP (238), (int ((mina.tempo - boneco.tempo) / 5) * 12, 0) - step (9, 14), trans
      end if
    end if
    if jogo.seqciclo mod 2 = 1 and boneco.morreu = 0 and iniciado > 0 and jogo.status <> VenceuJogo then
      line (679, 582) - (680, 590), point (679, 581), bf
    end if
    EscreveNumero int(Boneco.Tempo / 60), 2, 655, 578, 1
    EscreveNumero Boneco.Tempo mod 60, 2, 683, 578, 1

    if Jogo.Status = ModoDemo then
      DemoCiclo = DemoCiclo + 1
      select case MensDemo
      case 1
        EscreveCentro TXT(11), 430, 1, 0
        EscreveCentro TXT(12), 460, 1, 0
      case 2
        EscreveCentro TXT(13), 445, 1, 0
      case 3
        EscreveCentro TXT(14), 430, 1, 0
        EscreveCentro TXT(15), 460, 1, 0
      case 4
        EscreveCentro TXT(16), 430, 1, 0
        EscreveCentro TXT(17), 460, 1, 0
      case 5
        EscreveCentro TXT(18), 445, 1, 0
      case 6
        EscreveCentro TXT(19), 430, 1, 0
        EscreveCentro TXT(20), 460, 1, 0
      case 7
        EscreveCentro TXT(21), 430, 1, 0
        EscreveCentro TXT(22), 460, 1, 0
      case 8
        EscreveCentro TXT(23), 445, 1, 0
      case 9
        EscreveCentro TXT(24), 445, 1, 0
      case 10
        EscreveCentro TXT(25), 430, 1, 0
        EscreveCentro TXT(26), 460, 1, 0
      case 11
        EscreveCentro TXT(27), 430, 1, 0
        EscreveCentro TXT(28), 460, 1, 0
      case 12
        EscreveCentro TXT(29), 430, 1, 0
        EscreveCentro TXT(30), 460, 1, 0
      case 13
        EscreveCentro TXT(31), 430, 1, 0
        EscreveCentro TXT(32), 460, 1, 0
      case 14
        EscreveCentro TXT(33), 430, 1, 0
        EscreveCentro TXT(34), 460, 1, 0
      case 15
        EscreveCentro TXT(35), 430, 1, 0
        EscreveCentro TXT(36), 460, 1, 0
      case 16
        EscreveCentro TXT(37), 430, 1, 0
        EscreveCentro TXT(38), 460, 1, 0
      case 17
        EscreveCentro TXT(39), 430, 1, 0
        EscreveCentro TXT(40), 460, 1, 0
      case 18
        EscreveCentro TXT(41), 445, 1, 0
      case 19
        EscreveCentro TXT(42), 430, 1, 0
        EscreveCentro TXT(43), 460, 1, 0
      case 20
        EscreveCentro TXT(44), 430, 1, 0
        EscreveCentro TXT(45), 460, 1, 0
      case 21
        EscreveCentro TXT(46), 430, 1, 0
        EscreveCentro TXT(47), 460, 1, 0
      case 22
        EscreveCentro TXT(48), 430, 1, 0
        EscreveCentro TXT(49), 460, 1, 0
        for F = 0 to 4
          line (480 + f, 480)-(533 + f, 533), &HFFA000
          line (515, 529 + f)-(533, 529 + f), &HFFA000
          line (533 + f, 515)-(533 + f, 533), &HFFA000
        next
      end select
    end if
  else

    line (0, 543) - (799, 543), &H000000

    select case Jogo.EdStatus
    case Editando
      line (1, 545) - (609, 563), &HA0A0A0, BF
      line (0, 565) - (610, 599), &H000000, BF
      line (611, 544) - (611, 599), &H606060
      line (612, 544) - (612, 599), &H000000
      line (614, 545) - (798, 598), &HA0A0A0, BF
      line (667 , 544) - (667 , 599), &H000000
      line (718 , 544) - (718 , 599), &H000000

      select case PosMouse
      case EdForaTela
        'Nada a fazer
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
        line (int (MouseX / 34) * 34 - 1, 565) - step (35, 34), &HFFFFFF, BF
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
      case EdEXIT
        line (774, 573) - (798, 598), &HFFFFFF, BF
      end select

      'se mouse estiver sobre qualquer área, fazer um hilight em amarelo ou verde
      put (0, 544), bmp (279), trans
      'calcula posiçao da barra e mostra:
      put (46 + Primeiroitem * 4.48, 545), BMP (278), alpha
      put (613, 544), BMP(280), trans

      if ItemSel >= PrimeiroItem and ItemSel <= PrimeiroItem + 17 then
        line (int (ItemSel - PrimeiroItem) * 34 - 1, 565) - step (35, 34), &H40ff40, BF
      end if

      for f = 0 to 17
        DesenhaItem f * 34 + 1, 568, PrimeiroItem + F
      next

      if EdShow = 0 or Edshow = 1 then put (670, 547), Bmp (281), trans
      if EdShow = 0 or Edshow = 3 then put (670, 564), Bmp (281), trans

    case Selecionando
      DesBox 24, 1, 4, 400, 572
      EscreveCentro TXT(109), 562
      Dlinha EDXX1 * 32 - 3, EDYY1 * 32 - 3, EDXX2 * 32 + 34, EDYY2 * 32 + 34, 1
    case EdMovendo
      DesBox 24, 1, 4, 400, 572
      EscreveCentro TXT(110), 562
    case Apagando0, Apagando1
      DesBox 24, 1, 4, 400, 572
      EscreveCentro TXT(111), 562
      if Jogo.EdStatus = Apagando0 then
        Dlinha EDX1 * 32 - 3, EDY1 * 32 - 3, EDX1 * 32 + 34, EDY1 * 32 + 34, 3
      else
        Dlinha EDXX1 * 32 - 3, EDYY1 * 32 - 3, EDXX2 * 32 + 34, EDYY2 * 32 + 34, 2
      end if
    end select
  end if
end sub

'-------------------------------------------------------------------------------------------

'Escreve a pontuação ganha na tela

sub EscrevePT (Pontos as  integer, X as integer, Y as integer, CJCarac as integer)
  dim as string StrNum, NumTxt
  dim as integer X1, NumVal, F

  'Passa o número para texto
  StrNum= str(Pontos)
  X1 = X - (len (StrNum) * 6)
  for f = 1 to len (StrNum)
    NumTxt = mid(StrNum, f, 1)
    NumVal = val (NumTxt)
    put (x1 + f * 12 - 12, Y), BMP (239 + CJCarac), (NumVal * 9, 0) - step (8,14), alpha
  next
end sub

'-------------------------------------------------------------------------------------------

'Escreve um número (caracteres especiais)

sub EscreveNumero (byval Numero as long, Comprimento as  integer, X1 as integer, Y1 as integer, Preenche as integer)
  dim as string StrNum, NumTxt
  dim as integer NumVal, F

  if Preenche=0 then
    StrNum= right(space (Comprimento) & str(Numero), Comprimento)
  else
    StrNum= right("0000000000" & str(Numero), Comprimento)
  end if
  if len (StrNum) < len (str(Numero)) then StrNum = string (Comprimento, "+")

  for f= 1 to Comprimento
    NumTxt= mid(StrNum,f,1)
    if NumTxt =" " then
      NumVal=0
    elseif NumTxt ="+" then
      NumVal=11
    else
      NumVal=val(NumTxt)+1
    end if
    put (x1+f*12-12, Y1), BMP (197 + NumVal), pset
  next
end sub

'----------------------------------------------------------------------

'Escreve textos

sub Escreve (byval Texto as string, x1 as integer, y1 as integer, Bold as integer = 0, BoldV as integer = 0)
  dim as integer LF, PosL, LG, LV
  for LF = 1 to len(Texto)
    PosL = instr(Lt_, mid(Texto, LF, 1)) - 1
    if PosL = -1 then
      X1 += 8
    else
      for LV = 0 to BoldV
        for LG = 0 to Bold
          put(X1 + LG, Y1 + LV), BMP (247), (PosLetra (PosL, 0), 0) - (PosLetra (PosL, 1), 21), alpha
        next
      next
      x1 += PosLetra (PosL, 1) - PosLetra (PosL, 0) + Bold + 2
    end if
  next
end sub

'----------------------------------------------------------------------

'Escreve textos centralizados

sub EscreveCentro (byval Texto as string, Y1 as integer, Bold as integer = 0, BoldV as integer = 0)
  Escreve Texto, 399-LargTexto(Texto, Bold)/2, Y1, Bold, BoldV
end sub

'----------------------------------------------------------------------

'Calcula a largura que um texto ocupa em pixels

function LargTexto (byval Texto as string, Bold as integer = 0) as integer
  dim as integer LF, PosL, LArg
  for LF = 1 to len (Texto)
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

'-------------------------------------------------------------------------------------------

'Inicializa dados para nova partida

sub IniciaJogo
  randomize
  'Inicializa as variáveis principais
  with Jogo
    .UltExplosao=0
    .Encerra=0
    .player=int(rnd * 2)
    .Ciclo=0
  .SeqCiclo=0
  end with

  with Boneco
    .Mina=1
    .Vidas=Jogo.NumVidas
    .Pontos=0
  end with
end sub

'----------------------------------------------------------------------

'Inicia dados da vida (zera status do boneco)

sub IniciaVida
  dim F as integer
  with Boneco
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
  TIMESTART = Clock + 5
  Jogo.UltExplosao=0
  for f = 0 to 10
    Explosao (f).Tipo=0
    Explosao (f).Tempo=0
  next
end sub

'----------------------------------------------------------------------

'Le arquivo e monta uma mina

sub LeMinaOUT (NMina as integer, Editando as integer = 0)
  dim as string Linha, NArq
  randomize

  LimpaMina

  'zera contador de tesouros para iniciar a contagem
  Mina.Tesouros = 0

  'Abre arquivo
  if NMina = -1 then
    NArq = "minas/teste.map"
  else
    LimpaMinaEditor
    NArq = "minas/m" + right("000" & str(NMina), 3) + ".map"
  end if

  'Verifica se o arquivo existe
  if fileexists (Narq) then
    if NMina > -1 then Mina.numero = NMina
    open Narq for binary as #1
    get #1, , Mina.LArg
    get #1, , Mina.Alt
    get #1, , Mina.Noturno
    get #1, , Mina.Tempo

    LeMinaDet Editando
    close #1

  else  'Arquivo não existe
    Mensagem 4, 8, TXT(0), TXT(50),""
    if Tecla <>"" and Tecla <> UltTecla then
      MudaStatus NoMenu
    end if
    MudaStatus NoMenu
    IniciaJogo
    IniciaVida
    LimpaMina
    LimpaMinaEditor
  end if

end sub

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------

'Sub Principal

sub Joga
  dim as integer Emp1, Emp2, Emp3, SeqDemo, F, G, H, I
  DEBUG_LOG("Begin of the game procedure")
  
  ATimer = int(Clock * 1000)
  if VRed+VGreen+VBlue=0 then VBlue=1
  TeclasDemo= "R01M01R15M22R23M02R24M03L23M04L16M05L12M06L08M07L05M08L04M09D04L00R01W20L00M10R24D06M11L22IC L20ICLL18ICLL16M12IV R18W50L14IV R16W50L12ICLL10" & _
        "IV R12W50L08ICLL06IV R08W50L04ICLL02IV R04W50L01M13L00IX M14D08R04M15IB L02W50R06IB L04W50R08IB L06W50R10IB L08W50R12IB L10W50R14IB L12W50R16IB L14W50" & _
        "R17M16R20IZ R21M17R22M18IB L19W20L01M19D10L00M20R24U09M21###"
  Tecla = ""


  '-------------
  '#############
  '-------------

  'CICLO DO JOGO

  '-------------
  '#############
  '-------------

  while Jogo.Encerra = 0

    Jogo.Status0 = Jogo.Status

    'Silencia canais que terminaram de reproduzir sons
    for f = 1 to 6
      for g = 1 to 4
        if Som (f, g).Tempo > 0 then
          Som (f, g).Tempo -=1
#ifdef __FB_WIN32__
          if Som (f, g).Tempo = 0 then midiOutShortMsg (hMidiOut, Som(f,g).COff)
#else
#endif
        end if
      next
      if SomEx (f).Tempo > 0 then
        SomEx (f).Tempo -= 1
#ifdef __FB_WIN32__
        if SomEx (f).Tempo = 0 then midiOutShortMsg (hMidiOut, SomEx(f).COff)
#else
#endif
      end if
    next

    if inkey = chr(255) + "k" then
      Jogo.Encerra = 1
      goto TerminaCiclo
    end if

    'Não há som a reproduzir
    for f =1 to 6
      for g = 1 to 4
        Toca(f, g) = 0
      next
    next

    'Incrementa Contador de ciclos
    with Jogo
      .Ciclo = (.Ciclo+1) mod .passos
      If.Ciclo=0 then
        .SeqCiclo= (.SeqCiclo + 1) mod 1500
        if .seqciclo mod 10 = 0 then windowtitle "FreeBasic Miner"
      end if
    end with

    'Lê o teclado
    UltTecla = Tecla
    Tecla = ""
    'Controles
    for F = 0 to 127
      if multikey (f) then Tecla = "?"
    next
    if multikey(FB.SC_ENTER) then Tecla ="["
    if multikey(FB.SC_ESCAPE) then Tecla ="ESC"
    if multikey(FB.SC_SPACE) then Tecla = "]"
    if multikey(FB.SC_DELETE) then Tecla = "<"
    if multikey(FB.SC_P) then Tecla ="P"
    if multikey(FB.SC_A) then Tecla = "A"
    if multikey(FB.SC_B) then Tecla = "B"
    if multikey(FB.SC_C) then Tecla = "C"
    if multikey(FB.SC_M) then Tecla = "M"
    if multikey(FB.SC_Q) then Tecla = "Q"
    if multikey(FB.SC_V) then Tecla = "V"
    if multikey(FB.SC_X) then Tecla = "X"
    if multikey(FB.SC_Z) then Tecla = "Z"
    if multikey(SC_TAB) then Tecla = "TAB"
    if multikey(SC_PAGEUP) then Tecla = "@"
    if multikey(SC_PAGEDOWN) then Tecla = "#"
    'Movimento
    if multikey(FB.SC_DOWN) then Tecla ="D"
    if multikey(FB.SC_LEFT) then Tecla ="L"
    if multikey(FB.SC_RIGHT) then Tecla ="R"
    if multikey(FB.SC_UP) then Tecla ="U"

    LeMouse

    select case Jogo.Status
    '-------------------------------------------------------------------------------------------

    case NoMenu 'MENU --> mostra as opções até uma ser escolhida

      'Fundo e LOGO
      DesFundo
      PutLogo 290, 40

      'Opções
      MouseSobre = -1
      for F = 0 to 8
        if (MouseY > 300) and (MouseY < 363) and (MouseX > 48 + F * 80) and (MouseX < 111 + F * 80) then
          MouseSobre = F
          if (MouseMoveu = 1) and (OpMenu <> F) then
#ifdef __FB_WIN32__
            midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
#else
#endif
            OpMenu = F
#ifdef __FB_WIN32__
            midiOutShortMsg (hMidiOut, &H76c0)
            midiOutShortMsg (hMidiOut, &H7f4090 + (OpMenu * 256))
#else
#endif
          end if
        end if
        if OpMenu = F then
          put (32 + f * 80, 284), BMP (277), (0,0)-(95,95), alpha
          put (48 + F * 80, 300), BMP (276), (f*64,64)-Step(63,63), trans
        else
          put (48 + F * 80, 300), BMP (276), (f*64,0)-Step(63,63), trans
        end if
      next
      EscreveCentro TXT (OpMenu + 2), 380, 1, 1

      if (Tecla <> "") or (MouseMoveu = 1) then TTDemo1 = Clock

      if MouseSobre > -1 and MouseDisparou = 1 then OpMenu = MouseSobre : Tecla = "["

      if UltTecla <> Tecla then

        if Tecla = "D" or tecla = "R" then
#ifdef __FB_WIN32__
          midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
#else
#endif
          OpMenu = (Opmenu + 1) mod (Sair + 1)
#ifdef __FB_WIN32__
          midiOutShortMsg (hMidiOut, &H76c0)
          midiOutShortMsg (hMidiOut, &H7f4090 + (OpMenu * 256))
#else
#endif
        elseif Tecla = "U" or Tecla = "L" then
#ifdef __FB_WIN32__
          midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
#else
#endif
          OpMenu = (OpMenu + Sair) mod (Sair + 1)
#ifdef __FB_WIN32__
          midiOutShortMsg (hMidiOut, &H76c0)
          midiOutShortMsg (hMidiOut, &H7f4090 + (OpMenu * 256))
#else
#endif
        elseif Tecla = "ESC" then
          Jogo.encerra=1
        elseif Tecla = "[" or tecla = "]" then
          select case OpMenu  'Jogar, IrPara, VerTop, Sobre, Volume, EscIdioma, Custom, Editar, Sair
          case Jogar
            Opcao1 = 0
            MudaStatus Jogando
            IniciaJogo
            IniciaVida
            Mina.Tipo = 0
            LeMinaIn 1
            Iniciado=0
            TIMESTART = Clock + 5
          case IrPara, Volume
            Opcao1 = 0
            MudaStatus Configs
          case VerTop
            MudaStatus Top10
            PosTop10 = 0
          case Sobre
            MudaStatus Instruc
          case EscIdioma
            Jogo.Status = SelIdioma
            ProcIdiomas
          case Custom_
            Opcao1 = 0
            Boneco.Mina = 0
            cls
            TrocaTelas
            cls
            Mensagem 7, 8, TXT(92), TXT(93), " "
            LeMinasPers
            TrocaTelas
            cls
            MudaStatus Configs
          case Editar
            Opcao1 = 0
            Boneco.Mina = 0
            cls
            TrocaTelas
            cls
            Mensagem 7, 8, TXT(92), TXT(93), " "
            LeMinasPers
            TrocaTelas
            cls
            MudaStatus Configs
          case Sair
            Jogo.encerra = 1
          end select
        end if
      end if

      if Clock > TTDemo1 + 8 then
        MudaStatus ModoDemo
        Mina.Tipo = 0
        IniciaJogo
        IniciaVida
        LeMinaIn 0
        Iniciado=0
        MensDemo = 0
        TempMens = 0
        Tecla = ""
        PositDemo = 0
        DemoW1 = 0
        DemoW2 = 0
        DemoCiclo = 0
      end if

    '-------------------------------------------------------------------------------------------

    case SelIdioma  'troca o idioma do programa
      DesFundo
      PutLogo 290, 40

      if IQuant = 0 then
        Mensagem 5, 8, "Só há o idioma português instalado.", "", ""
        if Tecla <> "" and ulttecla <> Tecla then
          MudaStatus NoMenu
        end if
      else
        DesBox 10, IQuant + 3, 0, 400, 370
        EscreveCentro TXT(7), 374 - (IQuant + 3) * 16, 1, 1
        MouseSobre = -1
        for f = 0 to IQuant
          if (MouseX > 252) and (MouseX < 547) and (abs (MouseY - (444 - (IQuant + 3) * 16 + f * 32)) < 16) then
            MouseSobre = F
            if MouseMoveu = 1 then NAtual = F
          end if
          EscreveCentro Idioma (f), 434 - (IQuant + 3) * 16 + F * 32, 1, 0
        next
        line (250, 426 - (IQuant + 3) * 16 + NAtual * 32) - step (300, 35), rgb (0, 127, 255), b
        line (251, 427 - (IQuant + 3) * 16 + NAtual * 32) - step (298, 33), rgb (0, 127, 255), b

        if MouseSobre > -1 and MouseDisparou = 1 then NAtual = MouseSobre : Tecla = "["

        if UltTecla <> Tecla then
          if (Tecla = "U" or Tecla ="L") and NAtual > 0 then NAtual -= 1
          if (Tecla = "D" or Tecla ="R") and NAtual < IQuant then NAtual += 1
          if Tecla = "[" or Tecla = "]" then
            IAtual = Idioma (NAtual)
            LeTXT (IAtual)
            RegravaConfig
            MudaStatus NoMenu
          end if
          if Tecla = "ESC" then MudaStatus NoMenu
        end if
      end if

    '-------------------------------------------------------------------------------------------

    case Configs 'trata algumas opções do menu

      'Desenha fundo e LOGO
      DesFundo
      PutLogo 290, 40

      select case OpMenu
      case IrPara 'Ir para Mina...
        if Boneco.Mina < 1 or Boneco.Mina > Jogo.NumMinas then Boneco.Mina = 1
        EscreveCentro TXT(51), 140, 1, 0
        EscreveCentro TXT(52), 575, 1, 0

        Mina1 = int((boneco.mina - 1) / 100) * 100 + 1
        if Mina1 > Jogo.NumMinas - 100 then
          Mina2 = Jogo.NumMinas - Mina1 + 1
        else
          Mina2 = 100
        end if

        MouseSobre = -1

        for F = 0 to Mina2 - 1
          XM = (F mod 10) * 65 + 80
          YM = int (F / 10) * 40 + (370 - int((Mina2 + 9)/10) * 20)
          if Mina1 + F > Jogo.MaxAlcancada then
            put (XM, YM + 2), BMP (276), (576, 33) - (630, 65), trans
          else
            put (XM, YM + 2), BMP (276), (576, 0) - (630, 32), trans
          end if
          if (MouseX > XM) and (MOuseX < XM + 54) and (MouseY > YM + 2) and (MouseY < YM + 35) then
            MouseSobre = Mina1 + F
          end if
          if Mina1 + F > Jogo.MaxAlcancada then
            put (XM, YM + 6), BMP (276), (576, 103) - (630, 127), trans
          elseif Mina1 + F < 10 then
            Escreve str(Mina1 + F), XM + 23, YM + 8, 1, 0
          elseif Mina1 + F < 100 then
            Escreve str(Mina1 + F), XM + 17, YM + 8, 1, 0
          else
            Escreve str(Mina1 + F), XM + 11, YM + 8, 1, 0
          end if

        next

        if (MouseMoveu = 1) and (MouseSobre > -1) then Boneco.Mina = MouseSobre
        if MouseSobre > -1 and MouseDisparou = 1 then Boneco.Mina = MouseSobre : Tecla = "["
        XM = ((Boneco.Mina - Mina1) mod 10) * 65 + 80
        YM = int ((Boneco.Mina - Mina1) / 10) * 40 + (370 - int((Mina2+9)/10) * 20)
        put (XM, YM), BMP (276), (576, 66)-(630, 102), trans

        if MouseWDir = -1 then Tecla = "#"
        if MouseWDir = 1 then Tecla = "@"

        if Tecla <>"" and Tecla <> UltTecla then
          select case Tecla
          case "D"
            if Boneco.Mina <= Jogo.NumMinas - 10 then Boneco.Mina += 10
          case "L"
            if Boneco.Mina > 1 then Boneco.Mina -= 1
          case "U"
            if Boneco.Mina > 10 then Boneco.Mina -= 10
          case "R"
            if Boneco.Mina < Jogo.NumMinas then Boneco.Mina += 1
          case "@"
            if Boneco.Mina > 100 then Boneco.Mina -= 100 else Boneco. Mina = 1
          case "#"
            if Boneco.Mina < Jogo.NumMinas - 100 then Boneco.Mina += 100 else Boneco.Mina = Jogo.NumMinas
          case "ESC"
            MudaStatus NoMenu
          case "[", "]"
            if Boneco.Mina <= Jogo.MaxAlcancada then
              XM = Boneco.Mina
              IniciaJogo
              IniciaVida
              Boneco.Mina = XM
              Mina.Tipo = 0
              LeMinaIn XM
              Iniciado = 0
              TIMESTART = Clock + 5
              MudaStatus Jogando
            end if
          end select
        end if

      case Volume 'Ajuste do Volume

        put (364,250), BMP (276), (256,0)-Step(63,63), trans
        MouseSobre = -1
        if (MouseY > 330) and (MouseY < 400) and (MouseX > 270) and (MouseX < 530) then
          MouseSobre = (MouseX - 275) / 2
          if MouseSobre <0 then MouseSobre = 0
          if MouseSobre > 127 then MouseSobre = 127
        end if

        if MouseDisparou = 1 then
          if MouseSobre > -1 then
            Jogo.volume = mousesobre
          else
            Tecla = "["
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
        for F = 0 to 15
          if Jogo.Volume >= F * 8 then
            line (275 + f * 16, 400) - step(10, -10 - f * 4), CorRGB, BF
          else
            line (275 + f * 16, 400) - step(10, -10 - f * 4), CorRGB2, BF
          end if
        next
        if jogo.volume = 0  then line (275,400) - step(10, -10 ), rgba(180,0,0,0), BF
        if jogo.volume = 127  then line (515,400) - step(10, -70 ), rgba(200,200,0,0), BF
        EscreveCentro TXT(53), 440, 1, 0
        EscreveCentro TXT(54), 500, 1, 0

        if tecla = "D" or Tecla = "L" then
          if Jogo.Volume > 0 then Jogo.volume -= 1
        elseif tecla = "U" or tecla = "R" then
          if jogo.volume < 127 then Jogo.volume += 1
        elseif (tecla = "[" or tecla = "]" or Tecla = "ESC") and UltTecla <> tecla then
          RegravaConfig
          MudaStatus NoMenu
        elseif MouseWDir = -1 then
          if Jogo.Volume > 8 then
            Jogo.Volume -= 8
          else
            Jogo.Volume = 0
          end if
        elseif MouseWDir = 1 then
          Jogo.Volume += 8
          if Jogo.Volume > 127 then Jogo.Volume = 127
        end if
#ifdef __FB_WIN32__
        midiOutSetVolume(0, (jogo.volume shl 9) Or (jogo.volume shl 1))
#else
#endif

      case Custom_, Editar
        MouseSobre = -1
        if (QuantPers = 0) then
          if OpMenu = Editar then
            LimpaMina
            LimpaMinaEditor
            MudaStatus Editor
            Jogo.EdStatus = Editando
          else
            Mensagem 7, 8, TXT(55), TXT(56),""
            if (Tecla <>"" and Tecla <> UltTecla) or (MouseDisparou = 1) then
              MudaStatus NoMenu
            end if
          end if
        else
          if Boneco.Mina < 0 or Boneco.Mina > QuantPers -1 then Boneco.Mina = 0
          EscreveCentro TXT(51), 140, 1, 0
          if OpMenu = Editar then
            EscreveCentro TXT(97), 575, 1, 0
          else
            EscreveCentro TXT(52), 575, 1, 0
          end if

          Mina1 = int((boneco.mina) / 100) * 100
          if Mina1 > QuantPers - 100 then
            Mina2 = QuantPers - Mina1
          else
            Mina2 = 100
          end if

          for F = 0 to Mina2 - 1
            XM = (F mod 10) * 65 + 80
            YM = int (F / 10) * 40 + (370 - int((Mina2 + 9)/10) * 20)
            put (XM, YM+2), BMP (276), (576, 0)-(630, 32), trans
            if (MouseX > XM) and (MOuseX < XM + 54) and (MouseY > YM + 2) and (MouseY < YM + 35) then
              MouseSobre = Mina1 + F
            end if

            PersTemp = MinaPers (Mina1 + F)
            if PersTemp < 10 then
              Escreve str(PersTemp), XM + 23, YM + 8, 1, 0
            elseif PersTemp < 100 then
              Escreve str(PersTemp), XM + 17, YM + 8, 1, 0
            else
              Escreve str(PersTemp), XM + 11, YM + 8, 1, 0
            end if
          next
          if (MouseMoveu = 1) and (MouseSobre > -1) then Boneco.Mina = MouseSobre
          if MouseSobre > -1 and MouseDisparou = 1 then Boneco.Mina = MouseSobre : Tecla = "["

          XM = ((Boneco.Mina - Mina1) mod 10) * 65 + 80
          YM = int ((Boneco.Mina - Mina1) / 10) * 40 + (370 - int((Mina2 + 9)/10) * 20)
          put (XM, YM), BMP (276), (576,66)-(630, 102), trans
          if MouseWDir = -1 then Tecla = "#"
          if MouseWDir = 1 then Tecla = "@"

          if Tecla <>"" and Tecla <> UltTecla then
            select case Tecla
            case "D"
              Boneco.Mina += 10
              if Boneco.Mina >= QuantPers then Boneco.Mina -= 10
            case "L"
              Boneco.Mina -= 1
              if Boneco.Mina < 0 then Boneco.Mina = 0
            case "U"
              Boneco.Mina -= 10
              if Boneco.Mina < 0 then Boneco.Mina += 10
            case "R"
              Boneco.Mina += 1
              if Boneco.Mina >= QuantPers then Boneco.Mina = QuantPers - 1
            case "@"
              Boneco.Mina -= 100
              if Boneco.Mina < 0 then Boneco.Mina = 0
            case "#"
              Boneco.Mina += 100
              if Boneco.Mina >= QuantPers then Boneco.Mina = QuantPers - 1
            case "TAB"
              if OpMenu = Editar then
                LimpaMina
                LimpaMinaEditor
                MudaStatus Editor
              end if
            case "ESC"
              Boneco.Mina = 1
              MudaStatus NoMenu
            case "[", "]"
              XM = MinaPers(Boneco.Mina)
              IniciaJogo
              IniciaVida
              Boneco.Mina = XM
              Mina.Tipo = 1
              Iniciado = 0
              TIMESTART = Clock + 5
              if OpMenu = Editar then
                LeMinaOUT XM, 1
                MudaStatus Editor
                while MouseB = 1 and MouseX <> -1
                  sleep 1, 1
                  LeMouse
                wend
              else
                LeMinaOUT XM, 0
                MudaStatus Jogando
              end if
            end select
          end if
        end if
      end select
    '-------------------------------------------------------------------------------------------

    case Jogando, ModoDemo, Testando 'JOGANDO; MODO DEMONSTRAÇÃO; TESTANDO MINA EM EDIÇÃO

      if Jogo.Status = ModoDemo then
        'No modo demo, qualquer tecla faz voltar pro menu
        for F= 1 to 127
          if (multikey(f)) then MudaStatus NoMenu
        next

        'Busca comandos ou direções para modo demo
        if Boneco.NaFuradeira = 0 and Boneco.NaPicareta = 0 then
          Tecla = ProximaTeclaDemo ()
          if Tecla = "ESC" then
            MudaStatus NoMenu
          end if
        end if
      end if

      'Verifica se acabou o tempo
      if (jogo.SeqCiclo mod 8 = 0) and (jogo.Ciclo = 0) and (iniciado > 0) and (boneco.morreu = 0) then
        boneco.Tempo += 1
        if (boneco.tempo >= mina.tempo) and (mina.tempo > 0) and (Jogo.Status = Jogando) then
          boneco.morreu = 1
        end if
      end if

      'Verifica Comandos: PAUSAR, MAPA, QUIT e ESC
      if boneco.morreu = 0 and iniciado = 1 and (Jogo.Status = Jogando or Jogo.Status = Testando) and UltTecla <> Tecla then
        select case Tecla
        case "M"  'Mapa
          with boneco
            if (mina.Larg > 24 or mina.Alt > 16) then
              'Calcula o X inicial da tela
              if Mina.Larg <25 or .X<=12 then
                MapX=0
              elseif .X>= Mina.Larg-12 then
                MapX=Mina.LArg-24
              else
                MapX=.X-12
              end if

              'Calcula o Y inicial da tela
              if Mina.Alt <17 or .Y<=8 then
                MapY=0
              elseif .Y> Mina.Alt-8 then
                MapY=Mina.Alt-16
              else
                MapY=.Y-8
              end if
              MudaStatus ModoMapa
            else
              'Som DAME
              'midiOutShortMsg (hMidiOut, SomEx(6).COn1)
              'midiOutShortMsg (hMidiOut, SomEx(6).COn2)
              SomEx(6). Tempo = 4
            end if
          end with

        case "P"  'Pausa
          MudaStatus Pausado

        case "ESC"  'ESC
          if Jogo.Status = Testando then
            LMTEC=""
            LimpaTeclado
            opcao1 = 0
            DesligaSons
            while lmtec <> " " and LMTec <> chr(13) and lmtec <> chr(27)
              cls
              Mensagem 4, 5, TXT (95), "", "", 400, 300, Opcao1
              LMTec=inkey
              LeMouse
              if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
              if (MouseDisparou = 1) and (MouseSimNao > 0) then LMTec = " "
              if (LmTec = c255 + "H") or (LmTec = c255+ "K") or (LmTec = c255+ "M") or (LmTec = c255+ "P") then Opcao1 = 1 - Opcao1
              TrocaTelas
            wend
            cls
            if (LmTec <> chr(27)) and (Opcao1 = 0) then EncerraTeste
            LimpaTeclado 1

          else
            boneco.Morreu = 1
          end if

        case "Q"  'Quit

          LMTEC=""
          LimpaTeclado
          opcao1 = 0
          while lmtec <> " " and LMTec <> chr(13) and lmtec <> chr(27)
            cls
            Mensagem 4, 5, TXT(57), "", "", 400, 300, Opcao1
            LMTec=inkey
            LeMouse
            if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
            if (MouseDisparou = 1) and (MouseSimNao > 0) then LMTec = " "
            if (LmTec = c255+ "H") or (LmTec = c255+ "K") or (LmTec = c255+ "M") or (LmTec = c255+ "P") then Opcao1 = 1 - Opcao1
            TrocaTelas
            jogo.seqciclo=(jogo.seqciclo+1) mod 360
          wend
          cls
          if LMTec <> chr(27) and Opcao1 = 0 then
            jogo.encerra = 1
          end if

          LimpaTeclado 1

        end select
      end if

      if (Jogo.Status0 = Jogo.Status) and (Jogo.Encerra <> 1) then
        'Conclui movimentação de objetos empurrados
        if Boneco.Empurrando = 1 then
          if Boneco.DirAtual = 1 then
            Emp1 = Mina.Larg
            Emp2 = 0
            Emp3 = -1
          else
            Emp1 = 0
            Emp2 = Mina.Larg
            Emp3 = 1
          end if
          for F = Emp1 to Emp2 step Emp3
            with Objeto (F, boneco.Y)
              if .Empurrando > 0 and .Passo >= Jogo.Passos -1 then
                Objeto(F + 3 - .Empurrando * 2, boneco.y).Tp = .Tp
                Objeto(F + 3 - .Empurrando * 2, boneco.y).Passo = 0
                Objeto(F + 3 - .Empurrando * 2, boneco.y).Empurrando = 0
                Objeto(F + 3 - .Empurrando * 2, boneco.y).Caindo = 0
                Objeto(F + 3 - .Empurrando * 2, boneco.y).AntCaindo = 0
                .Passo = 0
                .Empurrando = 0
                .Caindo = 0
                .AntCaindo=0
                .Tp = 0
              end if
            end with
          next
        else
          'midiOutShortMsg (hMidiOut, SomEx(7).COff)
        end if

        'Verifica e conclui movimentação e outros comportamentos do boneco
        with Boneco
          'Se concluiu movimento nesta passagem, zera movimento
          if .DirAtual > 0 and .Passo = Jogo.Passos then
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
            if ((Tecla <> "") and (Tecla <> UltTecla)) or ((Clock >= TIMESTART) and (Jogo.Status <> Testando)) then
              Iniciado = 1
            end if

          elseif .Morreu = 1 then
            Explode (.x, .y, 2)
            .Morreu = 2
            if Jogo.Status = ModoDemo then
              .Morreu = 0
              MudaStatus NoMenu
            end if

          elseif .Morreu > 1 then
            .Morreu = (.Morreu + 1) mod 100
            if .Morreu < 2 then .Morreu = 2

            'Verifica se terminou movimento
            if Tecla <> "" and Tecla <> UltTecla then
              'Zera contadores de ciclos
              Jogo.Ciclo = 0
              Jogo.SeqCiclo = 0

              'Se for teste, apenas reinicia
              if Jogo.Status = Testando then
                LeMinaOUT -1, 0
                Iniciado = 0
                IniciaVida

              'Verifica Game Over
              elseif Boneco.Vidas < 1 then
                MudaStatus GameOver

              'Atualiza número de vidas e reinicia mina e boneco
              else
                'Tira uma vida
                Boneco.Vidas -= 1
                if Mina.Tipo = 0 then
                  LeMinaIn Boneco.Mina
                else
                  LeMinaOUT Boneco.Mina, 0
                end if

                Iniciado = 0
                IniciaVida
              end if
            end if

          'Se não pressionou ESC nem estava morto, verifica se está parado em posição de cair
              '(1-parado; 2-não está na escada; 3-não está sobre objeto que o apoie, ou o objeto de baixo está caindo, ou o objeto de baixo mata)

          elseif Iniciado = 1 and .DirAtual = 0 and .y < Mina.Alt and comport(TpObjeto(objeto(.x, .y).tp).tipo).sobe = 0 and _
                (comport (TpObjeto (objeto (.x, .y + 1).tp).tipo).apoia = 0 or Objeto(.x, .y + 1).caindo = 1 or comport(tpobjeto(Objeto(.x, .y + 1).tp).tipo).mata = 1) then

            'Informa queda, eliminando outros movimentos ou ações (ficam perdidas)
            .DirAtual   = 5
            .UltDir     = 5
            .NaFuradeira  = 0
            .NaPicareta   = 0
            .Passo      = 1
            if comport(tpobjeto(Objeto(.x, .y + 1).tp).tipo).mata = 1 then .morreu = 1

          'Se não está morto, nem pediu pra morrer, nem vai cair, verifica se está usando a picareta
          elseif .NaPicareta > 0 then
            if .NaPicareta mod 3 =1 then
              'midiOutShortMsg (hMidiOut, Som(6, 1).COn1)
              'midiOutShortMsg (hMidiOut, Som(6, 1).COn2)
              Som (6,1).Tempo = 1
            end if

            .NaPicareta += 1
            if .Napicareta >= Jogo.Passos * 2 then
              .NaPicareta = 0
              Objeto(.x, .y + 1).tp = 0
            end if

          'Se não morreu nem pediu, não vai cair nem está usando a picareta, verifica se está usando a furadeira
          elseif .NaFuradeira > 0 then
            .NaFuradeira += 1
            if (.DirFuradeira = 1 and Objeto (.x + 1, .y).caindo = 1)  or (.DirFuradeira = 2 and Objeto (.x - 1, .y).caindo = 1) then
              .Nafuradeira = 0
            end if
            if .NaFuradeira >= Jogo.Passos * 2 then
              if .dirfuradeira=1 then
                Objeto (.x + 1, .y).tp = 0
              else
                Objeto (.x - 1, .y).tp = 0
              end if
              .NaFuradeira = 0
              .VirouFuradeira = 0
            elseif .VirouFuradeira = 0 and .Nafuradeira <= Jogo.Passos then
              if .DirFuradeira = 1 and Tecla = "L" and comport(TpObjeto(Objeto(.x - 1, .y).tp).tipo).destroi = 2 and Objeto(.x - 1, .y).caindo = 0 then
                .VirouFuradeira = 1
                .DirFuradeira = 2
              elseif .dirfuradeira = 2 and tecla = "R" and comport(TpObjeto(Objeto(.x + 1, .y).tp).tipo).destroi = 2 and Objeto(.x + 1, .y).caindo = 0 then
                .viroufuradeira = 1
                .dirfuradeira = 1
              end if
            end if
          'Se não está morto, não pediu, não vai cair, não está usando a picareta nem a furadeira, verifica se está no meio de um movimento e dá sequencia ao mesmo
          elseif Iniciado = 1 and .DirAtual > 0 then
            .Passo += 1

          elseif Iniciado = 1 then

            'Se não morreu nem pediu, não vai cair nem está usando nada, nem está no meio de nenhum movimento, verifica se foi solicitado novo movimento, e se ele é possível
            select case Tecla

            '==========================
            'Tecla para cima
            case "U"
              'Se não está no topo e está em uma escada
              .UltDir = 3
              if .y > 0 and Comport(TpObjeto(Objeto(.x, .y).tp).tipo).sobe = 1 then
                if comport(TpObjeto(Objeto(.x, .y - 1).tp).tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto de cima está livre
                  if Comport(TpObjeto(Objeto(.x, .y - 1).tp).tipo).anda > 0 then
                    'Atualiza direção e inicia movimento
                    .DirAtual = 3
                    .Passo    = 1

                    'Pega e limpa objeto do destino, se for o caso
                    PegaObj .x, .y - 1
                    'Atenção: se 2 posições acima for pedra, vai cair na cabeça!
                  end if
                end if
              end if

            '==========================
            'Tecla para baixo
            case "D"
              'Se não está no fundo
              .UltDir = 5
              if .y < Mina.Alt then
                  if comport(TpObjeto(Objeto(.x, .y + 1).tp).tipo).mata = 1 then
                  .morreu = 1
                else

                  'Se o objeto de baixo for uma escada, então desce
                  if Comport(TpObjeto(Objeto(.x,.y + 1).tp).tipo).sobe = 1 then
                    'Atualiza direção e inicia movimento
                    .DirAtual = 4
                    .UltDir   = 4
                    .Passo    = 1

                  'Se abaixo não for escada, verifica se permite andar
                  elseif comport(TpObjeto(Objeto(.x, .y + 1).tp).tipo).anda > 0 then
                    'Atualiza direção e inicia movimento (queda)
                    .DirAtual = 5
                    .UltDir   = 5
                    .Passo    = 1
                    'Pega e limpa objeto do destino, conforme o caso
                    PegaObj .x, .y + 1
                  end if
                end if
              end if

            '==========================
            'Tecla para esquerda
            case "L"
              .UltDir = 2
              .DirFuradeira = 2
              'Se não está no extremo esquerdo
              if .X > 0 then
                'Verifica se foi na direção de objeto que mata
                if comport(TpObjeto(Objeto(.x - 1, .y).tp).tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto da esquerda permite andar e objeto da esquerda acima não está caindo
                  if comport(TpObjeto(Objeto(.x - 1, .y).tp).tipo).anda > 0 and Objeto (.x - 1, .y - 1).caindo = 0 then
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
                    'midiOutShortMsg (hMidiOut, SomEx(7).COn1)
                    'midiOutShortMsg (hMidiOut, SomEx(7).COn2)
                  end if
                end if
              end if

            '==========================
            'Tecla para Direita
            case "R"
              .UltDir = 1
              .DirFuradeira = 1
              'Se não está no extremo direito
              if .x < Mina.Larg then
                if comport(TpObjeto(Objeto(.x + 1, .y).tp).tipo).mata = 1 then
                  .morreu = 1
                else
                  'Se o objeto da direita permite andar e objeto da direita acima não está caindo
                  if comport(TpObjeto(Objeto(.x + 1, .y).tp).tipo).anda > 0 and Objeto (.x + 1, .y - 1).caindo = 0 then
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
                    'midiOutShortMsg (hMidiOut, SomEx(7).COn1)
                    'midiOutShortMsg (hMidiOut, SomEx(7).COn2)
                  end if
                end if
              end if

            '==========================
            'Usar Suporte
            case "Z"
            if UltTecla <> "Z" then
              if Comport(TpObjeto(Objeto(.x, .y).tp).tipo).apoia = 0 and .ItSuporte > 0 then
                Objeto(.x, .y).tp = 81
                .ItSuporte -= 1
              else
                'midiOutShortMsg (hMidiOut, SomEx(6).COn1)
                'midiOutShortMsg (hMidiOut, SomEx(6).COn2)
                SomEx (6).Tempo = 10
              end if
            end if

            '==========================
            'Usar Picareta
            case "X"
              if UltTecla <> "X" then
                if Comport(TpObjeto(Objeto(.x, .y + 1).tp).Tipo).Destroi = 2 and .ItPicareta > 0 then
                  .ItPicareta -= 1
                  .NaPicareta  = 1
                else
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn1)
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn2)
                  SomEx (6).Tempo = 10
                end if
              end if

            '==========================
            'Usar Furadeira
            case "C"
              if UltTecla <> "C" then
                if .ItFuradeira > 0 and ((Comport(TpObjeto(Objeto(.x - 1, .y).tp).Tipo).Destroi = 2 and Objeto(.x - 1, .y).caindo=0) or (Comport(TpObjeto(Objeto(.x + 1, .y).tp).Tipo).Destroi = 2) and Objeto(.x + 1, .y).caindo = 0) then
                  if .DirFuradeira = 1 and Comport(TpObjeto(Objeto(.x + 1, .y).tp).Tipo).Destroi = 2 and Objeto(.x + 1, .y).caindo = 0 then
                    .DirFuradeira  = 1
                    .ItFuradeira  -= 1
                    .NaFuradeira   = 1
                    .VirouFuradeira  = 0
                    'midiOutShortMsg (hMidiOut, Som(5, comport(tpobjeto(objeto(.x + 1, .y).tp).tipo).som).COn1)
                    'midiOutShortMsg (hMidiOut, Som(5, comport(tpobjeto(objeto(.x + 1, .y).tp).tipo).som).COn2)
                    Som(5, comport(tpobjeto(objeto(.x + 1, .y).tp).tipo).som).Tempo = 16
                  elseif Comport(TpObjeto(Objeto(.x - 1, .y).tp).Tipo).Destroi = 2 and Objeto(.x - 1,.y).caindo = 0 then
                    .DirFuradeira  = 2
                    .ItFuradeira  -= 1
                    .NaFuradeira   = 1
                    .VirouFuradeira  = 0
                    'midiOutShortMsg (hMidiOut, Som(5, comport(tpobjeto(objeto(.x - 1, .y).tp).tipo).som).COn1)
                    'midiOutShortMsg (hMidiOut, Som(5, comport(tpobjeto(objeto(.x - 1, .y).tp).tipo).som).COn2)
                    Som(5, comport(tpobjeto(objeto(.x - 1, .y).tp).tipo).som).Tempo = 16
                  end if
                else
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn1)
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn2)
                  SomEx (6).Tempo = 10
                end if
              end if

            '==========================
            'Aciona bomba pequena
            case "V"
              if UltTecla <> "V" then
                if .Itbombinha > 0 and Comport(TpObjeto(Objeto(.x, .y).tp).Tipo).vazio = 1 then
                  .ItBombinha       -= 1
                  objeto(.x, .y).Tp    = 77
                  objeto(.x, .y).Passo   = 1
                else
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn1)
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn2)
                  SomEx (6).Tempo = 10
                end if
              end if

            '==========================
            'Aciona bomba grande
            case "B"
              if UltTecla <> "B" then
                if .Itbombona > 0 and Comport(TpObjeto(Objeto(.x, .y).tp).Tipo).vazio = 1 then
                  .ItBombona      -= 1
                  objeto(.x,.y).Tp   = 79
                  objeto(.x,.y).Passo  = 1
                else
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn1)
                  'midiOutShortMsg (hMidiOut, SomEx(6).COn2)
                  SomEx (6).Tempo = 10
                end if
              end if

            '==========================
            '****DESATIVAR:::
            'Pula a mina
            case "TAB"
              if ulttecla <> "TAB" and Jogo.Status = Jogando then
                Jogo.SeqCiclo = 0
                MudaStatus VenceuMina
                CalculaBonusTempo
              end if

            end select
          end if

          'Atualizar oxigenio - Se estiver vivo e no momento de atualizar (jogo.Ciclo=0)
          if Iniciado = 1 and Jogo.Ciclo = 0 and .morreu = 0 then
            if (Fundo(.X, .Y) = 0 and (.DirAtual <> 3 or Fundo(.X, .Y - 1) = 0 or .Passo < Jogo.Passos / 2)) or (fundo(.x, .y + 1)=0 and .DirAtual > 3 and .Passo >= Jogo.Passos / 2) then
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
        end with 'Boneco

        'Verifica Movimentação dos Objetos
        '---------------------------------
        if Iniciado = 1 then
          with Boneco
            'Se estiver indo para a direita, faz a leitura ao contrário
            if .diratual = 1 or (.DirAtual = 0 and .UltDir = 1) then
              Emp1 = Mina.Larg
              Emp2 = 0
              Emp3 = -1
            else
              Emp1 = 0
              Emp2 = Mina.Larg
              Emp3 = 1
            end if
          end with

          'Roda todos os objetos verificando-os   (1 a 1)
          for F = Emp1 to Emp2 step Emp3
            for G = Mina.Alt to 0 step -1
              with Objeto(F, G)
                'Verifica se há movimento
                if .Passo > 0 or .empurrando > 0 then
                  'Dá sequencia
                  .Passo += 1
                  if .tp >= 77 and .Tp <= 80 then
                    .Tp = 77 + 2 * int((.tp - 77) / 2) + (.passo mod 2)
                    if .Passo >= Jogo.Passos * 6 then
                      Explode (f, g, int((.tp - 77) / 2) )
                    end if
                  end if

                  'Verifica se é queda e se com esse passo atingiu o boneco, que estava subindo
                  if .Caindo = 1 and Boneco.X = F and Boneco.Y = G + 2 and Boneco.DirAtual = 3 and (Boneco.Passo + .Passo >= Jogo.Passos) then
                    if Boneco.Morreu = 0 then
                      Boneco.Morreu = 1
                      .Passo -= 1
                    end if
                  end if

                  'Verifica se concluiu movimento (exceto bombas)
                  if .Passo = Jogo.Passos and (.tp < 77 or .tp > 80)then
                    'conclui queda
                    if .Caindo = 1 then
                      Objeto(F, G + 1).AntCaindo  = 1 'informa que ciclo terminou, mas era queda
                      Objeto(F, G + 1).Tp     = .Tp
                      Objeto(F, G + 1).Passo    = 0
                      Objeto(F, G + 1).Empurrando = 0
                      Objeto(F, G + 1).Caindo   = 0
                      .AntCaindo  = 0
                      .Passo    = 0
                      .Empurrando = 0
                      .Caindo   = 0
                      .Tp     = 0

                      'Verifica se a queda do objeto terminou, ou seja, chocou-se sobre outro objeto
                      if objeto(f, g + 2).caindo = 0 and comport(tpobjeto(objeto(f, g + 2).tp).tipo).vazio = 0 then
                        Toca(comport(tpobjeto(objeto(f, g + 1).tp).tipo).som, comport(tpobjeto(objeto(f, g + 2).tp).tipo).som) = 1
                      end if
                    end if
                  end if


                'Trata queda de objetos:

                'Verifica se o objeto já estava caindo
                elseif .AntCaindo = 1 then

                  'Verifica se para de cair (cai sobre apoio)
                  if Comport(TpObjeto(Objeto(f, g + 1).Tp).Tipo).Apoia = 1 then
                    .AntCaindo = 0

                  'Verifica se cai sobre o boneco
                  elseif Boneco.Morreu = 0 and (Boneco.Y = G + 1 and ((Boneco.X = F and Boneco.DirAtual < 4 and (Boneco.DirAtual = 0 or Boneco.Passo < int((Jogo.Passos - 1) * .8))) or _
                  (Boneco.X = F - 1 and Boneco.DirAtual = 1) or (Boneco.X = F + 1 and Boneco.DirAtual = 2))) then
                    Boneco.Morreu = 1

                  else  'Se não cai sobre apoio nem sobre o boneco, continua caindo
                    .Caindo = 1
                    .Passo  = 1
                  end if

                'Se não estava caindo, verifica se começa a cair (se não está apoiado por objeto ou pelo boneco)
                elseif Comport(TpObjeto(.tp).Tipo).Cai = 1 and G < Mina.Alt and Comport(TpObjeto(Objeto(F, G + 1).tp).Tipo).Apoia = 0 and _
                Objeto (F - 1,G + 1).Empurrando <> 1 and Objeto (F + 1, G + 1).Empurrando <> 2 then
                  if boneco.morreu = 0 and (Boneco.Y = g + 1 and (Boneco.X = F or (Boneco.X = F - 1 and Boneco.DirAtual = 1) or _
                  (Boneco.X = F + 1 and Boneco.DirAtual = 2))) then
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

        if Iniciado = 0 and mina.tesouros > 0 then
          Desenha
          if Jogo.Status = Testando then
            Mensagem 1, 2, TXT(60), TXT(96), ""
          else
            Mensagem 1, 2, TXT(60), TXT (61) & " . . . " & str(int (TIMESTART - Clock + 1)), ""
          end if
          for F = 0 to 9
            Msg(f).Ciclo = 0
          next
        else
          for f = 1 to 6 'Rotina para gerar o som
            for g = 1 to 4
              if toca(f, g) = 1 then
                'midiOutShortMsg(hMidiOut, Som (f, g).COn1)
                'midiOutShortMsg(hMidiOut, Som (f, g).COn2)
                Som (f, g).Tempo = 8
              end if
            next
          next

          Desenha
        end if
      else
        DesligaSons
      end if
    '-------------------------------------------------------------------------------------------

    case Pausado 'PAUSA NO JOGO

      'desenha fundo e LOGO
      DesFundo
      Mensagem 7, 2, TXT(62), TXT(63), ""
      if tecla <> "" and tecla <> ultTecla then
        Jogo.status = Jogo.StatusAnt
      end if

    '-------------------------------------------------------------------------------------------

    case GameOver 'GAME OVER

      Desenha
      SorteiaNotaGameOver
      if XM < 30 then
        put ( 240 + XM * 3, XM * 8.5), BMP (212), (0, 0) - (112, 28), trans
        put ( 452 - xm * 3, 580- xm * 8.5), BMP (212), (18, 33) - (127, 63), trans
        XM += 1
      elseif XM < 60 then
        put (334 + rnd * (60 - XM), 268+rnd * (60 - XM)), BMP (212), trans
        XM += 1
      elseif XM < 2000 then
        put (334 + rnd * (260-XM)/75, 268 + rnd * (260-XM)/75), BMP (212), trans
        XM += 1
      else
        'midiOutShortMsg (hMidiOut, &H6f0087 Or UltNotaGameOver)
        Tecla = "A"
      end if
      if tecla <> "" and tecla <> ultTecla then
        'midiOutShortMsg (hMidiOut, &H6f0087 Or UltNotaGameOver)
        PosTop10 = VerificaRecorde ()
        if PosTop10 > 0 then
          MudaStatus Top10
        else
          MudaStatus NoMenu
        end if
        IniciaJogo
        IniciaVida
        TTDemo1 = Clock
        VRed=int(rnd*2)
        VGreen=int(rnd*2)
        VBlue=int(rnd*2)
        if VRed+VGreen+VBlue=0 then VBlue=1
      end if

    '-------------------------------------------------------------------------------------------

    case ModoMapa 'Modo de MAPA

      select case Tecla
      case "U"
        MapY -= 1
        if MapY < 0 then MapY = 0
      case "D"
        MapY += 1
        if MapY > Mina.Alt - 16 then MapY -= 1
      case "R"
        Mapx += 1
        if MapX > Mina.Larg - 24 then MapX -= 1
      case "L"
        MapX -= 1
        if MapX < 0 then MapX = 0
      case ""
        'Não faz nada
      case else
        if UltTecla <> Tecla then Jogo.Status = Jogo.StatusAnt
      end select

      'Verifica se acabou o tempo
      if (jogo.SeqCiclo mod 5=0) and (jogo.Ciclo=0) and (iniciado > 0) and (boneco.morreu = 0) then
        boneco.Tempo += 1
        if (boneco.tempo>=mina.tempo) and (mina.tempo>0) then
          boneco.morreu = 1
          Jogo.status = Jogo.StatusAnt
        end if
      end if

      Desenha
      line(2,551)-(545,596),point(2,551),b
      line(3,552)-(544,595), point(3,552),b
      line(4,553)-(543,594), point(4,553),b
      line (5,554)-(542,593),point(5,554),bf
      line(2,597)-(545,597),point(2,597)
      line(110,554)-(110,593),point(2,551)
      Escreve TXT(64), 10, 560, 0, 0
      Escreve TXT(65), 127, 552, 0, 0
      Escreve TXT(66), 115, 572, 0, 0
      if int (Clock * 10) mod 5 <=2 then
        Mensagem 2, 0, TXT(64), "", "", 750 - LargTexto (txt(64), 1)/2, 500
      end if

    '-------------------------------------------------------------------------------------------

    case Instruc 'FreeBasic Miner?

      DesFundo
      line (0, 565) - (799, 599), rgb(48 * VRed, 48 * VGreen, 48 * VBlue), BF

      if (ulttecla <> tecla and Tecla <>"") or (MouseDisparou = 1) then
        MudaStatus NoMenu
        Jogo.Ciclo=0
        Jogo.SeqCiclo=0
      end if

      PutLogo 290, 40
      EscreveCentro TXT(67), 570, 1, 1
      EscreveCentro TXT(68), 150
      EscreveCentro TXT(69), 180
      EscreveCentro TXT(70), 210
      EscreveCentro TXT(71), 240
      EscreveCentro TXT(72), 270
      EscreveCentro TXT(73), 305
      EscreveCentro TXT(74), 340,1
      put (370,430), BMP(252), trans
      EscreveCentro TXT(75), 480, 1, 1

    '-------------------------------------------------------------------------------------------

    case VenceuMina 'CONCLUIU A MINA

      Desenha
      if Jogo.StatusAnt = Testando then
        F = PerguntaSeEncerraTeste
      else
        if mina.Tipo = 0 then
          if Boneco.Mina < Jogo.NumMinas then
            Mensagem 2, 6, TXT(76), TXT(77) & ": " & str(PtBonus), ""
          else
            Mensagem 2, 6, TXT(76), TXT(77) & ": " & str(PtBonus), TXT(94) & ": " & str(boneco.Vidas) & " x 1000 = " & str(boneco.vidas * 1000)
          end if
        else
          Mensagem 2, 6, TXT(78), TXT(77) & ": " & str(PtBonus), TXT(79) & str(Boneco.Pontos + PtBonus)
        end if
        if tecla <> "" and tecla <> ultTecla then
          if mina.Tipo = 0 then
            if Boneco.Mina = Jogo.NumMinas then
              MudaStatus VenceuJogo
              QtdNotasVenceu = 0
              UltNotaGameOver = 0
              Jogo.SeqCiclo =- 1
            else
              Boneco.Mina +=1
              if Boneco.Mina > Jogo.MaxAlcancada then
                Jogo.MaxAlcancada  = Boneco.Mina
                RegravaConfig
              end if
              IniciaVida
              MudaStatus Jogando
              LeMinaIn Boneco.Mina
              Iniciado=0
              TIMESTART = Clock + 5
            end if
            Boneco.Pontos += PtBonus
            if Boneco.Mina = Jogo.NumMinas then Boneco.Pontos += Boneco.Vidas * 1000
          else
            MudaStatus NoMenu
          end if
        end if
      end if
    '-------------------------------------------------------------------------------------------

    case VenceuJogo 'VENCEU O JOGO

      for f=0 to 19
        g=int(rnd*100)
        h=int(rnd*60)
        Frente (g,h)=0
        Fundo (g,h)=1
        objeto (g,h).tp = 40 + int(rnd*16)
      next

      SorteiaNotaVenceu

      Desenha
      jogo.Ciclo=jogo.passos-1
      Mensagem 0, 12, TXT(80), TXT(81), ""
      if tecla <> "" and tecla <> ultTecla then
        'midiOutShortMsg (hMidiOut, &H6f0080 Or UltNotaGameOver)
        'midiOutShortMsg (hMidiOut, &H5f0080 Or (UltNotaGameOver + 513))
        PosTop10 = VerificaRecorde()
        if PosTop10 > 0 then
          MudaStatus Top10
        else
          MudaStatus NoMenu
        end if
        IniciaJogo
        IniciaVida
        LimpaMina
        TTDemo1 = Clock
        VRed=int(rnd*2)
        VGreen=int(rnd*2)
        VBlue=int(rnd*2)
        if VRed+VGreen+VBlue=0 then VBlue=1
        Jogo.SeqCiclo=0
      end if

    '-------------------------------------------------------------------------------------------

    case Top10 'TOP 10

      DesFundo

      DesBox 14, 11, 3, 400, 310

      'Logo
      PutLogo 290, 40

      'Opções:
      EscreveCentro "Top 10", 140, 2, 1

      for f = -1 to 9
        line(197, 200 + f * 30) - step (394, 0), rgb (128, 128, 128)
      next

      if PosTop10 > 0 then
        line(187, 175 + (PosTop10 - 1) * 30) - step (413, 31), rgb (80 + 80 * VRed, 80 + 80 * VGreen, 80 + 80 * VBlue), bf
        line(190, 178 + (PosTop10 - 1) * 30) - step (407, 25), rgb (48 + 48 * VRed, 48 + 48 * VGreen, 48 + 48 * VBlue), bf
      end if

      for f=0 to 9
        g = len (Toppt(f).nome)
        while LargTexto (left(Toppt(f).nome, g), 1) > 399 - ((largTexto ("0",1)+2) * (1+len (str(Toppt(f).Pontos))))
          g -= 1
        wend
        Escreve left(toppt(f).nome, g), 198, 180 + f * 30, 1, 0
        Escreve str(toppt (f).pontos), 602 - ((largTexto ("0",1) +2)* ( 1 + len (str(Toppt(f).Pontos)))), 180 + f * 30, 1, 0
      next

      if ConfirmDel = 0 then
        EscreveCentro TXT(82), 520, 1, 0
      elseif ConfirmDel = 1 then
        Mensagem 1, 5, TXT(83), TXT(84), "", , , Opcao1
      elseif ConfirmDel = 2 then
        Mensagem 0, 5, TXT(90), TXT(91), "", , , Opcao1
      end if

      if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1

      if (Tecla <> UltTecla and Tecla <> "") or (MouseDisparou = 1) then
        if ConfirmDel = 0 then
          if Tecla = "<" then
            ConfirmDel = 1
            Opcao1 = 1
          else
            PosTop10 = 0
            MudaStatus NoMenu
          end if
        else
          if Tecla = "ESC" then
            ConfirmDel = 0
          elseif (Tecla = "U") or (Tecla = "D") or (Tecla = "R") or (Tecla = "L") then
            Opcao1 = 1 - Opcao1
          elseif (Tecla ="[") or (Tecla = "]") or (MouseDisparou = 1) then
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
                Jogo.MaxAlcancada = 1
                RegravaConfig
                ConfirmDel = 0
              else
                ConfirmDel = 0
              end if
            end select
          end if
        end if
      end if

    '-------------------------------------------------------------------------------------------

    case Editor

      Edita
      if Jogo.Status = Editor then Desenha

    '-------------------------------------------------------------------------------------------

    end select

    'Calcula e mostra FPS
    Quadros += 1
    Timer2 = Clock
    'Escreve Right ("0000" + str(UltQuadros), 4) , 0, 0, 1, 1
    if int(Timer2) <> int (timer1) then
      timer1 = Timer2
      UltQuadros = Quadros
      Quadros = 0
    end if

    'FLIP + temporizador
    TrocaTelas

TerminaCiclo:
  wend
  DEBUG_LOG("End of the game procedure")
end sub

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------

'Boneco recolhe pedras ou outros objetos

sub PegaObj (POX as integer, POY as integer)
  with boneco
    select case TpObjeto (Objeto(POX,POY).TP).Item
    case 1
      .ItOxigenio+=1
      'midiOutShortMsg (hMidiOut, SomEx(4).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(4).COn2)
      SomEx (4).Tempo = 10
    case 2
      .ItSuporte+=1
      'midiOutShortMsg (hMidiOut, SomEx(4).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(4).COn2)
      SomEx (4).Tempo = 10
    case 3
      .ItPicareta+=1
      'midiOutShortMsg (hMidiOut, SomEx(4).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(4).COn2)
      SomEx (4).Tempo = 10
    case 4
      .ItFuradeira+=1
      'midiOutShortMsg (hMidiOut, SomEx(4).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(4).COn2)
      SomEx (4).Tempo = 10
    case 5
      .ItBombinha+=1
      'midiOutShortMsg (hMidiOut, SomEx(4).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(4).COn2)
      SomEx (4).Tempo = 10
    case 6
      .ItBombona+=1
      'midiOutShortMsg (hMidiOut, SomEx(4).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(4).COn2)
      SomEx (4).Tempo = 10
    'Recolhe tesouros:
    case 7 to 22
      'midiOutShortMsg (hMidiOut, SomEx(5).COn1)
      'midiOutShortMsg (hMidiOut, SomEx(5).COn2)
      SomEx (5).Tempo = 10
      VeSeGanhaVida PontoTesouro(TpObjeto (Objeto(POX, POY).TP).Item)
      MarcaPt (PontoTesouro(TpObjeto (Objeto(POX, POY).TP).Item), POX, POY)
      .Pontos += PontoTesouro(TpObjeto (Objeto(POX, POY).TP).Item)
      Mina.Tesouros -= 1
      if Mina.Tesouros = 0 then
        Jogo.SeqCiclo = 0

        if jogo.status = Jogando or Jogo.Status = Testando then 'Termina a fase
          Jogo.StatusAnt = Jogo.Status
          MudaStatus VenceuMina
          CalculaBonusTempo

        else 'Termina a demonstração
          MudaStatus NoMenu
          VRed = int(rnd*2)
          VGreen = int(rnd*2)
          VBlue = int(rnd*2)
          if VRed + VGreen + VBlue = 0 then VBlue = 1
        end if

      end if
    end select

  end with

  'Limpa o objeto
  if Objeto(POX, POY).Tp <77 or Objeto(POX, POY).Tp > 80 then
    if Comport(TpObjeto(Objeto(POX, POY).Tp).Tipo).Anda=1then
      Objeto(POX,POY).Tp=0
    end if
    Objeto(POX,POY).Caindo=0
    Objeto(POX,POY).AntCaindo=0
    Objeto(POX,POY).Empurrando=0
    Objeto(POX,POY).Passo=0
  end if
end sub

'-------------------------------------------------------------------------------------------

'Verifica possibilidade e inicia o empurrar de objetos

function EmpurraObj (byval POX as integer, byval POY as integer, byval MDir as integer, byval Peso as integer, byval Quant as integer) as integer
  dim as integer Resultado, XR, PesoTemp
  Resultado= Comport(TpObjeto(objeto(POX, POY).Tp).Tipo).PEmpurra
  XR= 3 - (MDir * 2)

  'Antes, verifica se o objeto não está caindo nem vai começar a cair agora
  if (Comport(TpObjeto(Objeto(POX, POY).tp).Tipo).Cai =1 and POY < Mina.Alt and Comport(TpObjeto(Objeto(POX, POY+1).tp).Tipo).Apoia=0) or Objeto (POX, POY).Caindo=1 then
    Resultado=5
  else

    'Só faz verificação se ainda não tiver chegado ao canto da mina
    if POX >0 and POX < Mina.Larg then
      if Resultado + Peso > 2 then
        Resultado = 3

      elseif Resultado = 2 then
        if Quant=1 and Comport(TpObjeto(objeto(POX + XR, POY).Tp).Tipo).Vazio=1 and Objeto(POX + XR, POY - 1).caindo=0 then
          Resultado = 2
        else
          Resultado = 3
        end if

      elseif Resultado =1 then
        if Quant=1 then
          if Comport(TpObjeto(objeto(POX + XR, POY).Tp).Tipo).Vazio=1 and Objeto(POX + XR, POY - 1).caindo=0 then
            Resultado=1
          else
            PesoTemp = EmpurraObj (POX + XR, POY, MDir, 1, 2)
            if PesoTemp <= 1 then
              Resultado = PesoTemp + 1
            else
              Resultado = 3
            end if
          end if

        elseif quant = 2 and peso < 2 then
          if Comport(TpObjeto(objeto(POX + XR, POY).Tp).Tipo).Vazio=1 and Objeto(POX + XR, POY - 1).caindo=0 then
            Resultado = 1
          else
            Resultado = 3
          end if
        else
          Resultado = 3
        end if

      elseif Resultado =0 then
        if Peso > 0 and Quant >2 then
          Resultado = 3
        else
          if Comport(TpObjeto(objeto(POX + XR, POY).Tp).Tipo).Vazio=1 and Objeto(POX + XR, POY - 1).caindo=0 then
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
    Objeto(POX,POY).Empurrando = MDir
    Objeto(POX,POY).Passo = 0
  end if

  return Resultado
end function

'-------------------------------------------------------------------------------------------

'Inicia uma explosao (bomba ou morte do boneco)

sub Explode (byval EXX as integer, byval EXY as integer, byval XTam as integer)
  dim as integer LF, LG, NTam
  NTam=XTam
  'midiOutShortMsg (hMidiOut, SomEx(XTam+1).COn1)
  'midiOutShortMsg (hMidiOut, SomEx(XTam+1).COn2)
  SomEx (XTam+1).Tempo = 16

  if XTam=2 then XTam=1
  Objeto (EXX, EXY).tp = 0
  for LF = -1 to 1
    for lg = -XTam to XTam
      with Objeto(EXX+LF,EXY+LG)
        if .Tp >=77 and .Tp<=80 then
          Explode (EXX+LF, EXY+LG, int((.tp-77)/2))
        elseif Comport(TpObjeto(.Tp).Tipo).Destroi>0 then
          .Tp=0
        end if
      end with
    next
  next

  with Boneco
    if .morreu=0 and .x >= EXX-2 and .X <=EXX+2 then
      if (.X =EXX-2 and .DirAtual=1 and .Passo>=jogo.Passos * .4) or (.X=EXX-1 and (.dirAtual<>2 or .Passo<=Jogo.Passos * .6)) or .x=EXX or (.x=EXX+1 and (.diratual<>1 or .Passo<=Jogo.Passos * .6)) or (.X =EXX+2 and .DirAtual=2 and .Passo>=jogo.Passos * .4) then
        if XTam=0 then
          if (.Y =EXY-1 and .DirAtual>3 and .Passo>=jogo.Passos * .4) or (.Y=EXY and (.dirAtual<3 or .Passo<=Jogo.Passos * .6)) or (.Y =EXY+1 and .DirAtual=3 and .Passo>=jogo.Passos *.3) then .Morreu=1
        else
          if (.Y =EXY-2 and .DirAtual>3 and .Passo>=jogo.Passos * .4) or (.Y=EXY-1 and (.dirAtual<>3 or .Passo<=Jogo.Passos * .6)) or .Y=EXY or (.Y=EXY+1 and (.diratual<4 or .Passo<=Jogo.Passos * .6)) or (.Y =EXY+2 and .DirAtual=3 and .Passo>=jogo.Passos * .4) then .Morreu=1
        end if
      end if
    end if
  end with

  Jogo.UltExplosao = (Jogo.UltExplosao + 1) mod 11
  with Explosao(Jogo.UltExplosao)
    .X=EXX
    .Y=EXY
    .Tipo=XTam+1
    .Tempo=1
  end with

end sub


'-------------------------------------------------------------------------------------------

'Esvazia o conteúdo da matriz da mina

sub LimpaMina
  dim as integer F, G
  for f = -1 to 100
    for g = -1 to 60
      Frente (f, g) = 0
      Fundo (f, g) = 1
      Objeto (f, g).tp = 0
      Objeto (f, g).Caindo = 0
      Objeto (f, g).AntCaindo = 0
      Objeto (f, g).Empurrando = 0
      Objeto (f, g).Passo = 0
    next
  next
  Mina.Larg = 99
  Mina.Alt = 59
  Mina.X = 0
  Mina.Y = 0
  Boneco.X = 0
  Boneco.Y = 0
  MAPX = 0
  MAPY = 0
end sub

'-------------------------------------------------------------------------------------------

'Reinicia tabela de recordes

sub LimpaTopDez
  dim as integer F
  kill "top10.min"
  MontaTopDez
  open "top10.min" for output as #1
  for f=0 to 9
    print #1, toppt(f).nome; ", " ; str(toppt(f).pontos)
  next
  close #1
end sub

'-------------------------------------------------------------------------------------------

'Verifica se está entre os TOP 10, solicita nome e inclui na tabela

function VerificaRecorde as integer
  dim as integer F
  dim Posit as integer
  dim TecX as string
  Posit = 10
  for F = 9 to 0 step -1
    if Boneco.pontos > TopPt(f).Pontos then Posit = F
  next
  if Posit < 10 then
    for f = 9 to Posit step -1
      TopPt(f+1).Pontos = TopPt(f).Pontos
      TopPt(F+1).Nome = TopPt(f).Nome
    next
    TopPt(Posit).Pontos = Boneco.Pontos
    LimpaTeclado
    TecX=""

    while TecX <> chr(13)
      TecX=inkey
      if len(TecX)>0 then
        if instr(" " + Lt_, TecX)>0 and len (Boneco.nome) < 20 and TecX <> "," then Boneco.Nome += TecX
        if tecx=chr(8) or tecx=chr(255)+chr(83) and len(boneco.nome)>0 then boneco.nome=left(boneco.nome, len(boneco.nome)-1)
      end if
      DesFundo
      Mensagem 4, 10, TXT(85), TXT(86), "", , 220
      if boneco.nome="" then
        Mensagem 2, 10, " ", chr (32 + 63 * (int(Clock * 2) mod 2)), " ",, 360
      else
        Mensagem 2, 10, " ", boneco.nome & chr (32 + 63 * (int(Clock * 2) mod 2)), " ",, 360
      end if
      TrocaTelas
    wend
    cls
    UltTecla = "["
    Tecla = "["
    if boneco.nome="" then boneco.nome="?"
    TopPt(Posit).Nome=boneco.nome

    LimpaTeclado

    kill "top10.min"
    open "top10.min" for output as #1
    for f=0 to 9
      print #1, toppt(f).nome; ", " ; str(toppt(f).pontos)
    next
    close #1
  end if

  if Posit < 10 then return (Posit + 1) else return 0

end function

'-------------------------------------------------------------------------------------------

'Le a tabela dos TOP 10

sub LeTopDez
  dim as integer F
  'Lê Top10. Se não houver, reinicia recordes
  if fileexists("top10.min") then
    open "top10.min" for input as #1
    for f=0 to 9
      input #1, TopPt(f).nome, TopPt(f).pontos
    next
    close #1
  else
    MontaTopDez
  end if
end sub

'-------------------------------------------------------------------------------------------

'Reinicia tabela de TOP 10

sub MontaTopDez
  TopPt(0).nome = "Top1" : TopPt(0).pontos = 15000
  TopPt(1).nome = "Top2" : TopPt(1).pontos = 12500
  TopPt(2).nome = "Top3" : TopPt(2).pontos = 10000
  TopPt(3).nome = "Top4" : TopPt(3).pontos =  9000
  TopPt(4).nome = "Top5" : TopPt(4).pontos =  8000
  TopPt(5).nome = "Top6" : TopPt(5).pontos =  7000
  TopPt(6).nome = "Top7" : TopPt(6).pontos =  5000
  TopPt(7).nome = "Top8" : TopPt(7).pontos =  4000
  TopPt(8).nome = "Top9" : TopPt(8).pontos =  3000
  TopPt(9).nome = "Top10" : TopPt(9).pontos = 2000
end sub


'-------------------------------------------------------------------------------------------

'Faz a troca de screens e ajusta o FPS

sub TrocaTelas
  dim as integer tempo, Falta

  screenset 1 - ScrAtiva,  ScrAtiva
  ScrAtiva = 1 - ScrAtiva

  'Ajuste FPS
  ATimer = NTimer
  NTimer = int(Clock * 1000)
  Falta = 1
  Tempo = NTimer - ATimer
  Falta = Jogo.DelayMSec - Tempo
  if Falta < 1 then Falta = 1
  if multikey(SC_LSHIFT) or multikey(SC_RSHIFT) then
    sleep 1, 1
  else
    sleep Falta, 1
  end if
 end sub

'-------------------------------------------------------------------------------------------

'Manda desenhar o quadro e escreve as mensagens

sub Mensagem (QCor as integer, Tipo as integer, T1 as string, T2 as string, T3 as string, OX as integer = 400, OY as integer= 300, Opcao as integer = 0)

'Tipos:
'0-Sem ícone + pressiona qq tecla
'1-Sem ícone + Sim / Não
'2-Exclamação + Pressiome qq tecla
'3-Exclamação + Sim / Não
'4-Interrogação + pressiona qq tecla
'5-Interrogação + Sim / Não
'6-Ok + pressiona qq tecla
'7-Ok + Sim / Não
'8-Dame + pressiona qq tecla
'9-Dame + Sim / Não
'10-Medalha + pressiona qq tecla
'12-ByNIZ + pressiona qq tecla

  dim as integer Larg, Alt, V, F
  dim as string Tex (2)

  if T2 = "" then
    Alt = 1
  elseif T3 = "" then
    Alt = 2
  else
    Alt = 3
  end if
  V = Alt

  Tex(0) = T1
  Tex(1) = T2
  Tex(2) = T3

  Larg = 10
  for F = 0 to 2
    if LargTexto (Tex (f), - (f = 0)) > Larg then Larg = LargTexto (Tex (f), - (f = 0))
  next

  Larg = int (Larg / 32) + 1
  if Tipo > 1 then Larg += 2
  if (Tipo mod 2 = 1) and (Larg < 7) then Larg = 7
  if Tipo mod 2 = 1 then Alt += 2
  if Tipo > 1 and Alt < 2 then Alt = 2

  DesBox Larg, Alt, QCor, OX, OY
  for F = 0 to V - 1
    Escreve Tex(F), OX - 24 * (Tipo > 1) - LargTexto(Tex(F), - (f = 0)) /2  , OY - Alt * 16 + F * 32 + 4, - (f = 0), 0
  next
  if Tipo > 1 then put (OX - Larg * 16, OY - Alt * 16), BMP (252 + int(Tipo / 2)),trans

  MouseSimNao = 0

  if Tipo mod 2 = 1 then
    put (OX - 66 + Opcao * 76, Oy + Alt * 16 - 38), BMP (276), (576, 0) - (630, 32), trans
    put (OX + 10 - 76 * Opcao, Oy + Alt * 16 - 38), BMP (276), (576, 33) - (630, 65), trans
    Escreve TXT(58), OX - 38 - LargTexto (TXT (58), 0)/2, Oy + Alt * 16 - 32, 0, 0
    Escreve TXT(59), OX + 38 - LargTexto (TXT (59), 0)/2, Oy + Alt * 16 - 32, 0, 0
    put (OX - 66 + Opcao * 76, Oy + Alt * 16 - 40), BMP (276), (576, 66) - (630, 102), trans
    if (MouseY > OY + Alt * 16 - 39) and (MouseY < Oy + Alt * 16 - 4) then
      if MouseX > OX - 67 and MouseX < OX - 9 then MouseSimNao = 1
      if MouseX > OX + 9 and MouseX < OX + 67 then MouseSimNao = 2
    end if
  end if

end sub

'-------------------------------------------------------------------------------------------

'Desenha o quadro (para mensagens)

sub DesBox (H as integer, V as integer, QCor as integer, OX as integer = 400, OY as integer = 300)
  dim as integer F, G
  if QCor < 4 then
    put (OX - 16 - H * 16, OY - 16 - V * 16), BMP (248 + QCor), (0, 0) - step (15, 15), alpha
    put (OX - 16 - H * 16, OY + V * 16), BMP (248 + QCor), (0, 48) - step (15, 15), alpha
    put (OX + H * 16, OY - 16 - V * 16), BMP (248 + QCor), (48, 0) - step (15, 15), alpha
    put (OX + H * 16, OY + V * 16), BMP (248 + QCor), (48, 48) - step (15, 15), alpha
    for F = 0 to H - 1
      put (OX - H * 16 + F * 32, OY - 16 - V * 16), BMP (248 + QCor), (16, 0) - step (31, 15), alpha
      put (OX - H * 16 + F * 32, OY + V * 16), BMP (248 + QCor), (16, 48) - step (31, 15), alpha
      for G = 0  to V - 1
        put (OX - H * 16 + F * 32, OY - V * 16 + G * 32), BMP (248 + QCor), (16, 16) - step (31, 31), alpha
      next
    next
    for G = 0  to V - 1
      put (OX - 16- H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (0, 16) - step (15, 31), alpha
      put (OX + H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (48, 16) - step (15, 31), alpha
    next
  else
    QCor -= 4
    put (OX - 16 - H * 16, OY - 16 - V * 16), BMP (248 + QCor), (0, 0) - step (15, 15), trans
    put (OX - 16 - H * 16, OY + V * 16), BMP (248 + QCor), (0, 48) - step (15, 15), trans
    put (OX + H * 16, OY - 16 - V * 16), BMP (248 + QCor), (48, 0) - step (15, 15), trans
    put (OX + H * 16, OY + V * 16), BMP (248 + QCor), (48, 48) - step (15, 15), trans
    for F = 0 to H - 1
      put (OX - H * 16 + F * 32, OY - 16 - V * 16), BMP (248 + QCor), (16, 0) - step (31, 15), trans
      put (OX - H * 16 + F * 32, OY + V * 16), BMP (248 + QCor), (16, 48) - step (31, 15), trans
      for G = 0  to V - 1
        put (OX - H * 16 + F * 32, OY - V * 16 + G * 32), BMP (248 + QCor), (16, 16) - step (31, 31), trans
      next
    next
    for G = 0  to V - 1
      put (OX - 16- H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (0, 16) - step (15, 31), trans
      put (OX + H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (48, 16) - step (15, 31), trans
    next
  end if
end sub

'-------------------------------------------------------------------------------------------

'Desenha o LOGO do game

sub PutLogo (LX as integer, LY as integer)
  put (LX, LY), BMP (211), trans
end sub

'-------------------------------------------------------------------------------------------

function CTRX as integer
  with Boneco
    if .X < 12 then
      return .X * 32 + 16
    elseif .X > Mina.Larg - 12 then
      return 784 - (Mina.LArg - .X) * 32
    else
      return 399
    end if
  end with
end function

'-------------------------------------------------------------------------------------------

function CTRY as integer
  with Boneco
    if .Y < 8 then
      return .Y * 32 + 16
    elseif .Y > Mina.Alt - 8 then
      return 500 - (Mina.Alt - .Y) * 32
    else
      return 240
    end if
  end with
end function

'-------------------------------------------------------------------------------------------

sub MarcaPt (Pontos as integer, X as integer, Y as integer)
  with  MSG (ProxMsg)
    .Ciclo = 63
    .Pontos = Pontos
    .X = X
    .Y = Y
  end with
  ProxMsg = (ProxMsg + 1) mod 10
end sub

'-------------------------------------------------------------------------------------------

'Simula pressionamento de teclas no modo demo

function ProximaTeclaDemo as string
  dim TecTemp as string
  dim as integer ValTemp, BX, BY

  BX = Boneco.X
  BY = Boneco.Y
  if Boneco.Passo = Jogo.Passos then
    select case boneco.DirAtual
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
  if PositDemo > len (TeclasDemo)/3 then
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
          Boneco.DirFuradeira = 1
        elseif mid(teclasdemo, positdemo * 3 + 3, 1) = "L" then
          Boneco.DirFuradeira = 2
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

'-------------------------------------------------------------------------------------------

'Le mina do arquivo (padrão)

sub LeMinaIn (NMina as integer, SoQuant as integer = 0)
  dim as longint FilePos, FileTam
  dim as ushort MinaTemp, TotMinas
  dim as ubyte Temporary1
  randomize

  LimpaMina

  'zera contador de tesouros para iniciar a contagem
  Mina.Tesouros = 0

  'Abre arquivo

  'Verifica se o arquivo existe
  if fileexists ("minas.bin") then
    open "minas.bin" for binary as #1
    FileTam = lof (1)
    if FileTam > 20 then
      get #1, , TotMinas
      Jogo.NumMinas = TotMinas

      FilePos = 3

      if SoQuant = 0 then

        get #1, , MinaTemp
        get #1, , Mina.LArg
        get #1, , Mina.Alt
        get #1, , Mina.Noturno
        get #1, , Mina.Tempo

        while MinaTemp < NMina
          FilePos = FilePos + ((Mina.Alt * Mina.Larg) * 3) + 9
          get #1, FilePos, MinaTemp
          get #1, , Mina.LArg
          get #1, , Mina.Alt
          get #1, , Mina.Noturno
          get #1, , Mina.Tempo
        wend

        LeMinaDet 0

      end if
    else
      'MessageBox NULL,TXT(87), TXT(0), MB_ICONERROR
      print TXT(87), TXT(0)
      MudaStatus NoMenu
    end if

    close #1

  else  'Arquivo não existe
    'MessageBox NULL, TXT(88), TXT(0), MB_ICONERROR
    print TXT(88), TXT(0)
    MudaStatus NoMenu
  end if
end sub

'-------------------------------------------------------------------------------------------

'Le o desenho da mina (tiles)

sub LeMinaDet (Editando as integer = 0)
  dim as integer MXR, MYR, F, G
  MXR=0
  MYR=0

  if Editando = 0 then
    if Mina.Larg < 24 then MXR = int (25 - Mina.Larg) / 2
    if Mina.alt < 16 then MYR = int(17 - Mina.Alt) / 2
    for f = -1 to mina.larg
      for g = -1 to mina.alt
        objeto(mxr + f, myr + g).tp = 31
      next
    next
  end if

  Mina.Larg -= 1
  Mina.Alt -= 1

  'Lê cada linha
  for g = 0 to Mina.Alt
    'Le linha
    for f = 0 to Mina.Larg
      get #1, , Fundo (MXR + f, MYR + g)
      get #1, , Frente (MXR + f, MYR + g)
      get #1, , Objeto (MXR + f, MYR + g).tp
      'Posição inicial do boneco
      if objeto (MXR + f, MYR + g).tp = 85 then
        Mina.X = MXR + F
        Mina.Y = MYR + G
        Boneco.X = Mina.X
        Boneco.Y = Mina.Y
        Objeto(MXR + f, MYR + g).tp = 0
      elseif tpobjeto(Objeto (MXR+f,MYR+g).Tp).Tipo=5 then
        Mina.Tesouros +=1
      end if
    next
  next
  sleep 1, 1
  Mina.Larg += MXR
  Mina.Alt += MYR
  Jogo.UltExplosao = 0
  Jogo.Ciclo=0
  Iniciado=0
end sub

'-------------------------------------------------------------------------------------------

'Faz levantamento e contagem das minas personalizadas

sub LeMinasPers
  dim as string Narq
  dim as integer Ordem, F
  screenset ScrAtiva,  ScrAtiva
  Ordem = 0

  line (298, 320) - (502, 344), &HFFFFFF, b

  for F = 0 to 999
    line (300 + f/5, 322) - step (0, 20), &H7080F0
    NArq = "minas/m" + right("000" & str(f), 3) + ".map"
    if fileexists (Narq) then
      MinaPers (Ordem) = F
      Ordem +=1
    end if
  next
  if Ordem < 999 then
    for F = Ordem to 999
      MinaPers (f) = 0
    next
  end if
  Boneco.Mina = MinaPers (0)
  QuantPers = Ordem
end sub

'-------------------------------------------------------------------------------------------

'Gera um som aleatório (Game Over)

sub SorteiaNotaGameOver
  dim Nota as integer

  randomize

  if Jogo.Status <> GameOver or (rnd * 500) < 10 then
    Nota = (int(rnd * 32) + 64) shl 8
    'midiOutShortMsg (hMidiOut, &H65c7)
    'midiOutShortMsg (hMidiOut, &H600087 Or UltNotaGameOver)
    'midiOutShortMsg (hMidiOut, &H600097 Or Nota)
    UltNotaGameOver = Nota
  end if
end sub

'-------------------------------------------------------------------------------------------

'Gera um som aleatório (Vencendo o jogo)

sub SorteiaNotaVenceu
  dim Nota as integer

  randomize

  if (QtdNotasVenceu = 0) or (QtdNotasVenceu < 6 and Clock - TimerNotaVenceu >= .11) then
    QtdNotasVenceu += 1
    if QtdNotasVenceu = 1 then
      Nota = (int(rnd * 32) + 36) shl 8
    else
      Nota = (int(rnd * 6) + (UltNotaGameOver shr 8) - 1) shl 8
      if Nota = ultNotaGameOver then Nota -= 512
    end if
    'midiOutShortMsg (hMidiOut, &H76c0)  '26, 29, 2d, 6b
    'midiOutShortMsg (hMidiOut, &H6bc1)  '26, 29, 2d, 6b
    'midiOutShortMsg (hMidiOut, &H5f0080 Or (UltNotaGameOver + 513))
    'midiOutShortMsg (hMidiOut, &H6f0080 Or UltNotaGameOver)
    'midiOutShortMsg (hMidiOut, &H600090 Or (Nota + 513))
    'midiOutShortMsg (hMidiOut, &H6f0090 Or Nota)
    UltNotaGameOver = Nota
    TimerNotaVenceu = Clock
  elseif Clock - TimerNotaVenceu >= .6 then
    QtdNotasVenceu = 0
  end if
end sub


'-------------------------------------------------------------------------------------------

'Regrava configurações: Volume e maior mina alcançada

sub RegravaConfig

  kill "config.min"
  open "config.min" for output as #1
  print #1, jogo.volume
  print #1, Jogo.MaxAlcancada
  print #1, IAtual
  close #1
end sub

'-------------------------------------------------------------------------------------------

'Le textos do programa, no idioma selecionado

function LeTXT (Idioma as string) as integer
  dim as integer F
  if fileexists ("lang/" + idioma + ".lng") then
    open "lang/" + idioma + ".lng" for input as #1
    F = 0
    while not eof (1)
      input #1, TXT(F)
      F += 1
    wend
    close #1
    return 0
  else
    return 1
  end if
end function

'-------------------------------------------------------------------------------------------

'Define os textos, em português

sub ProcIdiomas ()
  dim as string Arquivo
  dim as integer F

  'Conta e carrega matriz com idiomas disponíveis
  IQuant = 0
  Arquivo = dir ("lang/*.lng")
  while len(Arquivo) > 0 and IQuant < 9
    
    Idioma (IQuant) = left(Arquivo, len(Arquivo) - 4)
    IQuant += 1
    Arquivo = dir ()
  wend

  'Localiza idioma atual na matriz
  NAtual = 0
  for f = 0 to IQuant
    if Idioma (F) = IAtual then NAtual = F
  next

end sub

'-------------------------------------------------------------------------------------------

'Verifica se é pra ganhar vida

sub VeSeGanhaVida (Acrescimo as integer)
  if int(boneco.pontos / 1000) < int ((boneco.Pontos + Acrescimo) / 1000) then
    Boneco.vidas += 1
  end if
end sub

'-------------------------------------------------------------------------------------------

'Calcula o bonus de acordo com o tempo para concluir a mina

sub CalculaBonusTempo
  if Mina.Tempo = 0 then
    PtBonus = (300 - Boneco.Tempo)
    if PtBonus > 100 then PtBonus = 100
  else
    PtBonus = (Mina.Tempo - Boneco.Tempo)
    if PtBonus > 100 then PtBonus = 100
  end if
  VeSeGanhaVida PtBonus
end sub

'-------------------------------------------------------------------------------------------

'Define os textos, em português
/'
sub LeTXTBase
end sub
'/
'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------

'ROTINAS REFERENTES AO EDITOR DE MINAS

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------



'-------------------------------------------------------------------------------------------

'Escreve um número pequeno e de 2 algarismos como cabeçalho de linha e coluna

sub EscreveNumeroPeq (byval Numero as integer, X1 as integer, Y1 as integer)

  put (x1, Y1), BMP (274), (int(Numero/10) * 6, 0) - step(5, 7), trans
  put (x1 + 6, Y1), BMP (274), ((Numero mod 10) * 6, 0)- step(5, 7), trans

end sub

'-------------------------------------------------------------------------------------------

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
  line (x1, y1) - (x2, y1 + 2), CorRGB, BF
  line (x1, y1) - (x1 + 2, y2), CorRGB, BF
  line (x1, y2 - 2) - (x2, y2), CorRGB, BF
  line (x2 - 2, y1) - (x2, y2), CorRGB, BF
end sub

'-------------------------------------------------------------------------------------------

'Conta as pedras existentes na mina

function ContaTesouros as integer
  dim as integer F, G
  dim Contagem as integer
  Contagem = 0
  for f=0 to 99
    for g =0 to 59
      if (objeto(f, g).TP >= 40) and (objeto(f, g).TP <= 55) then Contagem += 1
    next
  next
  return Contagem
end function

'-------------------------------------------------------------------------------------------

'Acha a coluna do objeto mais abaixo

function MaiorLinha as integer
  dim as integer LMax, f, g
  LMax = 1

  for F = 0 to 99
    for G = 0 to 59
      if objeto(f,g).TP > 0 or fundo (f, g) <> 1 or frente (f,g )>0 then
        if G > LMaX then LMaX = G
      end if
    next
  next
  return LMax
end function

'-------------------------------------------------------------------------------------------

'Acha a coluna do objeto mais à direita

function MaiorColuna as integer
  dim as integer LMax, f, g
  LMax = 1

  for F = 0 to 99
    for G = 0 to 59
      if objeto(f,g).TP > 0 or fundo (f, g) <> 1 or frente (f,g )>0 then
        if F > LMaX then LMaX = F
      end if
    next
  next
  return LMax
end function

'-------------------------------------------------------------------------------------------

'Salva a mina em arquivo


sub SalvaMina (ParaTestar as integer = 0)
  dim as string Linha, NArq, LMNum, LmTec
  dim as integer nmina, MaiorX, MaiorY, ValTemp, f, g

  'zera contador de tesouros para verificar se tem
  Mina.Tesouros = ContaTesouros ()

  cls
  TrocaTelas

  if Mina.tesouros = 0 then
    LimpaTeclado
    cls
    Mensagem 5, 8, TXT (100), "", ""
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

      LMNum= str(Mina.numero)
      LimpaTeclado
      LMTec = ""

      while LMTec<>Chr(27) and LMTec<>Chr(13)
        cls
        Mensagem 5, 4, TXT(101), TXT(102), LMNum & chr (32 + 63 * (int(Clock * 2) mod 2))

        if LMTec >= "0" and LMTec <= "9" and len (LMNum) < 3 then
          if LMNum = "0" then LMNum = "0"
          LMNum += LMTec
        elseif LMTec = chr(8) or lmtec = c255 + chr(83) then
          lMNum = left (LMNum, len (LMNum) - 1)
        end if
        TrocaTelas
        LMTec=inkey

      wend
      cls
      TrocaTelas

      NArq = "minas/m" + right("000" & str(LMNum),3) + ".map"
      Mina.numero= val(LMNum)
    else
      NArq = "minas/teste.map"
    end if

    cls

    if ParaTestar <> 0 or LMTec = chr (13) then

      if ParaTestar = 0 then
        LMTec=""
        while inkey<>""
          sleep 10, 1
        wend
        Opcao1 = Mina.Noturno
        while LMTec <> " " and LMTec <> chr(27) and LMTec <> chr(13)
          cls
          Mensagem 5, 5, TXT(103), TXT(104), "", , , Opcao1
          LMTec=inkey
          LeMouse
          if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
          if (MouseDisparou = 1) and (MouseSimNao > 0) then LMTec = " "
          if (LmTec = c255+ "H") or (LmTec = c255+ "K") or (LmTec = c255+ "M") or (LmTec = c255+ "P") then Opcao1 = 1 - Opcao1
          TrocaTelas
        wend
        cls
      end if

      if ParaTestar <> 0 or LMTec <> chr(27) then
        if ParaTestar = 0 then
          Mina.Noturno = Opcao1

          LMNum=str(Mina.Tempo)

          while inkey <> ""
            sleep 10
          wend
          LMTec = ""
          while LMTec <> chr(27) and LMTec <> chr(13)
            cls
            Mensagem 5, 4, TXT(106), TXT(107), LMNum & chr (32 + 63 * (int(Clock * 2) mod 2))
            if (LMTec >= "0") and (LMTec <= "9") and (len (LMNum) < 5) then
              if LMNum = "0" then LMNum = ""
              LMNum += LMTec
            elseif LMTec = chr(8) or lmtec = c255 + chr(83) then
              lMNum = left(LMNum, len (LMNum) - 1)
            end if
            LMTec = inkey
            TrocaTelas
          wend
          cls
        end if

        if ParaTestar <> 0 or lmtec = chr(13) then
          if ParaTestar = 0 then
            Mina.Tempo=val(LMNum)
            Mina.alterada = 0
            EdShow = 2
          end if

          'Inicia gravação da mina:

          Mina.Larg = MaiorColuna () + 1
          Mina.Alt = MaiorLinha () + 1

          'Salva dimensões, se é noturno/diurno e o tempo (0=livre)
          kill Narq
          open NArq for binary as #1
          put #1,, Mina.Larg
          put #1,, Mina.Alt
          put #1,, Mina.Noturno
          put #1,, Mina.Tempo

          'Escreve cada linha
          for g=0 to Mina.Alt-1

            for f= 0 to Mina.Larg-1
              put #1,,fundo(f,g)
              put #1,,frente(f,g)
              if boneco.x=f and boneco.y=g then
                objeto(f,g).TP =85
                put #1,,objeto(f,g).TP
                objeto(f,g).TP = 0
              else
                put #1,, objeto(f,g).TP
              end if
            next
          next
          close #1

          cls
          TrocaTelas
          cls
          if ParaTestar = 0 then
            Mensagem 6, 6, TXT(112), "", ""
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
          UltTecla = "ESC"
        end if
      else
        UltTecla = "ESC"
      end if
    else
      UltTecla = "ESC"
    end if
  end if

  LimpaTeclado

end sub

'-------------------------------------------------------------------------------------------

'Rotina principal do EDITOR - pode ser mudada para um item dentro de "Joga"

sub Edita

  dim as integer F, G
  PosMouse = PosMouseEd ()

  select case Jogo.EdStatus
  case Editando
    EdX1 = int (MouseX / 32)
    EdY1 = int (MouseY / 32)
    select case Tecla
    case "ESC"
      if Tecla <> UltTecla then Jogo.EdStatus = RespExit
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

    if (MouseDisparou = 1) or ((MouseB > 0) and ((PosMouse = EdBarra) or (PosMouse = EdEsquerda) or (PosMouse = EdDireita))) then
      select case PosMouse
      case EdForaTela
        'Nada a fazer
      case EdTela
        EdX2 = EDX1
        EdY2 = EDY1
        EdXX1 = EDX1
        EdXX2 = EDX2
        EdYY1 = EDY1
        EdYY2 = EDY2
        if ItemSel = 0 then
          if (boneco.x <> Mapx + edx1) or (boneco.y <> Mapy + edy1) then
            GravaUndo
            boneco.x = Mapx + edx1
            boneco.y = Mapy + edy1
            Mina.Alterada = 1
          end if
        else
          Jogo.EdStatus = Selecionando
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
        PrimeiroItem = int ((MouseX - 80) / 4.48)
        if PrimeiroItem < 0 then PrimeiroItem = 0
        if PrimeiroItem > 100 then PrimeiroItem = 100
      case EdItem
        ItemSel = PrimeiroItem + int (MouseX / 34)
      case EdNovo
        Jogo.EdStatus = RespNovo
      case EdAbre
        Jogo.EdStatus = RespAbrindo
      case EdMove
        Jogo.EdStatus = EdMovendo
        EdMovendoUndo = 0
      case EdSalva
        Jogo.EdStatus = RespSalvar
        UMTec = str(Mina.Numero)
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
        Jogo.EdStatus = Apagando0
      case EdTesta
        Jogo.EdStatus = RespTesta
      case EdUndo
        FazUndo
      case EdRedo
        FazRedo
      case EdEXIT
        Jogo.EdStatus = RespExit
      end select
    end if

  case Selecionando
    if PosMouse = EdTela then
      EdX2 = int (MouseX / 32)
      EdY2 = int (MouseY / 32)
      SwapEDXY
      if (Tecla = "ESC") and (Ulttecla <> Tecla) then
        Jogo.EdStatus = Editando
      else
        if MouseLiberou = 1 then

          Jogo.EdStatus = Editando
          GravaUndo
          Mina.alterada = 1
          for F = EDXX1 to EDXX2
            for G = EDYY1 to EDYY2
              select case ItemSel
              case 1 to 25
                Fundo (MAPX + F, MAPY + G) = ItemSel - 1
              case 26 to 37
                Frente (MAPX + F, MAPY + G) = ItemSel - 26
              case 38 to 114
                Objeto (MAPX + F, MAPY + G).TP = ItemSel - 38
              case else
                Objeto (MAPX + F, MAPY + G).TP = ItemSel - 33
              end select
            next
          next

        end if
      end if
    end if

  case RespNovo
    if PergFecha () = 1 then
      GravaUndo
      for f = -1 to 100
        for g = -1 to 60
          objeto (f, g).TP = 0
          fundo  (f, g) = 1
          frente (f, g) = 0
        next
      next
      boneco.x = 0
      boneco.y = 0
    end if
    Jogo.EdStatus = Editando

  case RespAbrindo
    if PergFecha () = 1 then
      Opcao1 = 0
      Boneco.Mina = 0
      cls
      TrocaTelas
      cls
      Mensagem 7, 8, TXT(92), TXT(93), " "
      LeMinasPers
      TrocaTelas
      cls
      MudaStatus Configs
    else
      Jogo.EdStatus = Editando
    end if

  case EdMovendo
    if ulttecla <> tecla then
      select case Tecla
      case "U"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        Mina.alterada = 1
        for f = 0 to 99
          for g = 0 to 59
            objeto (f, g) = objeto (f, g + 1)
            fundo  (f, g) = fundo  (f, g + 1)
            frente (f, g) = frente (f, g + 1)
          next
        next
        if boneco.y > 0 then boneco.y -= 1
        Objeto (boneco.x, boneco.y).tp = 0
      case "D"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        Mina.alterada = 1
        for f = 0 to 99
          for g = 59 to 0 step -1
            objeto (f, g) = objeto (f, g - 1)
            fundo  (f, g) = fundo  (f, g - 1)
            frente (f, g) = frente (f, g - 1)
          next
        next
        if boneco.y < 59 then boneco.y += 1
        Objeto (boneco.x, boneco.y).tp = 0
      case "R"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        Mina.alterada = 1
        for f = 99 to 0 step -1
          for g = 0 to 59
            objeto(f, g) = objeto (f - 1, g)
            fundo(f, g)  = fundo  (f - 1, g)
            frente(f, g) = frente (f - 1, g)
          next
        next
        if boneco.x < 99 then boneco.x += 1
        Objeto (boneco.x, boneco.y).tp = 0
      case "L"
        if EdMovendoUndo = 0 then GravaUndo : EdMovendoUndo = 1
        Mina.alterada = 1
        for f = 0 to 99
          for g = 0 to 59
            objeto (f, g) = objeto (f + 1, g)
            fundo  (f, g) = fundo  (f + 1, g)
            frente (f, g) = frente (f + 1, g)
          next
        next
        if boneco.x > 0 then boneco.x -= 1
        Objeto (boneco.x, boneco.y).tp = 0
      case "[", "]", "ESC"
        Jogo.EdStatus = Editando
        EdMovendoUndo = 0
      end select
    end if

  case RespSalvar
    SalvaMina
    Jogo.EdStatus = Editando

  case Apagando0
    if PosMouse = EdTela then
      EdX1 = int (MouseX / 32)
      EdY1 = int (MouseY / 32)
    end if
    if Tecla = "ESC" and UltTecla <> Tecla then
      Jogo.EdStatus = Editando
    end if
    if MouseDisparou = 1 then
      if PosMouse = EdTela then
        EdMon = 1
        EdX2 = EDX1
        EdY2 = EDY1
        EdXX1 = EDX1
        EdXX2 = EDX2
        EdYY1 = EDY1
        EdYY2 = EDY2
        Jogo.EdStatus = apagando1
      end if
    end if

  case Apagando1
    if PosMouse = EdTela then
      EdX2 = int (MouseX / 32)
      EdY2 = int (MouseY / 32)
      SwapEDXY
      if (Tecla = "ESC") and (Ulttecla <> Tecla) then
        Jogo.EdStatus = Editando
      else
        if MouseLiberou = 1 then
          Jogo.EdStatus = Editando
          GravaUndo
          Mina.alterada = 1
          for F = EDXX1 to EDXX2
            for G = EDYY1 to EDYY2
              Fundo (MAPX + F, MAPY + G) = 1
              Frente (MAPX + F, MAPY + G) = 0
              Objeto (MAPX + F, MAPY + G).TP = 0
            next
          next
        end if
      end if
    end if

  case RespTesta
    Opcao1 = 0
    LMTec = ""
    if ContaTesouros () = 0 then
      cls
      TrocaTelas
      cls
      Mensagem 5, 8, TXT(100), "", ""
      Jogo.EdStatus = Editando
      TrocaTelas
      cls
      while inkey = ""
        sleep 1, 1
      wend
      LimpaTeclado
    else
      while lmtec <> " " and LMTec <> chr(13) and lmtec <> chr(27)
        cls
        Mensagem 4, 5, TXT (108), "", "", 400, 300, Opcao1
        LMTec=inkey
        LeMouse
        if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
        if (MouseDisparou = 1) and (MouseSimNao > 0) then LMTec = " "
        if (LmTec = c255+ "H") or (LmTec = c255+ "K") or (LmTec = c255+ "M") or (LmTec = c255+ "P") then Opcao1 = 1 - Opcao1
        TrocaTelas
        jogo.seqciclo=(jogo.seqciclo+1) mod 360
      wend
      cls
      if Opcao1 = 1 or LMTec = chr(27) then
        Jogo.EdStatus = Editando
      else
        SalvaMina -1
        LeMinaOUT -1, 0
        IniciaVida
        MudaStatus Testando
      end if

      LimpaTeclado 1

    end if

  case RespExit
    Opcao1 = 1
    LMTec = ""
    while lmtec <> " " and LMTec <> chr(13) and lmtec <> chr(27)
      cls
      if Mina.Alterada = 1 then
        Mensagem 4, 5, TXT (98), TXT (105), "", 400, 300, Opcao1
      else
        Mensagem 4, 5, TXT (105), "", "", 400, 300, Opcao1
      end if
      LMTec=inkey
      LeMouse
      if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
      if (MouseDisparou = 1) and (MouseSimNao > 0) then LMTec = " "
      if (LmTec = c255+ "H") or (LmTec = c255+ "K") or (LmTec = c255+ "M") or (LmTec = c255+ "P") then Opcao1 = 1 - Opcao1
      TrocaTelas
      jogo.seqciclo=(jogo.seqciclo+1) mod 360
    wend
    cls
    if Opcao1 = 1 or LMTec = chr(27) then
      Jogo.EdStatus = Editando
    else
      MudaStatus NoMenu
    end if

    LimpaTeclado 1

  end select

  Objeto (Boneco.x, boneco.y).Tp = 0

end sub

'-------------------------------------------------------------------------------------------

sub EncerraTeste
  LeMinaOUT -1, 1
  MudaStatus Editor
  kill "minas/teste.map"
end sub

'-------------------------------------------------------------------------------------------

'Desenha um item na tela do editor, conforme seu tipo

sub DesenhaItem (ITX as integer, ITY as integer, ITN as integer)
  if ITN = 0 then 'Boneco (ITN = 0)
    put (ITX, ITY), BMP (116), trans
  elseif ITN = 1 then 'Fundo 0 = água (ITN = 1)
    put (ITX, ITY), BMP (213), pset
  elseif ITN = 2 then 'Fundo 1 = vazio
    line (ITX, ITY) - step (31, 31), &HFFFFFF, B
    Escreve "Fu", ITX + 7, ITY - 1
    Escreve "vz", ITX + 7, ITY + 13
    line (ITX, ITY + 31) - step (31, -31), &HFFFFFF
  elseif ITN  < 26 then 'Fundos 1 a 24 (ITN = 2 a 25)
    put (ITX, ITY), BMP (ITN - 1), pset
  elseif ITN = 26 then  'Frente 0 = vazio
    line (ITX, ITY) - step (31, 31), &HFFFFFF, B
    Escreve "Fr", ITX + 7, ITY - 1
    Escreve "vz", ITX + 7, ITY + 13
    line (ITX, ITY + 31) - step (31, -31), &HFFFFFF
  elseif ITN < 38 then  'Frentes 0 a 10
    put (ITX, ITY), BMP (ITN - 2), trans
  elseif ITN = 38 then  'Objeto 0 = vazio
    line (ITX, ITY) - step (31, 31), &HFFFFFF, B
    Escreve "Obj", ITX + 3, ITY - 1
    Escreve "vz", ITX + 7, ITY + 13
    line (ITX, ITY + 31) - step (31, - 31), &HFFFFFF
  elseif ITN < 115 then
    put (ITX, ITY), BMP (TpObjeto(ITN - 38).img), trans
  elseif ITN < 123 then
    put (ITX, ITY), BMP (TpObjeto(ITN - 33).img), trans
  else
    Escreve "?", ITX + 10, ITY + 7
  end if
end sub

'-------------------------------------------------------------------------------------------

'Encontra a posição do mouse (sobre qual comando ele está)

function PosMouseEd () as integer
  dim Resposta as integer
  if MouseY >= 544 then
    if MouseX < 611 then
      if MouseY > 564 then
        Resposta = EdItem
      else
        if MouseX < 23 then
          Resposta = EdInicio
        elseif MouseX < 46 then
          Resposta = EdEsquerda
        elseif MouseX < 565 then
          Resposta = EdBarra
        elseif MouseX < 588 then
          Resposta = EdDireita
        else
          Resposta = EdFim
        end if
      end if
    elseif MouseX > 612 then
      if MouseX < 640 then
        if MouseY < 572 then
          Resposta = EdNovo
        else
          Resposta = EdMove
        end if
      elseif MouseX < 667 then
        if MouseY < 572 then
          Resposta = EdAbre
        else
          Resposta = EdSalva
        end if
      elseif MouseX < 719 then
        Resposta = EdVisao
      elseif MouseX < 746 then
        if MouseY < 572 then
          Resposta = EdMudaGrid
        else
          Resposta = EdUndo
        end if
      elseif MouseX < 773 then
        if MouseY < 572 then
          Resposta = EdApaga
        else
          Resposta = EdRedo
        end if
      else
        if MouseY < 572 then
          Resposta = EdTesta
        else
          Resposta = EdExit
        end if
      end if
    end if
  elseif MouseY > 0 and MouseX >0 and MouseX <= 799 then
    Resposta = EdTela
  else
    Resposta = EdForaTela
  end if
  return Resposta
end function

'-------------------------------------------------------------------------------------------

'Limpa dados da mina usados pelo editor (nº, tempo, etc)

sub LimpaMinaEditor
  dim as integer F, G, H
  for H = 0 to MaxUndo
    for f = -1 to 100
      for g = -1 to 60
        UndoFrente (h, f, g) = 0
        UndoFundo  (h, f, g) = 1
        UndoObjeto (h, f, g) = 0
      next
    next
    BonecoX (h) = 0
    BonecoY (h) = 0
  next

  Mina.alterada = 0
  LMTec = ""
  UMTec = ""
  PrimeiroItem = 0
  ItemSel = 0
  EdShow = 2
  EdGrid = 0
  MatrizAtual = 0
  MatrizRedoLimite = 0
  MatrizUndoLimite = 0
  EdMovendoUndo = 0
  Mina.Tempo = 0
  Mina.Numero = 0
  Mina.Noturno = 0
end sub

'-------------------------------------------------------------------------------------------

'Pergunta se pode fechar mina não salva

function PergFecha () as integer
  dim OpTXT as integer
  if Jogo.EdStatus = RespNovo then
    OpTXT = 99
  elseif Jogo.EdStatus = RespAbrindo then
    OpTXT = 113
  end if
  Opcao1 = 1
  LMTec = ""
  while lmtec <> " " and LMTec <> chr(13) and lmtec <> chr(27)
    cls
    if Mina.Alterada = 1 then
      Mensagem 4, 5, TXT (98), TXT (OpTXT), "", 400, 300, Opcao1
    else
      Mensagem 4, 5, TXT (OpTXT), "", "", 400, 300, Opcao1
    end if
    LMTec=inkey
    LeMouse
    if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
    if (MouseDisparou = 1) and (MouseSimNao > 0) then LMTec = " "
    if (LmTec = c255+ "H") or (LmTec = c255+ "K") or (LmTec = c255+ "M") or (LmTec = c255+ "P") then Opcao1 = 1 - Opcao1
    TrocaTelas
    jogo.seqciclo=(jogo.seqciclo+1) mod 360
  wend
  cls
  LimpaTeclado 1

  if Opcao1 = 1 or LMTec = chr(27) then
    return 0
  else
    return 1
  end if

end function

'-------------------------------------------------------------------------------------------

'Coloca coordenadas em ordem crescente

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

'-------------------------------------------------------------------------------------------

'Grava situação para possível futuro UNDO

sub GravaUndo
  dim as integer F, G

  for f = -1 to 100
    for g = -1 to 60
      UndoFrente (MatrizAtual, f, g) = Frente (f, g)
      UndoFundo  (MatrizAtual, f, g) = Fundo  (f, g)
      UndoObjeto (MatrizAtual, f, g) = Objeto (F, g).tp
    next
  next

  BonecoX (MatrizAtual) = Boneco.X
  BonecoY (MatrizAtual) = Boneco.Y

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


'-------------------------------------------------------------------------------------------

'Faz um undo no editor

sub FazUndo
  dim as integer F, G
  if MatrizAtual = MatrizRedoLimite then
    for f = -1 to 100
      for g = -1 to 60
        UndoFrente (MatrizAtual, f, g) = Frente (f, g)
        UndoFundo  (MatrizAtual, f, g) = Fundo  (f, g)
        UndoObjeto (MatrizAtual, f, g) = Objeto (F, g).tp
      next
    next
    BonecoX (MatrizAtual) = Boneco.X
    BonecoY (MatrizAtual) = Boneco.Y
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
        Objeto (F, g).tp = UndoObjeto (MatrizAtual, f, g)
      next
    next
    Boneco.X = BonecoX (MatrizAtual)
    Boneco.Y = BonecoY (MatrizAtual)
  end if
end sub

'-------------------------------------------------------------------------------------------

'Faz um redo no editor

sub FazRedo
  dim as integer F, G
  if MatrizAtual <> MatrizRedoLimite then
    if MatrizAtual = MaxUndo then
      MatrizAtual = 0
    else
      MatrizAtual += 1
    end if
    for f = -1 to 100
      for g = -1 to 60
        Frente (f, g)    = UndoFrente (MatrizAtual, f, g)
        Fundo  (f, g)    = UndoFundo  (MatrizAtual, f, g)
        Objeto (F, g).tp = UndoObjeto (MatrizAtual, f, g)
      next
    next
    Boneco.X = BonecoX (MatrizAtual)
    Boneco.Y = BonecoY (MatrizAtual)
  end if
end sub

'-------------------------------------------------------------------------------------------

sub LimpaTeclado (IncLMTec as integer = 0)
  dim as integer EsperaMais, f

  if IncLMTec <> 0 then
    if LMTec = " " then
      UltTecla = "]"
      Tecla = "]"
    elseif LMTec = chr(13) then
      UltTecla = "["
      Tecla = "["
    elseif LMTec = chr(27) then
      UltTecla = "ESC"
      Tecla = "ESC"
    end if
  end if

  EsperaMais = 1
  while EsperaMais = 1
    EsperaMais = 0
    for F = 0 to 127
      if multikey (f) then EsperaMais = 1
    next
    sleep 1, 1
  wend

  while inkey <> ""
    sleep 1, 1
  wend
end sub

'-------------------------------------------------------------------------------------------

'Faz a leitura do mouse

sub LeMouse
  MouseXAnt = MouseX
  MouseYAnt = MouseY
  MouseBAnt = MouseB
  'MouseW, MouseWAnt, MouseWDir
  MouseWAnt = MouseW
  getmouse (MouseX, MouseY, MouseW, MouseB)
  MouseB = MouseB and 1
  if MouseB = 1 and MouseBAnt = 0 then MouseDisparou = 1 else MouseDisparou = 0
  if MouseB = 0 and MouseBAnt = 1 then MouseLiberou = 1 else MouseLiberou = 0
  if (MouseXAnt <> MouseX) or (MouseYAnt <> MouseY) then MouseMoveu = 1 else MouseMoveu = 0
  MouseWDir = sgn (MouseW - MouseWAnt)
end sub

'-------------------------------------------------------------------------------------------

'Faz a mudança de um status para outro, arranjando os parametros necessários

sub MudaStatus (NovoStatus as integer)
  Jogo.StatusAnt = Jogo.Status
  select case NovoStatus
  case NoMenu
    LimpaTeclado
    TTDemo1 = Clock
  case GameOver
    SorteiaNotaGameOver
    XM =0
  case Instruc
    Jogo.TelaInstr = 0
  case Top10
    LeTopDez
  case Editor
    Jogo.EdStatus = Editando
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
  Jogo.Status = NovoStatus
end sub

'-------------------------------------------------------------------------------------------

'Desativa os sons ligados

sub DesligaSons
  dim as integer F, G
  for f = 1 to 6
    for g = 1 to 4
      'midiOutShortMsg(hMidiOut, Som (f, g).COff)
    next
  next
  for f = 1 to 7
    'midiOutShortMsg(hMidiOut, SomEx (f).COff)
  next
end sub

'-------------------------------------------------------------------------------------------

'Pede confirmação se é pra encerrar o teste da mina sendo editada

function PerguntaSeEncerraTeste() as integer
  Mensagem 0, 5, TXT (95), "", "", 400, 300, Opcao1
  if (Tecla <> UltTecla) and (Tecla = "R" or Tecla = "U" or Tecla = "D" or Tecla = "L") then
    Opcao1 = 1 - Opcao1
  end if
  if ((MouseMoveu = 1) or (MouseDisparou = 1)) and (MouseSimNao > 0) then Opcao1 = MouseSimNao - 1
  if (Opcao1 = 1 and ((MouseDisparou = 1) or ((Tecla <> UltTecla) and (Tecla = "[" or Tecla = "]")))) or (Tecla = "ESC" and UltTecla <> Tecla) then
    MudaStatus Testando
    LeMinaOUT -1, 0
    Iniciado = 0
    IniciaVida
    return 1
  elseif Opcao1 = 0 then
    if (MouseDisparou = 1) or ((Tecla <> UltTecla) and (Tecla = "[" or Tecla = "]")) then
      EncerraTeste
      return 2
    end if
  else
    return 0
  end if
end function
