
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
  Tempo    as ulong    'Tempo para concluir a mina
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
  Passo      as long     'Número do passo no movimento
end type

'Top Score
type Recorde
  Nome   as string    'Nome
  Pontos as uinteger  'Pontuação
end type
