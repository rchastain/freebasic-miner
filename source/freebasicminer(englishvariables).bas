'FreeBasic Miner 1.0 - 2011
'--------------------------------------------------
'
'
'--------------------------------------------------

'--------------------------------------------------
'
'
'
'


'--------------------------------------------------
#Include Once "fbgfx.bi"
#Include Once "file.bi"
#Include Once "windows.bi"
#Include Once "win\mmsystem.bi"
#If __FB_LANG__ = "fb"
	Using FB 
#EndIf



'--------------------------------------------------
#Define RGBA_A(c) (CUInt(c) Shr 24)
#Define RGBA_R(c) (CUInt(c) Shr 16 And 255)
#Define RGBA_G(c) (CUInt(c) Shr 8 And 255)
#Define RGBA_B(c) (CUInt(c) And 255)
#Define Magenta &HFFFF00FF
#Define FontFileWidth 838
#Define MaxUndo 49

Const C255 = Chr (255)

Enum	'Menu options
	GameStart
	GoToMine 
	HighScores
	About
	Volume
	ChLanguage
	Custom
	EditCustom
	GameExit
End Enum

Enum	'program status
	MenuScreen
	Configs
	Playing
	DemoMode
	Testing
	Paused
	GameOver
	MapMode
	Instruc
	WonMine
	WonGame
	Top10
	SelectLanguage
	Editor
End Enum

Enum	'Where mouse is over (editor)
	EdOutOfScreen
	EdScreen
	EdBegin
	EdLeft
	EdRight
	EdEnd
	EdBottomBar
	EdItem
	EdNew
	EdOpen
	EdMove
	EdSave
	EdView
	EdChangeGrid
	EdClearArea
	EdTestMine
	EdUndo
	EdRedo
	EdExit
End Enum

Enum	'Editor Status
	Editing
	Selecting
	AnswerNew
	AnswerOpen
	EdMoving
	AnswerSave
	Clearing0
	Clearing1
	AnswerTest
	AnswerExit
End Enum
	


'Types
'--------------------------------------------------

'Sounds
Type TSounds
	COn1			As DWord
	COn2			As DWord
	COff			As DWord
	Time			As UByte
End Type

'Game main variables
Type TGame
	Status       	As Integer 	'Program Status
	Status0       	As Integer 	'Status when Cycle is started (for comparision in its end)
	OldStatus		As Integer	'Same above
	EdStatus		As Integer	'Editor Status
	LastExplosion  	As Integer	'To include a new one in list
	Steps       	As Integer	'To go from one tile to the next
	StepSize 		As Integer	'Pixels by step
	Cycle	     	As Integer	'Movement Cycle (step number)
	DelayMSec	  	As Integer	'Delay (for FPS adjust)
	LastTimer     	As Long		'For FPS adjust
	Finish      	As Integer	'Finish the game
	SeqCycle     	As Integer	'Cycles counting (0 - 999)
	Player       	As Integer	'0=red, 1=green clothes
	HowManyMines    As Integer	'How many mines we have
	LivesOnStart    As Integer	'Lifes on game start
	Volume   		As UByte	'Sound volume
	MaxReached		As UInteger	'Top reached mine
End Type

'Our hero
Type TPlayer
	CurrentMine    	As Integer  'Number of current mine
	Lives          	As Integer  'Number of lives
	Score         	As Long     'Score
	Died         	As Integer  '0=not (living);  1~ = Steps since died
	LastDirection   As Integer  'Direction befor stopping
	CurrDirection   As Integer  'Direction of current moving  (0=stopped 1=right 2=left 3=up 4=down 5=falling)
	Pushing     	As Integer  'If pushing objects
	StepNumber     	As Integer  'Of movement (0=stopped; 1 ~ Game.Steps)
	Img            	As Integer  'Image Number
	ImgX           	As Integer  'X (relative to the screen)
	ImgY           	As Integer  'Y (relative to the screen)
	X              	As Integer  'X (relative to the mine)
	Y              	As Integer  'Y (relative to the mine)
	Oxygen      	As Integer  'Oxygen remaining
	UsingOxygen    	As Integer  '0=Não 1=Usando garrafa de oxigênio
	ItScaffold      As Integer  'Scaffold counting
	ItOxygen     	As Integer  'Oxygen bottles
	ItPickaxe     	As Integer  'Pickaxes counting
	ItDrill    		As Integer  'Drills counting
	ItBombS     	As Integer  'Small bombs counting
	ItBombB      	As Integer  'Bog bombs counting
	UsingPickaxe    As Integer  'Using pickaxe now?
	UsingDrill    	As Integer  'Using drill now?
	DrillDirection  As Integer  'Using drill - direction (1=right 2=left)
	DrillDirChanged As Integer  'Changed direction when using drill? (0=no, so can change; 1=changed, so can't change anymore)
	Time          	As Long     'Time trying the mine
	Name           	As String   'Player name
End Type

'Mine
Type TMine
	Number 			As Integer
	Kind			As UByte	'0=Internal  1=Custom
	Width 			As UByte
	Height     		As UByte
	Gems   			As Integer  'Counted when mine is opened
	X          		As Integer  'Start position's X 
	Y          		As Integer  'Start position's Y
	DarkType   		As UByte
	Time      		As UInteger	'Time for solving
	Changed 		As Integer	'For editor to ask before closing
End Type

'Explosions
Type TExplosion
	X     		As Integer   'X (relative to the mine)
	Y     		As Integer   'Y (relative to the mine)
	Kind  		As Integer   '0=not used; 1=small (3 x 1); 2=big (3 x 3)
	Time 		As Integer   '0=not used; 1~ = Steps
End Type

'Editor
Type EdType
	Tp 			As Integer  '0=background 1=object 2=foreground
	Cod 		As Integer 	'background, object or foreground number
End Type


'For object behavior
Type TObjBehavior
	Empty    	As Byte		'0=not empty; 1=empty (no objects in the cell)
	Scalable    As Byte		'0=no; 1=yes - like stairs
	Support    	As Byte		'0=no; 1=yes (can walk over) - almost everytihng
	Walk     	As Byte		'0=no; 1=yes (can walk through) - soils and stairs
	Kill     	As Byte		'0=no; 1=yes (skewers)
	PushWeight 	As Integer	'0=any amount; 1=up to 2; 2=only 1; 3=none can be pushed
	Fall     	As Byte		'0=no; 1=yes (object falls if there is nothing under it)
	Destroyable As Byte		'0=noway;  1=by explosion;  2=by explosion, drill or pickaxe (actually, there's nothing set as 1)
	Sound     	As Byte		'0=Empty;  1=Soil;  2=Brick/Rock/Stair;  3=Gem/Car/Item;  4=Wood Box/straw
End Type

'Objects
Type TypeOfObjects
	Kind As Integer    'Behavior type number
	Img  As Integer    'Object image
	Item As Integer    'Item Number
End Type

'Showing points when you get a gem
Type TMsgGemPoints
	Cycle	As Integer '0=over
	Score	As Integer
	X		As Integer
	Y		As Integer
End Type

'Objects
Type TObj
	Tp			As UByte    'Object type
	IsFalling	As Byte     '0=no; 1=yes
	WasFalling	As Byte     'Was falling in previous Cycle
	BeingPushed As Byte     '0=no; 1=to right; 2=to left
	StepNumber	As Integer  'Of movement
End Type

'Top Score
Type TpTopScore
	Name	As String
	Score	As UInteger
End Type


'Sub's
'--------------------------------------------------
Declare Sub WriteNumber (ByVal Number As Long, Length As Integer, X1 As Integer, Y1 As Integer, Aligns As Integer)
Declare Sub WriteTXT (ByVal Text As String, x1 As Integer, y1 As Integer, Bold As Integer = 0, BoldV As Integer = 0)
Declare Sub WriteCentered (ByVal Text As String, x1 As Integer, Bold As Integer = 0, BoldV As Integer = 0)
Declare Sub WritePoints (Points As Integer, X As Integer, Y As Integer, Fading As Integer)
Declare Function TextWidth (ByVal Text As String, Bold As Integer = 0) As Integer
Declare Sub ResetGame
Declare Sub ResetLife
Declare Sub ReadInternalMine (MineNumber As Integer, AmountOnly As Integer = 0)
Declare Sub ReadCustomMine (MineNumber As Integer, Editing As Integer = 0)
Declare Sub ReadMineDetails (Editing As Integer = 0)
Declare Sub SearchCustomMines
Declare Sub DrawScene
Declare Sub PlayGame
Declare Sub PickUpObj (POX As Integer, POY As Integer)
Declare Function PushObj (ByVal POX As Integer, ByVal POY As Integer, ByVal MDir As Integer, ByVal Weight As Integer, ByVal Amount As Integer) As Integer 
Declare Sub Explode (ByVal EXX As Integer, ByVal EXY As Integer, ByVal XSize As Integer)
Declare Sub ClearMine
Declare Function VerifyRecord As Integer
Declare Sub ReadRecordTable
Declare Sub SwapScreens
Declare Sub CreateRecordTable
Declare Sub ResetRecordFile
Declare Sub ShowMSG (MColor As Integer, MType As Integer, T1 As String, T2 As String, T3 As String, OX As Integer = 400, OY As Integer= 300, MOption As Integer = 0)
Declare Sub DrawBox (H As Integer, V As Integer, QCor As Integer, OX As Integer = 400, OY As Integer = 300)
Declare Sub PutLogo (LX As Integer, LY As Integer)
Declare Sub GameOverRandomSound
Declare Sub GameWonRandomSound
Declare Sub MarkGemPoints (Points As Integer, X As Integer, Y As Integer)
Declare Function CTRX As Integer
Declare Function CTRY As Integer
Declare Function NextKeyForDemo () As String
Declare Sub GameLoadBar (perc As Integer)
Declare Sub SaveConfigs
Declare Function ReadLanguagePack (LanguageN As String) As Integer
Declare Sub ReadPortuguese
Declare Sub SearchLanguagePacks ()
Declare Sub DrawMenuBackground
Declare Sub CheckIfGotLife (AddPoints As Integer)
Declare Sub CalcTimeBonus
Declare Sub ReadMouse
Declare Sub ChangeStatus (NewStatus As Integer)
Declare Sub AllSoundOff
Declare Sub EmptyKeyboard (IncLMTec As Integer = 0)

'Editor:
Declare Sub DoEdit
Declare Sub WriteNumberLit (ByVal Number As Integer, X1 As Integer, Y1 As Integer)
Declare Sub SaveMine (ForTest As Integer = 0)
Declare Sub DrawLine (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, WColor As Integer)
Declare Sub FinishTest
Declare Sub DrawItem (ITX As Integer, ITY As Integer, ITN As Integer)
Declare Function LastCol As Integer
Declare Function LastRow As Integer
Declare Function CountGems As Integer
Declare Function MousePosEd () As Integer
Declare Sub DoRedo
Declare Sub DoUndo
Declare Sub ClearMineEditor
Declare Function AskToClose () As Integer
Declare Sub SwapEDXY
Declare Sub SaveUndo
Declare Function AskToFinishTest() as Integer


'Shared Variables
'--------------------------------------------------

'Image buffering
Dim Shared LoadSuccess As Integer
Dim Shared As Any Ptr Grafx, GrafX2, BMP (281)

'Gem point showing
Dim Shared As TMsgGemPoints MSG (20)

'High Scores
Dim Shared TopPt (10) As TpTopScore
Dim Shared As Integer ConfirmDel

'Sounds
Dim Shared hMidiOut As HMIDIOUT
Dim Shared As TSounds VSound (1 To 6, 1 To 4), VSoundEx (1 To 7)
Dim Shared As UByte SoundPlay (1 To 6, 1 To 4), NotesGameWon
Dim Shared As DWord LastNoteGameOver, VarAnswer
Dim Shared As Double GameWonNoteTimer

'Menu
Dim Shared As Integer OpMenu, XM, YM, Mine1, Mine2, PosTop10, Option1

'Others
Dim Shared As Integer Started, MapX, MapY, NextMSG, LenMSG
Dim Shared As String KBKey, LastKBKey
Dim Shared As UInteger ColorRGB, ColorRGB2

'Font
Dim Shared As String Lt, XTemp
Dim Shared as Integer CharacPosition (100, 1)

'Screen
Dim Shared ActiveScreen As Integer

'Languages
Dim Shared As String Language (15), CurrentLanguage
Dim Shared As Integer LanguangesQtt, LangNumber

'Texts (language pack)
Dim Shared As String TXT (159) 

'Timer
Dim Shared As UInteger OldTimer, NewTimer
Dim Shared As Double StartTime

'Game
Dim Shared Game As TGame
Dim Shared VPlayer As TPlayer
Dim Shared As TMine Mine
Dim Shared GemValue (7 To 22) As Integer
Dim Shared As Integer TmpSleep, PtBonus

'Explosions
Dim Shared Explosion (10) As TExplosion

'Objects behavior
Dim Shared Behavior (13) As TObjBehavior

'Object Types
Dim Shared TpObject (84) As TypeOfObjects

'Tiles: Background layer   (0 = water)
Dim Shared As UByte BkGround (-1 To 100, -1 To 60)

'Tiles: objects layer
Dim Shared As TObj Object (-1 To 100, -1 To 60)

'Tiles: foreground layer
Dim Shared As UByte FrGround (-1 To 100, -1 To 60)

'Moving player images
Dim Shared ImgStopped (5) As Integer
Dim Shared ImgMoving (7,3) As Integer
Dim Shared ImgUsing (2,1) As Integer

'Start screen
Dim Shared As Integer CRed, CGreen, CBlue, VRed, VGreen, VBlue, CRed2, CGreen2, CBlue2

'Demo mode
Dim Shared As String KBKeysDemo
Dim Shared As Integer PositDemo, DemoW1, DemoW2, DemoCycle, MSGDemo, MensTime
Dim Shared As Double TTDemo1, TTDemo2

'Custom Mines
Dim Shared As Integer CustomMine (999), SelCustomMine (999), CustomMineQt, CustomTemp

'Mouse:
Dim Shared As Integer MouseX, MouseY, MouseB, MouseXOld, MouseYOld, MouseBOld, MouseClicked, MouseReleased, MouseYesNo, MouseMoved, MouseOver, MouseW, MouseWOld, MouseWDir

'Editor:
Dim Shared As TMine MineEd
Dim Shared As String LMTec, UMTec

Dim Shared As Integer EdX1, EdX2, EdY1, EdY2, EdMOn, EdShow, FirstItemShowed, SelectedItem
Dim Shared As Integer EDXX1, EDXX2, EDYY1, EDYY2, EdGrid, MousePos

'Undo:
Dim Shared As Integer CurMatrix, LimitForRedo, LimitForUndo, EdMovingUndo, VPlayerX (MaxUndo), VPlayerY (MaxUndo)
Dim Shared As UByte UndoBkGround (MaxUndo, -1 To 100, -1 To 60), UndoFrGround (MaxUndo, -1 To 100, -1 To 60), UndoObject (MaxUndo, -1 To 100, -1 To 60)


'--------------------------------------------------
'Start routines
'--------------------------------------------------

'Font
Lt = "ABCDEFGHIJKLMNOPQRSTUVWXYZÇÁÉÍÓÚÂÊÔÃÕÀabcdefghijklmnopqrstuvwxyzçáéíóúâêôãõà.,:?!0123456789-+'/()=_>|"

'Local use variables
Dim as integer F, G, H, I

'Initialize screen
WindowTitle "FreeBasic Miner"
Screen 19, 32, 2  '800 x 600, 32 bpp color, 2 pages
Randomize

'Color for background
CRed = 0
VRed = Int (Rnd * 2)
VGreen = Int (Rnd * 2)
VBlue = Int (Rnd * 2)
DrawMenuBackground
CRed = 0
	
Draw String (25,500), "FreeBasic Miner is Loading..."
Line (20,520) - (779,554), RGB(200,200,200), bf
Line (21,519) - (778,555), RGB(200,200,200), b
Line (23,523) - (776,551), RGB(16,16,48),bf

GameLoadBar 5
Language (0)= "Portugues"

Sleep 2, 1

'Define player image sequences
'--------------------------------------------------

'Stopped (depends on last direction)
ImgStopped (0) = 116
ImgStopped (1) = 119
ImgStopped (2) = 122
ImgStopped (3) = 117
ImgStopped (4) = 117
ImgStopped (5) = 116

'right
ImgMoving (0, 0) = 119
ImgMoving (0, 1) = 118
ImgMoving (0, 2) = 120
ImgMoving (0, 3) = 118

'Left
ImgMoving (1, 0) = 122
ImgMoving (1, 1) = 121
ImgMoving (1, 2) = 123
ImgMoving (1, 3) = 121

'Up
ImgMoving (2, 0) = 124
ImgMoving (2, 1) = 117
ImgMoving (2, 2) = 125
ImgMoving (2, 3) = 117

'Down
ImgMoving (3, 0) = 124
ImgMoving (3, 1) = 117
ImgMoving (3, 2) = 125
ImgMoving (3, 3) = 117

'Falling
ImgMoving (4, 0) = 126
ImgMoving (4, 1) = 126
ImgMoving (4, 2) = 126
ImgMoving (4, 3) = 126

'Pushing objetc - right
ImgMoving (5, 0) = 128
ImgMoving (5, 1) = 127
ImgMoving (5, 2) = 129
ImgMoving (5, 3) = 127

'Pushing objetc - left
ImgMoving (6, 0) = 131
ImgMoving (6, 1) = 130
ImgMoving (6, 2) = 132
ImgMoving (6, 3) = 130

'Dying
ImgMoving (7, 0) = 116
ImgMoving (7, 1) = 119
ImgMoving (7, 2) = 117
ImgMoving (7, 3) = 122

'Using pickaxe
ImgUsing (0, 0) = 133
ImgUsing (0, 1) = 134

'Using drill - right
ImgUsing (1, 0) = 135
ImgUsing (1, 1) = 136

'Using drill - left
ImgUsing (2, 0) = 137
ImgUsing (2, 1) = 138

GameLoadBar 10
Sleep 2, 1

'Define Behaviors for objects
'--------------------------------------------------

'Empty (no object)
With Behavior (0) 
	.Empty = 1
	.Scalable = 0
	.Support = 0
	.Walk = 2
	.Kill = 0
	.PushWeight = 3
	.Fall = 0
	.Destroyable = 0
	.Sound = 1
End With

'Soil
With Behavior (1) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 1
	.Kill = 0
	.PushWeight = 3
	.Fall = 0
	.Destroyable = 1
	.Sound = 1
End With

'Destroyable wall
With Behavior (2) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 0
	.Kill = 0
	.PushWeight = 3
	.Fall = 0
	.Destroyable = 2
	.Sound = 1
End With  

'Indestructible wall
With Behavior (3) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 0
	.Kill = 0
	.PushWeight = 3
	.Fall = 0
	.Destroyable = 0
	.Sound = 2
End With

'Stair
With Behavior (4) 
	.Empty = 0
	.Scalable = 1
	.Support = 1
	.Walk = 2
	.Kill = 0
	.PushWeight = 3
	.Fall = 0
	.Destroyable = 1
	.Sound = 1
End With   

'Gem
With Behavior (5) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 1
	.Kill = 0
	.PushWeight = 3
	.Fall = 1
	.Destroyable = 1
	.Sound = 2
End With     

'Rock
With Behavior (6) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 0
	.Kill = 0
	.PushWeight = 3
	.Fall = 1
	.Destroyable = 2
	.Sound = 2
End With     

'Car
With Behavior (7) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 0
	.Kill = 0
	.PushWeight = 0
	.Fall = 1
	.Destroyable = 1
	.Sound = 3
End With 

'Wood box
With Behavior (8) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 0
	.Kill = 0
	.PushWeight = 2
	.Fall = 1
	.Destroyable = 2
	.Sound = 4
End With  

'Straw
With Behavior (9) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 0
	.Kill = 0
	.PushWeight = 1
	.Fall = 1
	.Destroyable = 2
	.Sound = 1
End With    

'Item
With Behavior (10) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 1
	.Kill = 0
	.PushWeight = 3
	.Fall = 1
	.Destroyable = 1
	.Sound = 3
End With  

'Activated bomb
With Behavior (11) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 2
	.Kill = 0
	.PushWeight = 3
	.Fall = 1
	.Destroyable = 0
	.Sound = 3
End With   

'Used scaffold
With Behavior (12) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 2
	.Kill = 0
	.PushWeight = 3
	.Fall = 1
	.Destroyable = 1
	.Sound = 2
End With    

'Skewers
With Behavior (13) 
	.Empty = 0
	.Scalable = 0
	.Support = 1
	.Walk = 2
	.Kill = 1
	.PushWeight = 3
	.Fall = 0
	.Destroyable = 1
	.Sound = 2
End With      

GameLoadBar 15
Sleep 2, 1


'Define objects
'--------------------------------------------------

'Empty (0):
With TpObject (0)
	.Kind = 0
	.Img  = 0
	.Item = 0
End With

'Soils (1-14):
For f = 0 To 13
	With TpObject (f + 1)
		.Kind = 1
		.Img  = f + 36
		.Item = 0
	End With
Next

'Destroyable walls (15-25):
For f = 0 To 10
	With TpObject (f + 15)
		.Kind = 2
		.Img  = f + 50
		.Item = 0
	End With
Next

'Indestructible wall (26-37):
For f = 0 To 11
	With TpObject (f + 26)
		.Kind = 3
		.Img  = f + 61
		.Item = 0
	End With
Next

'Stairs (38-39):
For f = 0 To 1
	With TpObject (f + 38)
		.Kind = 4
		.Img  = f + 73
		.Item = 0
	End With
Next

'Gems (40-55):
For f = 0 To 15
	With TpObject (f + 40)
		.Kind = 5
		.Img  = f + 75
		.Item = f + 7
	End With
Next

'Rocks (56-63):
For f = 0 To 7
	With TpObject (f + 56)
		.Kind = 6
		.Img  = f + 91
		.Item = 0
	End With
Next

'Cars (64-66):
For f = 0 To 2
	With TpObject (f + 64)
		.Kind = 7
		.Img  = f + 99
		.Item = 0
	End With
Next

'Wood boxes (67-68):
For f = 0 To 1
	With TpObject (f + 67)
		.Kind = 8
		.Img  = f + 102
		.Item = 0
	End With
Next

'Straw (69-70):
For f = 0 To 1
	With TpObject (f + 69)
		.Kind = 9
		.Img  = f + 104
		.Item = 0
	End With
Next

'Items (71-76):
For f = 0 To 5
	With TpObject (f + 71)
		.Kind = 10
		.Img  = f + 106
		.Item = f + 1
    End With
Next

'Activated bombs (77-78: small; 79-80: big):
For f = 0 To 3
	With TpObject (f + 77)
		.Kind = 11
		.Img  = f + 112
		.Item = 0
	End With
Next

'Scaffold in use (81):
With TpObject (81)
	.Kind = 12
	.Img  = 236
	.Item = 0
End With

'Skewers (82-84)
For f = 0 To 2
	With TpObject(f + 82)
		.Kind = 13
		.img  = 233 + f
		.item = 0
	End With
Next

GameLoadBar 20
Sleep 2, 1

'Gems values
GemValue (7)  = 1
GemValue (8)  = 2
GemValue (9)  = 3
GemValue (10) = 4
GemValue (11) = 5
GemValue (12) = 6
GemValue (13) = 7
GemValue (14) = 8
GemValue (15) = 9
GemValue (16) = 10
GemValue (17) = 12
GemValue (18) = 15
GemValue (19) = 17
GemValue (20) = 20
GemValue (21) = 25
GemValue (22) = 30

'Initialize MIDI
If midiOutOpen( @hMidiOut, MIDI_MAPPER, 0, 0, CALLBACK_NULL) Then
	Cls
	Draw String (10, 20), TXT (1)
	Draw String (10, 50), TXT (50)
	EmptyKeyboard
	If hMidiOut <> 0 Then midiOutClose hMidiOut
	End
End If

GameLoadBar 25

Sleep 2, 1

'Buffers for images
'-----------------------------------

'Buffer for sprites file
Grafx = ImageCreate (800, 440, 0, 32)
Sleep 10, 1

'Menu and editor images
BMP (275) = ImageCreate (448, 444, RGBA (0, 0, 0, 255), 32)

'Lantern
For f = 0 To 79
	Circle BMP (275), (222, 222), 144 - f, RGBA (0, 0, 0, 255 - f * 3.17), , , , f
Next
Circle BMP (275), (222, 222), 64, RGBA (0, 0, 0, 0), , , , f

'Load sprites file
LoadSuccess = BLoad ("Res\Sprites.bmp", Grafx)
GameLoadBar 27

'Get images from file: 0-184 = tiles + player images
For f = 0 To 184
	BMP (f) = ImageCreate (32, 32, 0, 32)
	Put BMP (f), (0,0), GrafX, ((f Mod 25) * 32, Int (f/25) * 32) - Step (31, 31), PSet
Next
GameLoadBar 30

'185-196 = Explosions
For f = 0 To 11
	BMP (185 + f) = ImageCreate (32, 32, 0, 32)

	'Increasing transparency
	For G = 0 To 31
		For H = 0 To 31
			ColorRGB = Point (320 + F * 32 + G, 224 + H, GrafX)
			If ColorRGB = Magenta Then
				PSet BMP(185 + F), (G, H), RGBA (255, 0, 255, 0)
			Else
				PSet BMP(185 + F), (G, H), RGBA (rgba_R(ColorRGB), rgba_G(ColorRGB), rgba_B(ColorRGB), 255 - f * 21)
			End If
		Next
	Next
Next
GameLoadBar 33

'197 - 208 = Numbers (for info bar)
For f = 0 To 11
	BMP (197 + f) = ImageCreate (10, 15, 0, 32)
	Put BMP (197 + f), (0,0), GrafX, (f * 10 + 672, 256) - Step (9, 14), PSet
Next
GameLoadBar 35

'209 = Oxygen bar
BMP (209) = ImageCreate (100, 16, 0, 32)
Put BMP (209), (0,0), GrafX, (672, 272) - (771, 287), PSet

'210 = Info bar
BMP (210) = ImageCreate (800, 56, 0, 32)
Put BMP (210), (0,0), GrafX, (0, 352) - (799, 407), PSet

'211 = Game Logo
BMP (211) = ImageCreate (220, 96, 0, 32)
Put BMP (211), (0,0), GrafX, (0, 256) - (219, 351), PSet

'212 = Game over (212)
BMP (212) = ImageCreate (128, 64, 0, 32)
Put BMP (212), (0,0), GrafX, (672, 288) - (799, 351), PSet

'213 - 232 = Water
'233 - 235 = skewers
'236 = Used scaffold
'237 =  BkGround image for water
For f = 0 To 24
	BMP (213 + f) = ImageCreate (32, 32, 0, 32)
	Put BMP (213 + f), (0,0), GrafX, (F * 32, 408) - Step (31, 31), PSet
Next

'238 = Little arrows for timer
BMP (238) = ImageCreate (58, 15, 0, 32)			
Put BMP (238), (0, 0), Grafx, (7, 385) - (64, 399), PSet
GameLoadBar 40

'239 - 246 = fading numbers (for showing points when a gem is taken)
For F = 0 To 7
	BMP (239 + f) = ImageCreate (90, 15, 0, 32)			
	For H = 0 To 89
		For I = 0 To 14
			ColorRGB = (Point (288 + H, 320 + I, GrafX) And 255) * (1 - F * .1)
			PSet BMP (239 + f), (H, I), RGBA (255, 255, 0, ColorRGB)
		Next
	Next
Next
GameLoadBar 45

'247 = Font for texts
Grafx2 = ImageCreate(FontFileWidth, 23, 0, 32)
BMP (247)= ImageCreate(FontFileWidth, 22, 0, 32)
LoadSuccess = BLoad ("Res\Fonte.bmp", Grafx2)

'Read file and find characters
h=0
CharacPosition (0,0) = 0
For g = 0 To FontFileWidth - 1
	For f = 0 To 21
		ColorRGB = Point (g, f, grafx2) And 255
		PSet BMP (247), (g, f), RGBA (255, 255, 255, ColorRGB)
	Next           
	If (point(g, 22, Grafx2) and 1) = 0 then
		CharacPosition (h, 1)= G
		h += 1
		If g < FontFileWidth - 1 Then CharacPosition (h, 0) = g + 1
	end if
Next
GameLoadBar 50

'248 - 251 = Message boxes
For h = 0 To 3
	BMP (248 + h) = ImageCreate (64, 64, 0, 32)
	For F = 0 To 63
		For G = 0 To 63
			ColorRGB = Point (288 + h * 64 + F, 256 + G, GrafX)
			If ColorRGB = Magenta Then
				PSet BMP (248 + h), (F, G), RGBA (255, 0, 255, 0)
			Else
				PSet BMP (248 + h), (F, G), RGBA (rgba_R(ColorRGB), rgba_G(ColorRGB), rgba_B(ColorRGB), 192)
			End If
		Next
	Next
Next
GameLoadBar 55

'252 = FreeBasic's HORSE
BMP (252) = ImageCreate (59, 47, 0, 32)
Put BMP(252), (0, 0), grafx, (225,256) - (283,302), PSet

'Sets alpha for foreground images
For H = 25 To 36
	For G = 0 To 31
		For F = 0 To 31
			ColorRGB = Point (F, G, BMP (H))
			If ColorRGB = Magenta Then
				PSet BMP (H), (F, G), RGBA (255, 0, 255, 0)
			Else
				If H < 32 Then
					PSet BMP (H), (F, G), RGBA (rgba_R(ColorRGB), rgba_G(ColorRGB), rgba_B(ColorRGB), 191)
				Else
					PSet BMP (H), (F, G), RGBA (rgba_R(ColorRGB), rgba_G(ColorRGB), rgba_B(ColorRGB), 127)
				End If
			End If
		Next
	Next
Next
GameLoadBar 60

'253 - 258 = Icons for messages
For h = 0 To 5
	BMP (253 + h) = ImageCreate (42, 48, 0, 32)
	Put BMP(253 + H), (0, 0), GrafX, (544 + (h Mod 3) * 42, 256 + (Int (h/3) * 48)) - Step (41, 47), PSet
Next

'259 - 273 = Fissures - For walls being destroyed (down, left, right)
For F= 259 To 273
	BMP (F) = ImageCreate (32, 32, 0, 32)
Next
GameLoadBar 65
For f = 0 To 4
	Put BMP (264 + F), (0, 0), GrafX, (378 + F * 32, 320) - Step (31, 31), PSet
	For g = 0 To 31
		Put BMP (269 + f), (g, 0), GrafX, (409 + F * 32 - G, 320) - Step (0, 31), PSet
		For h = 0 To 31
			PSet BMP (259 + F), (31 - H, G), Point (378 + F * 32 + G, 320 + H, GrafX)
		Next
	Next
Next
GameLoadBar 70

'Small numbers - cols and rows in editor
BMP (274) = ImageCreate (60, 8, 0, 32)
Put BMP (274), (0, 0), GrafX, (288, 335) - (347, 342), PSet

'Destroy buffer used to load image from file
ImageDestroy GrafX
GameLoadBar 75

'Menu and editor images
BMP (276) = ImageCreate (630, 128, 0, 32)
GrafX = ImageCreate (723, 128, 0, 32)

'Load menu and editor images file
LoadSuccess = BLoad ("Res\Menu.bmp", GrafX)
Put BMP (276), (0,0), GrafX, (0, 0) - (629, 127), PSet
BMP (277) = ImageCreate (96, 96, 0, 32)

'Create images for editor (tool bar and others)
BMP (278) = ImageCreate (73, 19, RGBA(255, 0, 255, 0), 32)
For f = 0 To 3
	Line bmp (278), (3 - f, f) - (69 +  f, 18 - f), RGBA (0, 0, 0, 255), b
Next
GameLoadBar 80

Line bmp (278), (4, 4) - (68, 14), RGBA (0, 0, 0, 64), Bf
BMP (279) = ImageCreate (611, 21, RGBA (255, 0, 255, 0), 32)
Line bmp (279), (0,0) - (22, 20), RGB (128, 128, 128), b
Line bmp (279), (23,0) - (45, 20), RGB (128, 128, 128), b
Line bmp (279), (46,0) - (564, 20), RGB (128, 128, 128), b
Line bmp (279), (565,0) - (587, 20), RGB (128, 128, 128), b
Line bmp (279), (588,0) - (610, 20), RGB (128, 128, 128), b
Put bmp (279), (3, 2), GrafX, (688, 66) - (703, 82), PSet
Put bmp (279), (30, 2), GrafX, (695, 66) - (703, 82), PSet
Put bmp (279), (572, 2), GrafX, (677, 66) - (685, 82), PSet
Put bmp (279), (592, 2), GrafX, (677, 66) - (692, 82), PSet
Line bmp (279), (48, 4) - (562, 17), RGBA (255, 255, 255, 255), B
Line bmp (279), (48, 4) - (561, 16), RGBA (128, 128, 128, 255), B
Line bmp (279), (49, 5) - (52, 16), RGBA (255, 255, 0, 255), BF
Line bmp (279), (53, 5) - (152, 16), RGBA (80, 160, 160, 255), BF
Line bmp (279), (153, 5) - (208, 16), RGBA (185, 106, 106, 255), BF
Line bmp (279), (209, 5) - (561, 16), RGBA (100, 180, 100, 255), BF
GameLoadBar 85

BMP (280) = ImageCreate (187, 56, RGBA (255, 0, 255, 0), 32)
For F = 0 To 1
	For g = 0 To 1
		Line bmp (280), (g * 27, F * 28) - Step (26, 27), RGBA (96, 96, 96, 255), B
		Put bmp (280), (2 + g * 27, 3 + F * 28), GrafX, (631 + G * 23, f * 23)- Step (22, 22), PSet
	Next
	For g = 0 To 2
		Line bmp (280), (106 + g * 27, F * 28) - Step (26, 27), RGBA (96, 96, 96, 255), B
		Put bmp (280), (108 + g * 27, 3 + F * 28), GrafX, (631 + F * 23, 46 + G * 23)- Step (22, 22), PSet
	Next
Next
Line bmp (280), (54, 0) - Step (51, 55), RGBA (0, 0, 0, 255), B
Line bmp (280), (55, 0) - Step (49, 55), RGBA (128, 128, 128, 255), B
Put bmp (280), (57, 3), Grafx, (677, 0) - (722, 49), PSet
BMP (281) = ImageCreate (46, 16, RGBA (192, 192, 192, 255), 32)
Put bmp (281), (0, 0), grafX, (677, 50) - (722, 65), PSet

'Destroy buffer used to load image from file
ImageDestroy GrafX
GameLoadBar 90	'(90% -> almost finishing load)

'Menu Hilight
Sleep 10, 1
For F=0 To 15
	Circle BMP (277), (f + 15, f + 15), 15, RGBA(64, 255, 64, f * 16), , , , f
	Circle BMP (277), (f + 15, 80 - f), 15, RGBA(64, 255, 64, f * 16), , , , f
	Circle BMP (277), (80 - f, f + 15), 15, RGBA(64, 255, 64, f * 16), , , , f
	Circle BMP (277), (80 - f, 80 - f), 15, RGBA(64, 255, 64, f * 16), , , , f
	Line BMP (277), (16 + f, f) - (79 - f, 95 - f), RGBA(64, 255, 64, f * 16), bf
	Line BMP (277), (f , 16 + f) - (95 - f, 79 - f), RGBA(64, 255, 64, f * 16), bf
Next

GameLoadBar 95

'Sound for fallen straw
VSound (1, 1).COn1 = &H76c0 : VSound (1, 1).COn2 = &H6f3490: VSound (1, 1).COff = &H6f3480	'Over soil, straw, walls or stairs
VSound (1, 2).COn1 = &H76c0 : VSound (1, 2).COn2 = &H6f2d90: VSound (1, 2).COff = &H6f2d80	'Over indest. walls, rocks, gems, scaffolds or skewers
VSound (1, 3).COn1 = &H76c0 : VSound (1, 3).COn2 = &H6f3b90: VSound (1, 3).COff = &H6f3b80	'Over cars, items or bombs
VSound (1, 4).COn1 = &H75c0 : VSound (1, 4).COn2 = &H6f3f90: VSound (1, 4).COff = &H6f3f80	'Over wood box

'Sounds for fallen rocks, gems and used scaffold
VSound (2, 1).COn1 = &H7fc1 : VSound (2, 1).COn2 = &H774391: VSound (2, 1).COff = &H774381	'Over soil, straw, walls or stairs
VSound (2, 2).COn1 = &H7fc1 : VSound (2, 2).COn2 = &H774491: VSound (2, 2).COff = &H774481	'Over indest. walls, rocks, gems, scaffolds or skewers
VSound (2, 3).COn1 = &H7fc1 : VSound (2, 3).COn2 = &H774591: VSound (2, 3).COff = &H774581	'Over cars, items or bombs
VSound (2, 4).COn1 = &H7fc1 : VSound (2, 4).COn2 = &H774691: VSound (2, 4).COff = &H774681	'Over wood box

'Sounds for fallen cars, items and bombs
VSound (3, 1).COn1 = &H2fc2 : VSound (3, 1).COn2 = &H7f4c92: VSound (3, 1).COff = &H7f4c82	'Over soil, straw, walls or stairs
VSound (3, 1).COn1 = &H2fc2 : VSound (3, 2).COn2 = &H7f4892: VSound (3, 2).COff = &H7f4882	'Over indest. walls, rocks, gems, scaffolds or skewers
VSound (3, 1).COn1 = &H2fc2 : VSound (3, 3).COn2 = &H7f4392: VSound (3, 3).COff = &H7f4382	'Over cars, items or bombs	
VSound (3, 1).COn1 = &H2fc2 : VSound (3, 4).COn2 = &H7f3c92: VSound (3, 4).COff = &H7f3c82	'Over wood box

'Sounds for fallen wood box
VSound (4, 1).COn1 = &H73c3 : VSound (4, 1).COn2 = &H7f3c93: VSound (4, 1).COff = &H7f3c83	'Over soil, straw, walls or stairs
VSound (4, 2).COn1 = &H73c3 : VSound (4, 2).COn2 = &H7f4393: VSound (4, 2).COff = &H7f4383	'Over indest. walls, rocks, gems, scaffolds or skewers
VSound (4, 3).COn1 = &H73c3 : VSound (4, 3).COn2 = &H7f4093: VSound (4, 3).COff = &H7f4083	'Over cars, items or bombs
VSound (4, 4).COn1 = &H73c3 : VSound (4, 4).COn2 = &H7f3893: VSound (4, 4).COff = &H7f3883	'Over wood box

'Sounds for drill being used
VSound (5, 1).COn1 = &H7cc4 : VSound (5, 1).COn2 = &H7f5994: VSound (5, 1).COff = &H7f5984	'for straw or wall
VSound (5, 2).COn1 = &H7cc4 : VSound (5, 2).COn2 = &H7f5a94: VSound (5, 2).COff = &H7f5a84	'for rock or gems
VSound (5, 3).COn1 = &H7cc4 : VSound (5, 3).COn2 = &H7f5b94: VSound (5, 3).COff = &H7f5b84	'for cars, items or bombs
VSound (5, 4).COn1 = &H7cc4 : VSound (5, 4).COn2 = &H7f5c94: VSound (5, 4).COff = &H7f5c84	'for wood box

'Sounds for pickaxe being used
VSound (6, 1).COn1 = &H7fc5 : VSound (6, 1).COn2 = &H7f5795: VSound (6, 1).COff = &H7f5785	'for straw or wall
VSound (6, 2).COn1 = &H7fc5 : VSound (6, 2).COn2 = &H7f5695: VSound (6, 2).COff = &H7f5685	'for rock or gems
VSound (6, 3).COn1 = &H7fc5 : VSound (6, 3).COn2 = &H7f5595: VSound (6, 3).COff = &H7f5585	'for cars, items or bombs
VSound (6, 4).COn1 = &H7fc5 : VSound (6, 4).COn2 = &H7f5495: VSound (6, 4).COff = &H7f5485	'for wood box

'Sounds for explosions and others
VSoundEx (1).COn1 = &H7fc6 : VSoundEx (1).COn2 = &H7f3296: VSoundEx (1).COff = &H7f3286	'Small bomb explosion
VSoundEx (2).COn1 = &H7fc6 : VSoundEx (2).COn2 = &H7f2f96: VSoundEx (2).COff = &H7f2f86	'Big bomb explosion
VSoundEx (3).COn1 = &H7fc6 : VSoundEx (3).COn2 = &H7f2396: VSoundEx (3).COff = &H7f2386	'Player has died
VSoundEx (4).COn1 = &H72c6 : VSoundEx (4).COn2 = &H6f4096: VSoundEx (4).COff = &H6f4086	'Item was taken
VSoundEx (5).COn1 = &H72c6 : VSoundEx (5).COn2 = &H5f4896: VSoundEx (5).COff = &H5f4886	'Gem was taken
VSoundEx (6).COn1 = &H15c6 : VSoundEx (6).COn2 = &H6f2996: VSoundEx (6).COff = &H6f2986	'Can't do - warning
VSoundEx (7).COn1 = &H7ec6 : VSoundEx (7).COn2 = &H6f4196: VSoundEx (7).COff = &H6f4186	'Objects moving (when pushed)

'---------------------------------------------------
ReadInternalMine 0, 1

GameLoadBar 100
Sleep 2, 1
Game.LivesOnStart = 2

If FileExists("Config.min") Then
	Open "Config.min" For Input As #1
	Input #1, Game.Volume
	Input #1, Game.MaxReached
	Input #1, CurrentLanguage
	Close #1
Else
	Game.Volume   = 64
	Game.MaxReached = 1
	CurrentLanguage = "Portugues"
End If

ReadLanguagePack (CurrentLanguage)

If Game.MaxReached < 1 Then Game.MaxReached = 1
If Game.Volume < 0 Or Game.Volume > 127 Then Game.Volume = 64

MidiOutSetVolume(0, (Game.Volume Shl 9) Or (Game.Volume Shl 1))

'Game speed / FPS
Game.Steps = 8
Game.DelayMSec = 33
Game.StepSize = 4   'pixels

'Read top scores
ReadRecordTable
ConfirmDel = 0

'Start parameters for game
ResetGame
ResetLife
ClearMine
ChangeStatus MenuScreen
TmpSleep = 25
Sleep 20, 1

Cls
ScreenSet 0, 1
ActiveScreen = 0

'-----------------------------------------
'MAIN
'-----------------------------------------

PlayGame

'-----------------------------------------
'END
'-----------------------------------------

'Close midi and image buffers
If hMidiOut <> 0 Then midiOutClose hMidiOut
For f= 0 To 277
	ImageDestroy BMP (f)
Next

End		

'*****************************************
'*****************************************
'*****************************************
'SUB's and FUNCTION's
'*****************************************
'*****************************************
'*****************************************


'-------------------------------------------------------------------------------------------

'Draws BkGround for screens while not playing

Sub DrawMenuBackground
Dim F as integer
	cRed = (Cred + 2) Mod 256
	For F = 0 To 119
		CRed2 = (cred + f) Mod 256
		If CRed2 > 127 Then CRed2 = 255 - cred2
		Line (0, f * 5) - (799, f * 5 + 9), RGB(cred2 * VRed, cred2 * VGreen, Cred2 * VBlue), bf
	Next
End Sub

'-------------------------------------------------------------------------------------------

'Draws the progress bar (program load)

Sub GameLoadBar (perc As Integer)
	Line (25,525) - (25 + perc * 7.51, 549), RGB(127,127,255),bf
	Sleep 2, 1
End Sub


'-------------------------------------------------------------------------------------------

'Draws the Scene

Sub DrawScene

	'Local variables
	Dim As Integer XR, YR, X1, Y1, X1R, Y1R, VPlayerR, Water0, DF1, DF2, DG1, DG2, ImgPt, F, G, H, I
	Dim As Integer TRX, TRY, TRXa, TRYa, Exploding
	
	'Check if there's any explosion, to shake the screen
	For f = 0 To 10
		If Explosion(f).Kind > 0 And Explosion(f).Time < 10 Then Exploding = 1
	Next
	
	'Calculates area (of mine) to draw
	If (Game.Status = MapMode) Or (Game.Status = Top10) Or (Game.Status = Editor) Then
		TRX  = MapX
		TRY  = MapY
		TRXa = 0
		TRYa = 0
		
	Else 
		With VPlayer
			'Compute X coords to begin drawing
			If Mine.Width < 25 Or .X < 12 Then
				TRX  = 0
				TRXa = 0
			ElseIf .X > Mine.Width - 12 Then
				TRX  = Mine.Width - 24
				TRXa = 0
			ElseIf .CurrDirection = 1 Then
				TRX  = .X - 12
				TRXa = -.StepNumber * Game.StepSize
			ElseIf .CurrDirection = 2 Then
				TRX  = .X - 13
				TRXa = (.StepNumber - Game.Steps) * Game.StepSize
			Else	
				TRX  = .x - 12
				TRXa = 0
			End If
			
			If .X = 12 And .CurrDirection = 2 Then
				TRX  = 0
				TRXa = 0
			End If  
			
			If .x = Mine.Width - 12 And .CurrDirection = 1 Then TRXa = 0
			
			'Compute Y coords to begin drawing
			If Mine.Height < 17 Or .Y < 8 Then
				TRY  = 0
				TRYa = 0
			ElseIf .Y > Mine.Height - 8 Then
				TRY  = Mine.Height - 16
				TRYa = 0
			ElseIf .CurrDirection > 3 Then
				TRY  = .Y - 8
				TRYa = -.StepNumber * Game.StepSize
			ElseIf .CurrDirection = 3 Then
				TRY  = .Y - 9
				TRYa = (.StepNumber - Game.Steps) * Game.StepSize
			Else	
				TRY  = .Y - 8
				TRYa = 0
			End If
			
			If .Y = 8 And .CurrDirection = 3 Then
				TRY  = 0
				TRYa = 0
			End If  
			
			If .Y = Mine.Height - 8 And .CurrDirection > 3 Then TRYa = 0
			
		End With                                           
	End If

	'If in editor or normal mine, draw hole screen
	If (Mine.DarkType = 0) Or (Game.Status = Editor) Then
		df1 = 0
		df2 = 25
		dg1 = 0
		dg2 = 17
	Else
		'If in a dark mine, clear screen and redraws only a part of it
		Cls
		df1 = VPlayer.x - trx - 5
		df2 = VPlayer.x - trx + 5
		dg1 = VPlayer.y - try - 5
		dg2 = VPlayer.y - try + 5
		If df1 < 0  Then df1 = 0
		If df2 > 25 Then df2 = 25
		If dg1 < 0  Then dg1 = 0
		If dg2 > 17 Then dg2 = 17
	End If

	'Player image group
	If VPlayer.UsingOxygen = 0 Then		'Normal = red or green clothes
		VPlayerR = Game.Player * 46
	Else                    
		VPlayerR = 23					'Using Oxygen
	End If

	'Shakes screen, if applicable
	If Exploding > 0 Then
		TRXA = trxa + Rnd * 11 - 5
		trya = TRYA + Rnd * 11 - 5
	ElseIf Game.Status = WonGame Then
		TRXA = trxa + Rnd * 3 - 1
		trya = TRYA + Rnd * 3 - 1
	End If

	'Begins drawing
	'----------------

	'Draws Background layer (uses pset) 
	For f = df1 To df2
		For g = dg1 To dg2
			If BkGround (TRX + f, TRY + g) > 0 Then
				Put (TRXa + f * 32, TRYa + g * 32), BMP (BkGround (TRX + f, TRY + g)),PSet
			Else
				Put (TRXa + F * 32, TRYa + g * 32), BMP (237), PSet
			End If
		Next
	Next
	
	'Draws Objects layer (uses trans)  -  don't draw if in editor and layer is hidden
	If (Game.Status <> Editor) Or (EdShow =1 Or EdShow = 2) Then  
		For f = df1 To df2
			For g = dg1 To dg2
				XR = 0
				YR = 0
				'Position of falling object
				If Object (TRX + f,TRY + g).IsFalling = 1 Then 
					YR = Object (TRX + f,TRY + g).StepNumber * Game.StepSize
				Else
				
				'Position of objects being pushed
					Select Case Object (TRX + f,TRY + g).BeingPushed
					Case 1
						XR = Object (TRX + f,TRY + g).StepNumber * Game.StepSize
					Case 2
						XR = -Object (TRX + f,TRY + g).StepNumber * Game.StepSize
					End Select
				End If
				
				'Draws the object in its correct position
				Put (TRXa + f * 32 + XR, TRYa + g * 32 + YR), BMP (TpObject (Object (TRX + F,TRY + G).tp).Img), Trans
			Next
		Next
	End If
	
	'Draws Player (uses trans)
	If Game.Status <> WonGame And Game.Status <> Top10 And Game.Status <> GameOver And VPlayer.Died = 0 Then
		
		'Gets position
		With VPlayer
			
			'Choose image
			
			'In Editor?
			If Game.Status = Editor Then
				.Img = ImgStopped (0)
				.ImgX = .x * 32
				.ImgY = .y * 32
			Else
				
				'Using pickaxe?
				If .UsingPickaxe > 0 Then
					.Img = ImgUsing (0, .UsingPickaxe Mod 2) + VPlayerR 
					Put (TRXa + .ImgX - (TRX * 32), TRYa + .ImgY - (TRY * 32)+ 32), BMP (259 + Int((.UsingPickaxe / Game.Steps) * 2.35)), Trans
					
				'Using drill?
				ElseIf .UsingDrill>0 Then
					.img = ImgUsing (.DrillDirection, .UsingDrill Mod 2) + VPlayerR
					If .DrillDirection = 1 Then
						Put (TRXa + .ImgX - (TRX * 32) + 32, TRYa + .ImgY - (TRY * 32)), BMP (264 + Int((.UsingDrill / Game.Steps) * 2.35)), Trans
					Else
						Put (TRXa + .ImgX - (TRX * 32) - 32, TRYa + .ImgY - (TRY * 32)), BMP (269 + Int((.UsingDrill / Game.Steps) * 2.35)), Trans
					End If
					
				'Stopped?
				ElseIf .CurrDirection = 0 Then
					.img = ImgStopped (.LastDirection) + VPlayerR 
					
				'Moving? Or pushing objects?
				Else
					.img = ImgMoving (.CurrDirection + (.Pushing * 5) - 1, .StepNumber Mod 4) + VPlayerR 
				End If
				
				'Calculates the position (in accordance with the movement)
				Select Case .CurrDirection
				Case 1 'Right
					.ImgX = .x * 32 + (.StepNumber * Game.StepSize)
				Case 2 'Left
					.ImgX = .x * 32 - (.StepNumber * Game.StepSize)
				Case 3 'Climbing
					.imgY = .y * 32 - (.StepNumber * Game.StepSize)
				Case 4, 5 'Down / Falling
					.imgY = .y * 32 + (.StepNumber * Game.StepSize)
				Case Else 'No movement
					.ImgX = .x * 32
					.ImgY = .y * 32
				End Select
			End If
			
			'Draws the player
			Put (TRXa + .ImgX - (TRX * 32), TRYa + .ImgY - (TRY * 32)), BMP (.Img), Trans
		End With	
	End If

	'Draws ForeGround layer (uses alpha)   - don't draw if in editor and layer is hidden
	If (Game.Status <> Top10) And (Game.Status <> Editor Or EdShow >= 2) Then
		For f = df1 To df2
			For g = dg1 To dg2
				If FrGround (TRX + f,TRY + g) > 0 Then
					Put (TRXa + f * 32, TRYa + g * 32), BMP (FrGround (TRX + f, TRY + g) + 24), Alpha
				End If
			Next
		Next
	End If

	'Draws Water (uses Alpha 95)
	Water0 = (Game.seqCycle * 13) Mod 20   'movement
	For f = df1 To df2
		For g = dg1 To dg2
			If BkGround (TRX + f, TRY + g) = 0 Then
				Put (TRXa + f * 32, TRYa + g * 32), BMP (213 + (Water0 + F + g * 6) Mod 20), Alpha, 95
			End If
		Next
	Next

	
	If Game.Status <> Editor Then
		
		'Last images over playing area
		
		'Lantern
		If Mine.DarkType = 1 Then
			Put (TRXa + VPlayer.ImgX - (TRX * 32) - 208, TRYa + VPlayer.ImgY - (TRY * 32) - 208), BMP (275), (0, 0) - (443, 443), Alpha
		End If
		
		'Explosions
		For f = 0 To 10
			With Explosion(f)
				
				If .Kind > 0 Then
					For G = (.Kind = 2) To - (.Kind = 2)
						For H = -1 To 1
							Put(TRXa + (.x - TRX + H) * 32, TRYa + (.y - TRY + G) * 32), BMP (185 + Int(.Time / 3)), Alpha
						Next
					Next
				Else
					.Time = 0
				End If
				
				'Incrementa contador
				.Time += 1
				If .Time >= 35 Then
					.Time = 0
					.Kind  = 0
				EndIf
			End With
		Next
		
		'Points - when a gem is taken
		For I = 0 To 9
			With Msg (I)
				If .Cycle > 0 Then
					WritePoints (.Score, TRXa + (.X -TRX) * 32 + 16, TRYa + (.Y - TRY) * 32 - 12 + Int(.Cycle/4), Int((127 - .Cycle) / 16))
					.Cycle -= 1
				End If
			End With
		Next
	Else
	
	'Editor
	
		'Grid
		Select Case edgrid
		Case 6, 7
			For f=0 To 23
				Line(f * 32 + 32, 0) - (f * 32 + 32, 543), &HFF00FF
			Next
			For f=0 To 15
				Line(0, f * 32 + 32) - (799, f * 32 + 32), &HFF00FF
			Next
		Case 2, 3
			For f=0 To 23
				Line(f * 32 + 32, 0) - (f * 32 + 32, 543), &HFFFFFF
			Next
			For f=0 To 15
				Line(0, f * 32 + 32) - (799, f * 32 + 32), &HFFFFFF
			Next
		Case 0, 1
			For f=0 To 23
				Line(f * 32 + 32, 0) - (f * 32 + 32, 543), &H1F1F1F
			Next
			For f=0 To 15
				Line(0, f * 32 + 32) - (799, f * 32 + 32), &H1F1F1F
			Next
		End Select
		
		'Cols / Rows number
		If edgrid Mod 2 = 0 Then
			For f = 0 To 24
				WriteNumberLit (MapX + f, 11 + f * 32, 0)
			Next
			For f = 0 To 16
				WriteNumberLit (Mapy + f, 0, 11 + f * 32)
			Next
		End If
		
	End If
	
	If Game.Status <> Editor Then
	
		'Info bar (when playing)
		
		Put (0, 544), BMP (210), PSet
		
		With VPlayer
			
			'Score
			WriteNumber .Score, 6, 7, 577, 0
			
			'Mine number
			'If Game.Status <> DemoMode Then
				WriteNumber .CurrentMine, 3, 96, 577, 0
			'end if
			
			'Oxygen bar
			Put (151, 576), BMP (209), (0, 0) - Step (.Oxygen, 15), PSet
			
			'Oxygen bottles
			WriteNumber .ItOxygen, 1, 296, 575, 0
			
			'Scaffolds
			WriteNumber .ItScaffold, 1, 347, 575, 0
			
			'Pickaxes
			WriteNumber .ItPickaxe, 1, 393, 575, 0
			
			'Drills
			WriteNumber .ItDrill, 1, 445, 575, 0
			
			'Small bombs
			WriteNumber .ItBombS, 1, 489, 575, 0
			
			'Big bombs
			WriteNumber .ItBombB, 1, 532, 575, 0
					
			'Gems to be taken
			WriteNumber Mine.Gems, 2, 550, 575, 0         
			
			'Lives
			WriteNumber .Lives, 2, 582, 576, 0
			
		End With
		
		'Time limit
		If Mine.Time > 0 Then
			'Mine time
			WriteNumber Int(Mine.Time / 60), 2, 655, 556, 1
			WriteNumber Mine.Time Mod 60, 2, 683, 556, 1
			If Mine.Time - VPlayer.Time >= 20 Or Game.Status <> Playing Then	'Ok, you have time...
				Put (642, 578), BMP(238), (48, 0) - Step (9, 14), Trans
			Else	
				'Hurry up!
				If (Game.seqCycle Mod 2 = 1) Or (Game.Status = WonGame) Then Put (642, 578), BMP (238), (Int ((Mine.Time - VPlayer.Time) / 5) * 12, 0) - Step (9, 14), Trans
			End If
		End If
		
		'Timer blinking dots
		If Game.seqCycle Mod 2 = 1 And VPlayer.Died = 0 And Started > 0 And Game.Status <> WonGame Then
			Line (679, 582) - (680, 590), Point (679, 581), bf
		End If
		
		'Your time
		WriteNumber Int(VPlayer.Time / 60), 2, 655, 578, 1
		WriteNumber VPlayer.Time Mod 60, 2, 683, 578, 1
		
		'Show messages for demo mode
		If Game.Status = DemoMode Then
			DemoCycle = DemoCycle + 1
			Select Case MSGDemo
			Case 1
				WriteCentered TXT(11), 430, 1, 0
				WriteCentered TXT(12), 460, 1, 0
			Case 2
				WriteCentered TXT(13), 445, 1, 0
			Case 3
				WriteCentered TXT(14), 430, 1, 0
				WriteCentered TXT(15), 460, 1, 0
			Case 4
				WriteCentered TXT(16), 430, 1, 0
				WriteCentered TXT(17), 460, 1, 0
			Case 5
				WriteCentered TXT(18), 445, 1, 0
			Case 6
				WriteCentered TXT(19), 430, 1, 0
				WriteCentered TXT(20), 460, 1, 0
			Case 7
				WriteCentered TXT(21), 430, 1, 0
				WriteCentered TXT(22), 460, 1, 0
			Case 8
				WriteCentered TXT(23), 445, 1, 0
			Case 9
				WriteCentered TXT(24), 445, 1, 0
			Case 10
				WriteCentered TXT(25), 430, 1, 0
				WriteCentered TXT(26), 460, 1, 0
			Case 11
				WriteCentered TXT(27), 430, 1, 0
				WriteCentered TXT(28), 460, 1, 0
			Case 12
				WriteCentered TXT(29), 430, 1, 0
				WriteCentered TXT(30), 460, 1, 0
			Case 13
				WriteCentered TXT(31), 430, 1, 0
				WriteCentered TXT(32), 460, 1, 0
			Case 14
				WriteCentered TXT(33), 430, 1, 0
				WriteCentered TXT(34), 460, 1, 0
			Case 15
				WriteCentered TXT(35), 430, 1, 0
				WriteCentered TXT(36), 460, 1, 0
			Case 16
				WriteCentered TXT(37), 430, 1, 0
				WriteCentered TXT(38), 460, 1, 0
			Case 17
				WriteCentered TXT(39), 430, 1, 0
				WriteCentered TXT(40), 460, 1, 0
			Case 18
				WriteCentered TXT(41), 445, 1, 0
			Case 19
				WriteCentered TXT(42), 430, 1, 0
				WriteCentered TXT(43), 460, 1, 0
			Case 20
				WriteCentered TXT(44), 430, 1, 0
				WriteCentered TXT(45), 460, 1, 0
			Case 21
				WriteCentered TXT(46), 430, 1, 0
				WriteCentered TXT(47), 460, 1, 0
			Case 22
				WriteCentered TXT(48), 430, 1, 0
				WriteCentered TXT(49), 460, 1, 0
				For F = 0 To 4
					Line (480 + f, 480)-(533 + f, 533), &HFFA000
					Line (515, 529 + f)-(533, 529 + f), &HFFA000
					Line (533 + f, 515)-(533 + f, 533), &HFFA000
				Next
			End Select
		End If
	Else
	
		'Tool bar (when editing)
		
		Line (0, 543) - (799, 543), &H000000
		
		Select Case Game.EdStatus
		Case Editing	'Draws tool bar and mouse position
			Line (1, 545) - (609, 563), &HA0A0A0, BF
			Line (0, 565) - (610, 599), &H000000, BF
			Line (611, 544) - (611, 599), &H606060
			Line (612, 544) - (612, 599), &H000000
			Line (614, 545) - (798, 598), &HA0A0A0, BF
			Line (667 , 544) - (667 , 599), &H000000
			Line (718 , 544) - (718 , 599), &H000000
			
			'Highligth option under mouse
			Select Case MousePos
			Case EdOutOfScreen
				'Nothing to do
			Case EdScreen
				DrawLine EDX1 * 32 - 3, EDY1 * 32 - 3, EDX1 * 32 + 34, EDY1 * 32 + 34, 0
			Case EdBegin
				Line (1, 545) - (21, 563), &HFFFFFF, BF
			Case EdLeft
				Line (24, 545) - (44, 563), &HFFFFFF, BF
			Case EdRight
				Line (565, 545) - (585, 563), &HFFFFFF, BF
			Case EdEnd
				Line (588, 545) - (608, 563), &HFFFFFF, BF
			Case EdBottomBar
				Line (47, 545) - (563, 563), &HFFFFFF, BF
			Case EdItem
				Line (Int (MouseX / 34) * 34 - 1, 565) - Step (35, 34), &HFFFFFF, BF
			Case EdNew
				Line (614, 545) - (638, 570), &HFFFFFF, BF
			Case EdOpen
				Line (641, 545) - (665, 570), &HFFFFFF, BF
			Case EdMove
				Line (614, 573) - (638, 598), &HFFFFFF, BF
			Case EdSave
				Line (641, 573) - (665, 598), &HFFFFFF, BF
			Case EdView
				Line (669, 545) - (716, 598), &HFFFFFF, BF
			Case EdChangeGrid
				Line (720, 545) - (744, 570), &HFFFFFF, BF
			Case EdClearArea
				Line (747, 545) - (771, 570), &HFFFFFF, BF
			Case EdTestMine
				Line (774, 545) - (798, 570), &HFFFFFF, BF
			Case EdUndo
				Line (720, 573) - (744, 598), &HFFFFFF, BF
			Case EdRedo
				Line (747, 573) - (771, 598), &HFFFFFF, BF
			Case EdExit
				Line (774, 573) - (798, 598), &HFFFFFF, BF
			End Select
			
			'Tool bar
			Put (0, 544), bmp (279), Trans
			
			'Object selection bar
			Put (46 + FirstItemShowed * 4.48, 545), BMP (278), Alpha
			Put (613, 544), BMP(280), Trans
			
			'Highlight selected object, if visible
			If SelectedItem >= FirstItemShowed And SelectedItem <= FirstItemShowed + 17 Then
				Line (Int (SelectedItem - FirstItemShowed) * 34 - 1, 565) - Step (35, 34), &H40ff40, BF
			End If
			
			'Draw objects to select (visible range)
			For f = 0 To 17
				DrawItem f * 34 + 1, 568, FirstItemShowed + F
			Next
			
			'Layer selector
			If EdShow = 0 Or Edshow = 1 Then Put (670, 547), Bmp (281), Trans
			If EdShow = 0 Or Edshow = 3 Then Put (670, 564), Bmp (281), Trans
			
		Case Selecting	'Draws selected area and message
			DrawBox 24, 1, 4, 400, 572
			WriteCentered TXT(109), 562
			DrawLine EDXX1 * 32 - 3, EDYY1 * 32 - 3, EDXX2 * 32 + 34, EDYY2 * 32 + 34, 1
		Case EdMoving	'Shows message for area moving
			DrawBox 24, 1, 4, 400, 572
			WriteCentered TXT(110), 562
		Case Clearing0, Clearing1		'Shows area select to clear and message
			DrawBox 24, 1, 4, 400, 572
			WriteCentered TXT(111), 562
			If Game.EdStatus = Clearing0 Then
				DrawLine EDX1 * 32 - 3, EDY1 * 32 - 3, EDX1 * 32 + 34, EDY1 * 32 + 34, 3
			Else
				DrawLine EDXX1 * 32 - 3, EDYY1 * 32 - 3, EDXX2 * 32 + 34, EDYY2 * 32 + 34, 2
			End If
		End Select
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Shows points earned when a gem is taken (fading out)

Sub WritePoints (Points As Integer, X As Integer, Y As Integer, Fading As Integer)
	Dim As String StrNum, NumTxt
	Dim As Integer X1, NumVal, F
	
	'Passa o número para Text
	StrNum= Str(Points)
	X1 = X - (Len (StrNum) * 6)
	For f = 1 To Len (StrNum)
		NumTxt = Mid$(StrNum, f, 1)
		NumVal = Val (NumTxt)
		Put (x1 + f * 12 - 12, Y), BMP (239 + Fading), (NumVal * 9, 0) - Step (8,14), Alpha
	Next
End Sub

'-------------------------------------------------------------------------------------------

'Writes a number - for info bar (digital type appearance)

Sub WriteNumber (ByVal Number As Long, Length As  Integer, X1 As Integer, Y1 As Integer, Aligns As Integer)
	Dim As String StrNum, NumTxt 
	Dim As Integer NumVal, F
	
	If Aligns = 0 Then 
		StrNum = Right(Space (Length) & Str(Number), Length)
	Else
		StrNum= Right("0000000000" & Str(Number), Length)
	End If
	If Len (StrNum) < Len (Str(Number)) Then StrNum = String (Length, "+")

	For f= 1 To Length
		NumTxt = Mid$ (StrNum, f, 1)
		If NumTxt = " " Then
			NumVal = 0
		ElseIf NumTxt = "+" Then
			NumVal = 11
		Else
			NumVal = Val (NumTxt) + 1
		End If
		Put (x1 + f * 12 - 12, Y1), BMP (197 + NumVal), PSet
	Next
End Sub

'----------------------------------------------------------------------

'Writes Texts

Sub WriteTXT (ByVal Text As String, x1 As Integer, y1 As Integer, Bold As Integer = 0, BoldV As Integer = 0)
	Dim As Integer F, PosL, G, H
	For F = 1 To Len(Text)
		PosL = InStr(Lt, Mid$(Text, F, 1)) - 1
		If PosL = -1 Then
			X1 += 8
		Else
			For H = 0 To BoldV
				For G = 0 To Bold
					Put(X1 + G, Y1 + H), BMP (247), (CharacPosition (PosL, 0), 0) - (CharacPosition (PosL, 1), 21), Alpha
				Next
			Next
			x1 += CharacPosition (PosL, 1) - CharacPosition (PosL, 0) + Bold + 2
		End If
	Next
End Sub

'----------------------------------------------------------------------

'Writes Centered Texts

Sub WriteCentered (ByVal Text As String, Y1 As Integer, Bold As Integer = 0, BoldV As Integer = 0)
	'Only for 800 x 600 screen
	WriteTXT Text, 399 - TextWidth (Text, Bold)/2, Y1, Bold, BoldV
End Sub

'----------------------------------------------------------------------

'Calculates text width - in pixels

Function TextWidth (ByVal Text As String, Bold As Integer = 0) As Integer
	Dim As Integer F, PosL, TWidth
	For F = 1 To Len (Text)
		PosL = InStr (Lt, Mid$ (Text, F, 1)) - 1
		If PosL = -1 Then
			TWidth += 8
		Else
			TWidth += CharacPosition (PosL, 1) - CharacPosition (PosL, 0) + Bold + 2
		End If
	Next
	TWidth = TWidth - Bold - 1
	Return TWidth
End Function

'-------------------------------------------------------------------------------------------

'Resets data for a new game

Sub ResetGame
	Randomize
	'Reset main variables
	With Game
		.LastExplosion = 0
		.Finish = 0
		.player = Int (Rnd * 2)
		.Cycle = 0
		.SeqCycle = 0
	End With

	With VPlayer
		.CurrentMine = 1
		.Lives = Game.LivesOnStart
		.Score = 0
	End With
End Sub

'----------------------------------------------------------------------

'Resets data for a new life (player status)

Sub ResetLife
	Dim F as integer
	With VPlayer
		.Died = 0
		.Pushing = 0
		.StepNumber = 0
		.Img = 116
		.ImgX = 0
		.ImgY = 0
		.LastDirection = 0
		.CurrDirection = 0
		.Oxygen = 10
		.UsingOxygen = 0
		.ItOxygen = 0
		.ItScaffold = 0
		.ItPickaxe = 0
		.ItDrill = 0
		.ItBombS = 0
		.ItBombB = 0
		.UsingPickaxe = 0
		.UsingDrill = 0
		.DrillDirection = 0
		.DrillDirChanged =0
		.Time = 0
	End With

	Started = 0
	StartTime = Timer + 5
	Game.LastExplosion = 0
	For f = 0 To 10
		Explosion (f).Kind = 0
		Explosion (f).Time = 0
	Next
End Sub

'----------------------------------------------------------------------

'Read a custom mine file

Sub ReadCustomMine (MineNumber As Integer, Editing As Integer = 0)
	Dim As String RowNumber, VarFileName
	
	Randomize
	ClearMine
	Mine.Gems = 0

	If MineNumber = -1 Then			'test requested by editor
		VarFileName = "Minas\TESTE.MAP"
	Else							'no test.
		ClearMineEditor
		VarFileName = "Minas\M" + Right("000" & Str(MineNumber), 3) + ".MAP"
	End If

	If FileExists (VarFileName) Then	'Opens and read the file
		If MineNumber > -1 Then Mine.Number = MineNumber
		Open VarFileName For Binary As #1
		Get #1, , Mine.Width
		Get #1, , Mine.Height
		Get #1, , Mine.DarkType
		Get #1, , Mine.Time
		
		ReadMineDetails Editing
		Close #1

	Else	'File not found
		ShowMSG 4, 8, TXT(0), TXT(50),""
		If KBKey <>"" And KBKey <> LastKBKey Then
			ChangeStatus MenuScreen
		End If
		ChangeStatus MenuScreen
		ResetGame
		ResetLife
		ClearMine
		ClearMineEditor
	End If	
	
End Sub

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------

'MAIN

Sub PlayGame
	Dim As Integer Push1, Push2, Push3, SeqDemo, F, G, H, I

	OldTimer = Int(Timer * 1000)
	If VRed + VGreen + VBlue = 0 Then VBlue = 1 'If background color ir black, then make it blue
	
	'Demo sequence movements
	KBKeysDemo=	"R01M01R15M22R23M02R24M03L23M04L16M05L12M06L08M07L05M08L04M09D04L00R01W20L00M10R24D06M11L22IC L20ICLL18ICLL16M12IV R18W50L14IV R16W50L12ICLL10" & _
				"IV R12W50L08ICLL06IV R08W50L04ICLL02IV R04W50L01M13L00IX M14D08R04M15IB L02W50R06IB L04W50R08IB L06W50R10IB L08W50R12IB L10W50R14IB L12W50R16IB L14W50" & _
				"R17M16R20IZ R21M17R22M18IB L19W20L01M19D10L00M20R24U09M21###"

	KBKey = ""

	
	'-------------
	'#############
	'-------------
	
	'Game Cycle
	
	'-------------
	'#############
	'-------------

	While Game.Finish = 0

		Game.Status0 = Game.Status
		
		'Mute channels that finished sounds
		For f = 1 To 6
			For g = 1 To 4
				If VSound (f, g).Time > 0 Then
					VSound (f, g).Time -=1
					If VSound (f, g).Time = 0 Then midiOutShortMsg (hMidiOut, VSound(f,g).COff)
				End If
			Next
			If VSoundEx (f).Time > 0 Then
				VSoundEx (f).Time -= 1
				If VSoundEx (f).Time = 0 Then midiOutShortMsg (hMidiOut, VSoundEx(f).COff)
			End If
		Next				
				
		If Inkey = Chr(255) + "k" Then	'Window's close button was clicked
			Game.Finish = 1
			GoTo FinishCycle
		End If
		
		'Reset sounds
		For f = 1 To 6
			For g = 1 To 4
				SoundPlay(f,g) = 0
			Next
		Next
		
		'Increases cycle counter 
		With Game
			.Cycle = (.Cycle + 1) Mod .Steps
			If.Cycle = 0 Then
				.SeqCycle = (.SeqCycle + 1) Mod 1500
				If .seqCycle Mod 10 = 0 Then WindowTitle "FreeBasic Miner"
			End If
		End With
		
		'Scans keyboard
		LastKBKey= KBKey
		KBKey=""
		For F = 0 To 127
			If MultiKey (f) Then KBKey = "?"
		Next
		If MultiKey(FB.SC_ENTER) Then KBKey ="["
		If MultiKey(FB.SC_ESCAPE) Then KBKey ="ESC"
		If MultiKey(FB.SC_SPACE) Then KBKey = "]"
		If MultiKey(FB.SC_DELETE) Then KBKey = "<"
		If MultiKey(FB.SC_P) Then KBKey ="P"
		If MultiKey(FB.SC_A) Then KBKey = "A"
		If MultiKey(FB.SC_B) Then KBKey = "B"
		If MultiKey(FB.SC_C) Then KBKey = "C"
		If MultiKey(FB.SC_M) Then KBKey = "M"
		If MultiKey(FB.SC_Q) Then KBKey = "Q"
		If MultiKey(FB.SC_V) Then KBKey = "V"
		If MultiKey(FB.SC_X) Then KBKey = "X"
		If MultiKey(FB.SC_Z) Then KBKey = "Z"
		If MultiKey(SC_TAB) Then KBKey = "TAB"
		If MultiKey(SC_PAGEUP) Then KBKey = "@"
		If MultiKey(SC_PAGEDOWN) Then KBKey = "#"
		If MultiKey(FB.SC_DOWN) Then KBKey ="D"
		If MultiKey(FB.SC_LEFT) Then KBKey ="L"
		If MultiKey(FB.SC_RIGHT) Then KBKey ="R"
		If MultiKey(FB.SC_UP) Then KBKey ="U"

		ReadMouse
		
		Select Case Game.Status
		'-------------------------------------------------------------------------------------------
		
		Case MenuScreen
		
			DrawMenuBackground			
			PutLogo 290, 40
			
			'Options
			MouseOver = -1
			For F = 0 To 8
				If (MouseY > 300) And (MouseY < 363) And (MouseX > 48 + F * 80) And (MouseX < 111 + F * 80) Then
					MouseOver = F
					If (MouseMoved = 1) And (OpMenu <> F) Then
						midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
						OpMenu = F
						midiOutShortMsg (hMidiOut, &H76c0)
						midiOutShortMsg (hMidiOut, &H7f4090 + (OpMenu * 256))
					End If
				End If
				If OpMenu = F Then
					Put (32 + f * 80, 284), BMP (277), (0,0)-(95,95), Alpha
					Put (48 + F * 80, 300), BMP (276), (f*64,64)-Step(63,63), Trans
				Else
					Put (48 + F * 80, 300), BMP (276), (f*64,0)-Step(63,63), Trans
				End If
			Next
			WriteCentered TXT (OpMenu + 2), 380, 1, 1
			
			If (KBKey <> "") Or (MouseMoved = 1) Then TTDemo1 = Timer

			If (MouseOver > -1) And (MouseClicked = 1) Then OpMenu = MouseOver : KBKey = "["

			If LastKBKey <> KBKey Then
				
				If KBKey = "D" Or KBKey = "R" Then
					midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
					OpMenu = (Opmenu + 1) Mod (GameExit + 1)
					midiOutShortMsg (hMidiOut, &H76c0)
					midiOutShortMsg (hMidiOut, &H7f4090 + (OpMenu * 256))
					
				ElseIf KBKey = "U" Or KBKey = "L" Then
					midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
					OpMenu = (OpMenu + GameExit) Mod (GameExit + 1)
					midiOutShortMsg (hMidiOut, &H76c0)
					midiOutShortMsg (hMidiOut, &H7f4090 + (OpMenu * 256))
					
				ElseIf KBKey = "ESC" Then
					Game.Finish = 1
					
				ElseIf KBKey = "[" Or KBKey = "]" Then	'Option selected!
					Select Case OpMenu
					Case GameStart
						Option1 = 0
						ChangeStatus Playing
						ResetGame
						ResetLife
						Mine.Kind = 0
						ReadInternalMine 1
						Started=0
						StartTime = Timer + 5
						
					Case GoToMine, Volume
						Option1 = 0
						ChangeStatus Configs
						
					Case HighScores
						ChangeStatus Top10
						PosTop10 = 0
						
					Case About
						ChangeStatus Instruc
						
					Case ChLanguage
						ChangeStatus SelectLanguage
						SearchLanguagePacks
						
					Case Custom
						Option1 = 0
						VPlayer.CurrentMine = 0
						Cls
						SwapScreens
						Cls
						ShowMSG 7, 8, TXT (92), TXT (93), " "
						SearchCustomMines
						SwapScreens
						Cls
						ChangeStatus Configs
						
					Case EditCustom
						Option1 = 0
						VPlayer.CurrentMine = 0
						Cls
						SwapScreens
						Cls
						ShowMSG 7, 8, TXT (92), TXT (93), " "
						SearchCustomMines
						SwapScreens
						Cls
						ChangeStatus Configs
						
					Case GameExit
						Game.Finish = 1
						
					End Select
				End If
			End If
			
			If Timer > TTDemo1 + 8 Then
				ChangeStatus DemoMode
				Mine.Kind = 0
				ResetGame
				ResetLife
				ReadInternalMine 0
				Started=0
				MSGDemo = 0
				MensTime = 0
				KBKey = ""
				PositDemo = 0
				DemoW1 = 0
				DemoW2 = 0
				DemoCycle = 0
			End If
		
		'-------------------------------------------------------------------------------------------
		
		Case SelectLanguage	
		
			DrawMenuBackground
			PutLogo 290, 40

			If LanguangesQtt = 0 Then
				ShowMSG 5, 8, "Só há o idioma português instalado.", "", ""
				If KBKey <> "" And LastKBKey <> KBKey Then
					ChangeStatus MenuScreen
				End If
			Else
				DrawBox 10, LanguangesQtt + 3, 0, 400, 370
				WriteCentered TXT(7), 374 - (LanguangesQtt + 3) * 16, 1, 1
				MouseOver = -1
				For f = 0 To LanguangesQtt
					If (MouseX > 252) And (MouseX < 547) And (Abs (MouseY - (444 - (LanguangesQtt + 3) * 16 + f * 32)) < 16) Then
						MouseOver = F
						If MouseMoved = 1 Then LangNumber = F
					End If
					WriteCentered Language (f), 434 - (LanguangesQtt + 3) * 16 + F * 32, 1, 0
				Next
				Line (250, 426 - (LanguangesQtt + 3) * 16 + LangNumber * 32) - Step (300, 35), RGB (0, 127, 255), b
				Line (251, 427 - (LanguangesQtt + 3) * 16 + LangNumber * 32) - Step (298, 33), RGB (0, 127, 255), b

				If MouseOver > -1 And MouseClicked = 1 Then LangNumber = MouseOver : KBKey = "["

				If LastKBKey <> KBKey Then
					If (KBKey = "U" Or KBKey ="L") And LangNumber > 0 Then LangNumber -= 1
					If (KBKey = "D" Or KBKey ="R") And LangNumber < LanguangesQtt Then LangNumber += 1
					If KBKey = "[" Or KBKey = "]" Then
						CurrentLanguage = Language (LangNumber)
						ReadLanguagePack (CurrentLanguage)
						SaveConfigs
						ChangeStatus MenuScreen
					End If
					If KBKey = "ESC" Then ChangeStatus MenuScreen
				End If
			End If			
			
		'-------------------------------------------------------------------------------------------
		
		Case Configs 'Choose mine to go, or custom mine to play or edit, or sets sound volume
			
			DrawMenuBackground
			PutLogo 290, 40
				
			Select Case OpMenu
			
			Case GoToMine 	'Choose a internal mine (shows up to 100 at a time)
			
				If VPlayer.CurrentMine < 1 Or VPlayer.CurrentMine > Game.HowManyMines Then VPlayer.CurrentMine = 1
				WriteCentered TXT(51), 140, 1, 0
				WriteCentered TXT(52), 575, 1, 0
				
				Mine1 = Int((VPlayer.CurrentMine - 1) / 100) * 100 + 1
				If Mine1 > Game.HowManyMines - 100 Then
					Mine2 = Game.HowManyMines - Mine1 + 1
				Else
					Mine2 = 100
				End If

				MouseOver = -1

				For F = 0 To Mine2 - 1			'Draw boxes with the number of the mines
					XM = (F Mod 10) * 65 + 80
					YM = Int (F / 10) * 40 + (370 - Int((Mine2 + 9)/10) * 20)
					If Mine1 + F > Game.MaxReached Then
						Put (XM, YM + 2), BMP (276), (576, 33) - (630, 65), Trans	'Locked mine  = gray box
					Else
						Put (XM, YM + 2), BMP (276), (576, 0) - (630, 32), Trans	'Unlocked one = green box
					End If
					If (MouseX > XM) And (MOuseX < XM + 54) And (MouseY > YM + 2) And (MouseY < YM + 35) Then
						MouseOver = Mine1 + F
					End If
					If Mine1 + F > Game.MaxReached Then
						Put (XM, YM + 6), BMP (276), (576, 103) - (630, 127), Trans	'Locked mine = lock
					ElseIf Mine1 + F < 10 Then
						WriteTXT Str(Mine1 + F), XM + 23, YM + 8, 1, 0 	'Center text (1 digit number)
					ElseIf Mine1 + F < 100 Then
						WriteTXT Str(Mine1 + F), XM + 17, YM + 8, 1, 0 	'Center text (2 digits number)
					Else
						WriteTXT Str(Mine1 + F), XM + 11, YM + 8, 1, 0 	'Center text (3 digits number)
					End If
				Next
				
				If (MouseMoved = 1) And (MouseOver > -1) Then VPlayer.CurrentMine = MouseOver
				If MouseOver > -1 And MouseClicked = 1 Then VPlayer.CurrentMine = MouseOver : KBKey = "["
				XM = ((VPlayer.CurrentMine - Mine1) Mod 10) * 65 + 80
				YM = Int ((VPlayer.CurrentMine - Mine1) / 10) * 40 + (370 - Int((Mine2+9)/10) * 20)
				Put (XM, YM), BMP (276), (576, 66)-(630, 102), Trans
				
				If MouseWDir = -1 Then KBKey = "#"		'Mouse wheel = Pg Up / Pg Down
				If MouseWDir = 1 Then KBKey = "@"
				
				If KBKey <>"" And KBKey <> LastKBKey Then
					Select Case KBKey
					Case "D"
						If VPlayer.CurrentMine <= Game.HowManyMines - 10 Then VPlayer.CurrentMine += 10 
					Case "L"
						If VPlayer.CurrentMine > 1 Then VPlayer.CurrentMine -= 1
					Case "U"
						If VPlayer.CurrentMine > 10 Then VPlayer.CurrentMine -= 10
					Case "R"
						If VPlayer.CurrentMine < Game.HowManyMines Then VPlayer.CurrentMine += 1
					Case "@"
						If VPlayer.CurrentMine > 100 Then VPlayer.CurrentMine -= 100 Else VPlayer.CurrentMine = 1
					Case "#"
						If VPlayer.CurrentMine < Game.HowManyMines - 100 Then VPlayer.CurrentMine += 100 Else VPlayer.CurrentMine = Game.HowManyMines
					Case "ESC"
						ChangeStatus MenuScreen
					Case "[", "]"
						If VPlayer.CurrentMine <= Game.MaxReached Then		'Mine selected
							XM = VPlayer.CurrentMine
							ResetGame
							ResetLife
							VPlayer.CurrentMine = XM
							Mine.Kind = 0
							ReadInternalMine XM
							Started = 0
							StartTime = Timer + 5
							ChangeStatus Playing
						End If
					End Select
				End If
					
					
			Case Volume 		'Stes sound volume
				
				Put (364,250), BMP (276), (256,0)-Step(63,63), Trans
				MouseOver = -1
				If (MouseY > 330) And (MouseY < 400) And (MouseX > 270) And (MouseX < 530) Then
					MouseOver = (MouseX - 275) / 2
					If MouseOver <0 Then MouseOver = 0
					If MouseOver > 127 Then MouseOver = 127
				End If
				
				If MouseClicked = 1 Then
					If MouseOver > -1 Then
						Game.Volume = MouseOver
					Else
						KBKey = "["
					EndIf
				EndIf
				
				'Barras
				If MouseOver = - 1 Then
					ColorRGB = &H60ff00
					ColorRGB2 = &H205000
				Else
					ColorRGB = &H60ff90
					ColorRGB2 = &H205030
					Line (270, 405) - (530, 325), &H909090, b
					Line (269, 406) - (531, 324), &H909090, b
				End If
				For F = 0 To 15
					If Game.Volume >= F * 8 Then
						Line (275 + f * 16, 400) - Step(10, -10 - f * 4), ColorRGB, BF
					Else
						Line (275 + f * 16, 400) - Step(10, -10 - f * 4), ColorRGB2, BF
					End If
				Next
				If Game.Volume = 0  Then Line (275,400) - Step(10, -10 ), RGBA(180,0,0,0), BF
				If Game.Volume = 127  Then Line (515,400) - Step(10, -70 ), RGBA(200,200,0,0), BF
				WriteCentered TXT(53), 440, 1, 0
				WriteCentered TXT(54), 500, 1, 0
				
				If KBKey = "D" Or KBKey = "L" Then
					If Game.Volume > 0 Then Game.Volume -= 1
				ElseIf KBKey = "U" Or KBKey = "R" Then
					If Game.Volume < 127 Then Game.Volume += 1
				ElseIf (KBKey = "[" Or KBKey = "]" Or KBKey = "ESC") And LastKBKey <> KBKey Then
					SaveConfigs
					ChangeStatus MenuScreen
				ElseIf MouseWDir = -1 Then
					If Game.Volume > 8 Then
						Game.Volume -= 8
					Else
						Game.Volume = 0
					End If
				ElseIf MouseWDir = 1 Then
					Game.Volume += 8
					If Game.Volume > 127 Then Game.Volume = 127
				End If
				midiOutSetVolume(0, (Game.Volume Shl 9) Or (Game.Volume Shl 1))
				
			
			Case Custom, EditCustom		'Select custom mine to play or edit
			
				MouseOver = -1
				If (CustomMineQt = 0) Then			'If no mine file was found
					If OpMenu = EditCustom Then
						ClearMine
						ClearMineEditor
						ChangeStatus Editor
						Game.EdStatus = Editing
					Else
						ShowMSG 7, 8, TXT(55), TXT(56), ""
						If (KBKey <> "" And KBKey <> LastKBKey) Or (MouseClicked = 1) Then
							ChangeStatus MenuScreen
						End If
					End If
				Else
					If VPlayer.CurrentMine < 0 Or VPlayer.CurrentMine > CustomMineQt - 1 Then VPlayer.CurrentMine = 0
					WriteCentered TXT (51), 140, 1, 0
					If OpMenu = EditCustom Then 
						WriteCentered TXT(97), 575, 1, 0
					Else
						WriteCentered TXT(52), 575, 1, 0
					End If
					
					Mine1 = Int((VPlayer.CurrentMine) / 100) * 100
					If Mine1 > CustomMineQt - 100 Then
						Mine2 = CustomMineQt - Mine1
					Else
						Mine2 = 100
					End If
				
					For F = 0 To Mine2 - 1
						XM = (F Mod 10) * 65 + 80
						YM = Int (F / 10) * 40 + (370 - Int((Mine2 + 9)/10) * 20)
						Put (XM, YM+2), BMP (276), (576, 0)-(630, 32), Trans
						If (MouseX > XM) And (MOuseX < XM + 54) And (MouseY > YM + 2) And (MouseY < YM + 35) Then
							MouseOver = Mine1 + F
						End If

						CustomTemp = CustomMine (Mine1 + F)
						If CustomTemp < 10 Then
							WriteTXT Str(CustomTemp), XM + 23, YM + 8, 1, 0
						ElseIf CustomTemp < 100 Then
							WriteTXT Str(CustomTemp), XM + 17, YM + 8, 1, 0
						Else
							WriteTXT Str(CustomTemp), XM + 11, YM + 8, 1, 0
						End If
					Next
					If (MouseMoved = 1) And (MouseOver > -1) Then VPlayer.CurrentMine = MouseOver
					If MouseOver > -1 And MouseClicked = 1 Then VPlayer.CurrentMine = MouseOver : KBKey = "["

					XM = ((VPlayer.CurrentMine - Mine1) Mod 10) * 65 + 80
					YM = Int ((VPlayer.CurrentMine - Mine1) / 10) * 40 + (370 - Int((Mine2 + 9)/10) * 20)
					Put (XM, YM), BMP (276), (576,66)-(630, 102), Trans
					If MouseWDir = -1 Then KBKey = "#"
					If MouseWDir = 1 Then KBKey = "@"
					
					If KBKey <>"" And KBKey <> LastKBKey Then
						Select Case KBKey
						Case "D"
							VPlayer.CurrentMine += 10 
							If VPlayer.CurrentMine >= CustomMineQt Then VPlayer.CurrentMine -= 10
						Case "L"
							VPlayer.CurrentMine -= 1
							If VPlayer.CurrentMine < 0 Then VPlayer.CurrentMine = 0
						Case "U"
							VPlayer.CurrentMine -= 10
							If VPlayer.CurrentMine < 0 Then VPlayer.CurrentMine += 10
						Case "R"
							VPlayer.CurrentMine += 1
							If VPlayer.CurrentMine >= CustomMineQt Then VPlayer.CurrentMine = CustomMineQt - 1
						Case "@"
							VPlayer.CurrentMine -= 100
							If VPlayer.CurrentMine < 0 Then VPlayer.CurrentMine = 0
						Case "#"
							VPlayer.CurrentMine += 100
							If VPlayer.CurrentMine >= CustomMineQt Then VPlayer.CurrentMine = CustomMineQt - 1
						Case "TAB"
							If OpMenu = EditCustom Then
								ClearMine
								ClearMineEditor
								ChangeStatus Editor
							End If
						Case "ESC"
							VPlayer.CurrentMine = 1
							ChangeStatus MenuScreen
						Case "[", "]"
							XM = CustomMine(VPlayer.CurrentMine)
							ResetGame
							ResetLife
							VPlayer.CurrentMine = XM
							Mine.Kind = 1
							Started = 0
							StartTime = Timer + 5
							If OpMenu = EditCustom Then
								ReadCustomMine XM, 1
								ChangeStatus Editor
								While MouseB = 1 And MouseX <> -1
									Sleep 1, 1
									ReadMouse
								Wend
							Else
								ReadCustomMine XM, 0
								ChangeStatus Playing
							End If
						End Select
					End If
				End If
			End Select
		'-------------------------------------------------------------------------------------------
			
			
		Case Playing, DemoMode, Testing 		'Game is being played, tested or is in demo mode
			
			If Game.Status = DemoMode Then
				'In demo mode, pressing any key causes to go back to menu
				For F= 1 To 127
					If (MultiKey(f)) Then ChangeStatus MenuScreen
				Next
				
				'Next command for demo
				If VPlayer.UsingDrill = 0 And VPlayer.UsingPickaxe = 0 Then
					KBKey = NextKeyForDemo ()
					If KBKey = "ESC" Then
						ChangeStatus MenuScreen
					End If
				End If
			End If
			
			'Is time over?
			If (Game.SeqCycle Mod 8 = 0) And (Game.Cycle = 0) And (Started > 0) And (VPlayer.Died = 0) Then
				VPlayer.Time += 1
				If (VPlayer.Time >= Mine.Time) And (Mine.Time > 0) And (Game.Status = Playing) Then
					VPlayer.Died = 1
				End If
			End If
			
			'Check commands: Pause, Map, Quit, Esc (to die)
			If VPlayer.Died = 0 And Started = 1 And (Game.Status = Playing Or Game.Status = Testing) And LastKBKey <> KBKey Then
				Select Case KBKey
				Case "M"	'Map
					With VPlayer
						If (Mine.Width > 24 Or Mine.Height > 16) Then	'Only for mines larger than screen
							'Calculates X for map
							If Mine.Width < 25 Or .X <= 12 Then
								MapX = 0
							ElseIf .X >= Mine.Width - 12 Then
								MapX = Mine.Width - 24
							Else
								MapX = .X - 12
							End If
							
							'Calculates Y for map
							If Mine.Height < 17 Or .Y <= 8 Then
								MapY = 0
							ElseIf .Y > Mine.Height - 8 Then
								MapY = Mine.Height - 16
							Else	
								MapY = .Y - 8
							End If
							ChangeStatus MapMode
						Else
							'Warning sound - mine is smaller than the screen
							midiOutShortMsg (hMidiOut, VSoundEx (6).COn1)
							midiOutShortMsg (hMidiOut, VSoundEx (6).COn2)
							VSoundEx(6).Time = 4
						End If
					End With
					
				Case "P"	'Pause
					ChangeStatus Paused
					
				Case "ESC" 	'Dies or finishes test
					If Game.Status = Testing Then		'If testing the mine being edited...
						LMTEC = ""
						EmptyKeyboard
						Option1 = 0
						AllSoundOff
						While lmtec <> " " And LMTec <> Chr(13) And lmtec <> Chr(27)
							Cls
							ShowMSG 4, 5, TXT (95), "", "", 400, 300, Option1
							LMTec=Inkey
							ReadMouse
							If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
							If (MouseClicked = 1) And (MouseYesNo > 0) Then LMTec = " "
							If (LmTec = c255 + "H") Or (LmTec = c255+ "K") Or (LmTec = c255+ "M") Or (LmTec = c255+ "P") Then Option1 = 1 - Option1
							SwapScreens
						Wend
						Cls
						If (LmTec <> Chr(27)) And (Option1 = 0) Then FinishTest
						EmptyKeyboard 1
						
					Else								'Dies
						VPlayer.Died = 1
					End If
					
				Case "Q"	'Quits (confirm before)
					
					LMTEC = ""
					EmptyKeyboard
					Option1 = 0
					While lmtec <> " " And LMTec <> Chr(13) And lmtec <> Chr(27)
						Cls
						ShowMSG 4, 5, TXT(57), "", "", 400, 300, Option1
						LMTec = Inkey
						ReadMouse
						If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
						If (MouseClicked = 1) And (MouseYesNo > 0) Then LMTec = " "
						If (LmTec = c255+ "H") Or (LmTec = c255+ "K") Or (LmTec = c255+ "M") Or (LmTec = c255+ "P") Then Option1 = 1 - Option1
						SwapScreens
						Game.seqCycle=(Game.seqCycle+1) Mod 360
					Wend
					Cls
					If LMTec <> Chr(27) And Option1 = 0 Then
						Game.Finish = 1
					End If
					
					EmptyKeyboard 1
						
				End Select
			End If
			
			
			'Verify player movements and objects involved
			
			If (Game.Status0 = Game.Status) And (Game.Finish <> 1) Then
			
				If VPlayer.Pushing = 1 Then		'player is begining to push objects
					If VPlayer.CurrDirection = 1 Then	'to rigth
						Push1 = Mine.Width
						Push2 = 0
						Push3 = -1
					Else								'to left
						Push1 = 0
						Push2 = Mine.Width
						Push3 = 1
					End If
					
					For F = Push1 To Push2 Step Push3	'Aligned objects are pushed together
						With Object (F, VPlayer.Y)
							If .BeingPushed > 0 And .StepNumber >= Game.Steps -1 Then
								Object (F + 3 - .BeingPushed * 2, VPlayer.y).Tp = .Tp
								Object (F + 3 - .BeingPushed * 2, VPlayer.y).StepNumber = 0
								Object (F + 3 - .BeingPushed * 2, VPlayer.y).BeingPushed = 0
								Object (F + 3 - .BeingPushed * 2, VPlayer.y).IsFalling = 0
								Object (F + 3 - .BeingPushed * 2, VPlayer.y).WasFalling = 0
								.StepNumber = 0
								.BeingPushed = 0
								.IsFalling = 0
								.WasFalling=0
								.Tp = 0
							End If
						End With
					Next
				Else
					midiOutShortMsg (hMidiOut, VSoundEx(7).COff)
				End If
				
				'Player movements and actions
				
				With VPlayer
					'Movement is finishing now
					If .CurrDirection > 0 And .StepNumber = Game.Steps Then
						
						.LastDirection= .CurrDirection
						'Changes player position
						Select Case .CurrDirection
						'Right
						Case 1
							.x += 1
						'Left
						Case 2
							.x -= 1
						'Up
						Case 3
							.y -= 1
						'Down / Fall
						Case 4, 5
							.y += 1
						End Select
						
						'Movements was completed
						.CurrDirection = 0
						.Pushing = 0
						.StepNumber = 0
					End If
					
					'Starting a mine now? Waits for a key or some seconds to begin.
					If Started = 0 Then
						If ((KBKey <> "") And (KBKey <> LastKBKey)) Or ((Timer >= StartTime) And (Game.Status <> Testing)) Then
							Started = 1
						End If
											
					'Has just died? Then explode!
					ElseIf .Died = 1 Then
						Explode (.x, .y, 2)
						.Died = 2
						If Game.Status = DemoMode Then	'If in demo mode, goes back to menu (it should never happen...)
							.Died = 0
							ChangeStatus MenuScreen
						End If
						
					'Died in a previous cyvle?					
					ElseIf .Died > 1 Then
						.Died = (.Died + 1) Mod 100		'Increase counter
						If .Died < 2 Then .Died = 2
						
						'Key pressed
						If KBKey <> "" And KBKey <> LastKBKey Then
							'Reset cycle counters
							Game.Cycle = 0
							Game.SeqCycle = 0
							
							'If testing, just restart
							If Game.Status = Testing Then
								ReadCustomMine -1, 0
								Started = 0
								ResetLife
								
							'Is Game Over?
							ElseIf VPlayer.Lives < 1 Then
								ChangeStatus GameOver
								
							'Decreases lives, resets the mine and the player
							Else
								VPlayer.Lives -= 1
								If Mine.Kind = 0 Then	'Reads the mine again
									ReadInternalMine VPlayer.CurrentMine
								Else
									ReadCustomMine VPlayer.CurrentMine, 0
								End If
								
								Started = 0
								ResetLife
							End If
						End If
						
						
						
						'ESC was not pressed. Was not dead. Will then fall?
						'Check: Is stopped? Is not at a stair? Is not an object? Is the object under player falling? Or does it kill player?
							
					ElseIf Started = 1 And .CurrDirection = 0 And .y < Mine.Height And Behavior (TpObject(Object (.x, .y).tp).Kind).Scalable = 0 And _
								(Behavior (TpObject (Object (.x, .y + 1).tp).Kind).Support = 0 Or Object (.x, .y + 1).IsFalling = 1 Or Behavior (TpObject(Object (.x, .y + 1).tp).Kind).Kill = 1) Then
						
						.CurrDirection = 5	'Falling
						.LastDirection = 5
						.UsingDrill	= 0
						.UsingPickaxe = 0
						.StepNumber = 1		'Just started
						If Behavior (TpObject(Object (.x, .y + 1).tp).Kind).Kill = 1 Then .Died = 1	'Falling over an object that kills
						
					'Is not dead. No ESC pressed. Not falling. Is using pickaxe?
					
					ElseIf .UsingPickaxe > 0 Then
						If .UsingPickaxe Mod 3 =1 Then
							midiOutShortMsg (hMidiOut, VSound(6, 1).COn1)
							midiOutShortMsg (hMidiOut, VSound(6, 1).COn2)
							VSound (6,1).Time = 1
						End If
	
						.UsingPickaxe += 1
						If .UsingPickaxe >= Game.Steps * 2 Then
							.UsingPickaxe = 0
							Object (.x, .y + 1).tp = 0
						End If
						
					'Is not dead. No ESC pressed. Not falling. Not using pickaxe. Is using drill?
					ElseIf .UsingDrill > 0 Then
						.UsingDrill += 1	
						'The object is falling? Can't use drill on it!
						If (.DrillDirection = 1 And Object (.x + 1, .y).IsFalling = 1)  Or (.DrillDirection = 2 And Object (.x - 1, .y).IsFalling = 1) Then
							.UsingDrill = 0
						End If
						If .UsingDrill >= Game.Steps * 2 Then
							If .DrillDirection=1 Then
								Object (.x + 1, .y).tp = 0
							Else
								Object (.x - 1, .y).tp = 0
							End If
							.UsingDrill = 0
							.DrillDirChanged = 0
						ElseIf .DrillDirChanged = 0 And .UsingDrill <= Game.Steps Then
							'Perform direction change while using drill
							If .DrillDirection = 1 And KBKey = "L" And Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Destroyable = 2 And Object (.x - 1, .y).IsFalling = 0 Then
								.DrillDirChanged = 1
								.DrillDirection = 2
							ElseIf .DrillDirection = 2 And KBKey = "R" And Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Destroyable = 2 And Object (.x + 1, .y).IsFalling = 0 Then
								.DrillDirChanged = 1
								.DrillDirection = 1
							End If
						End If
					'Not dead. No Esc pressed. Not falling. Not using pickaxe or drill. Then, if is moving, go ahead.
					ElseIf Started = 1 And .CurrDirection > 0 Then
						.StepNumber += 1
						
					ElseIf Started = 1 Then
					
						'Not dead. No Esc pressed. Not falling. Not using pickaxe or drill. Not moving.
						'begin a new movement now?
						
						Select Case KBKey
						
						'==========================
						'UP
						Case "U"
							'Can go up? Not at mine top, and on stairs?
							.LastDirection = 3
							If .y > 0 And Behavior (TpObject(Object (.x, .y).tp).Kind).Scalable = 1 Then
								If Behavior (TpObject(Object (.x, .y - 1).tp).Kind).Kill = 1 Then	'Objetc above kills?
									.Died = 1
								Else
									'Object above allows movement?
									If Behavior (TpObject(Object (.x, .y - 1).tp).Kind).Walk > 0 Then
										'begin going up
										.CurrDirection = 3
										.StepNumber = 1
										
										'Take object above, if there is someone
										PickUpObj .x, .y - 1
									End If
								End If
							End If
							
						'==========================
						'DOWN
						Case "D"
							'Can go down? Not at mine bottom?
							.LastDirection = 5
							If .y < Mine.Height Then
							    If Behavior (TpObject(Object (.x, .y + 1).tp).Kind).Kill = 1 Then	'Object under kills?
									.Died = 1
								Else
									
									'If there's stair under, goes down
									If Behavior (TpObject(Object (.x,.y + 1).tp).Kind).Scalable = 1 Then
										'begin going down
										.CurrDirection = 4
										.LastDirection = 4
										.StepNumber = 1
										
									'no stairs under. Object allows movement? Then falls
									ElseIf Behavior (TpObject(Object (.x, .y + 1).tp).Kind).Walk > 0 Then
										'begin falling
										.CurrDirection = 5
										.LastDirection = 5
										.StepNumber = 1
										'Take object under, if there's someone
										PickUpObj .x, .y + 1
									End If
								End If
							End If
							
						'==========================
						'LEFT
						Case "L" 
							.LastDirection = 2
							.DrillDirection = 2
							'Mine left corner?
							If .X > 0 Then
								If Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Kill = 1 Then	'Object at left kill?
									.Died = 1
								Else
									'Object at left allows movement, and the one over it is not falling
									If Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Walk > 0 And Object (.x - 1, .y - 1).IsFalling = 0 Then
										'begin movement to left
										.CurrDirection = 2
										.StepNumber = 1
										'Take object (if present)
										PickUpObj .x - 1, .y
										
									'If object doesn't allow movement, check if it can be pushed
									ElseIf PushObj (.x - 1, .y, 2, 0, 1) < 3 Then
										.Pushing = 1
										.CurrDirection = 2
										.StepNumber = 1
										midiOutShortMsg (hMidiOut, VSoundEx(7).COn1)	'Sound for object pushing
										midiOutShortMsg (hMidiOut, VSoundEx(7).COn2)
									End If
								End If
							End If
						
						'==========================
						'RIGHT
						Case "R"
							.LastDirection = 1
							.DrillDirection = 1
							'Mine right corner?
							If .x < Mine.Width Then
								If Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Kill = 1 Then	'Object at right kills?
									.Died = 1
								Else
									'Object at right allows movement, and the one over it is not falling
									If Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Walk > 0 And Object (.x + 1, .y - 1).IsFalling = 0 Then
										'begin movement to right
										.CurrDirection = 1
										.StepNumber = 1
										'Take object (if present)
										PickUpObj .x + 1, .y
										
									'If object doesn't allow movement, check if it can be pushed
									ElseIf PushObj (.x + 1, .y, 1, 0, 1) < 3 Then
										.Pushing = 1
										.CurrDirection = 1
										.LastDirection = 1
										.StepNumber = 1
										midiOutShortMsg (hMidiOut, VSoundEx(7).COn1)	'Sound for object pushing
										midiOutShortMsg (hMidiOut, VSoundEx(7).COn2)
									End If
								End If
							End If
							
						'==========================
						'Use scaffold
						Case "Z"
						If LastKBKey <> "Z" Then
							'Can be used? Have scaffolds to use?
							If Behavior (TpObject(Object (.x, .y).tp).Kind).Support = 0 And .ItScaffold > 0 Then
								Object (.x, .y).tp = 81
								.ItScaffold -= 1
							Else
								'Warning sound
								midiOutShortMsg (hMidiOut, VSoundEx(6).COn1)
								midiOutShortMsg (hMidiOut, VSoundEx(6).COn2)
								VSoundEx (6).Time = 10
							End If
						End If
						
						'==========================
						'Use pickaxe
						Case "X"
							If LastKBKey <> "X" Then
								'Object destroyable? Have pickaxes to use?
								If Behavior (TpObject(Object (.x, .y + 1).tp).Kind).Destroyable = 2 And .ItPickaxe > 0 Then
									.ItPickaxe -= 1
									.UsingPickaxe  = 1
								Else
									'Warning sound
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn1)
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn2)
									VSoundEx (6).Time = 10
								End If
							End If
							
						'==========================
						'Use drill
						Case "C" 
							If LastKBKey <> "C" Then
								'Object destroyable? Have drills to use?
								If .ItDrill > 0 And ((Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Destroyable = 2 And Object (.x - 1, .y).IsFalling=0) Or (Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Destroyable = 2) And Object (.x + 1, .y).IsFalling = 0) Then
								'Right
									If .DrillDirection = 1 And Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Destroyable = 2 And Object (.x + 1, .y).IsFalling = 0 Then
										.DrillDirection	 = 1
										.ItDrill -= 1
										.UsingDrill = 1
										.DrillDirChanged = 0
										midiOutShortMsg (hMidiOut, VSound(5, Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Sound).COn1)	'Drill sound
										midiOutShortMsg (hMidiOut, VSound(5, Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Sound).COn2)
										VSound(5, Behavior (TpObject(Object (.x + 1, .y).tp).Kind).Sound).Time = 16
								'Left
									ElseIf Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Destroyable = 2 And Object (.x - 1,.y).IsFalling = 0 Then
										.DrillDirection	 = 2
										.ItDrill -= 1
										.UsingDrill = 1
										.DrillDirChanged = 0
										midiOutShortMsg (hMidiOut, VSound(5, Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Sound).COn1)	'Drill sound
										midiOutShortMsg (hMidiOut, VSound(5, Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Sound).COn2)
										VSound(5, Behavior (TpObject(Object (.x - 1, .y).tp).Kind).Sound).Time = 16
									End If
								Else
									'Warning sound
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn1)
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn2)
									VSoundEx (6).Time = 10
								End If
							End If
							
						'==========================
						'Activate small bomb
						Case "V"
							If LastKBKey <> "V" Then
								'Cell is empty? Have small bombs to use?
								If .ItBombS > 0 And Behavior (TpObject(Object (.x, .y).tp).Kind).Empty = 1 Then
									.ItBombS -= 1
									Object (.x, .y).Tp = 77
									Object (.x, .y).StepNumber = 1
								Else
									'Warning sound
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn1)
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn2)
									VSoundEx (6).Time = 10
								End If
							End If
							
						'==========================
						'Activate big bomb
						Case "B"
							If LastKBKey <> "B" Then
								'Cell is empty? Have big bombs to use?
								If .ItBombB > 0 And Behavior (TpObject(Object (.x, .y).tp).Kind).Empty = 1 Then
									.ItBombB -= 1
									Object (.x, .y).Tp = 79
									Object (.x, .y).StepNumber = 1
								Else
									'Warning sound
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn1)
									midiOutShortMsg (hMidiOut, VSoundEx(6).COn2)
									VSoundEx (6).Time = 10
								End If
							End If
							
						'==========================	
						'****DISABLE THIS option
						'
						'Case "TAB"
						'	If LastKBKey <> "TAB" And Game.Status = Playing Then 
						'		Game.SeqCycle = 0
						'		ChangeStatus WonMine
						'		CalcTimeBonus
						'	End If
							
						End Select
					End If
					
					'Updates Oxygen
					If Started = 1 And Game.Cycle = 0 And .Died = 0 Then
						If (BkGround(.X, .Y) = 0 And (.CurrDirection <> 3 Or BkGround(.X, .Y - 1) = 0 Or .StepNumber < Game.Steps / 2)) Or (BkGround(.x, .y + 1)=0 And .CurrDirection > 3 And .StepNumber >= Game.Steps / 2) Then
							If .Oxygen > 10 Then .UsingOxygen = 1
							.Oxygen -= 1
							If .Oxygen < 0 Then		'Activates oxygen bootle if needed and available
								If .ItOxygen > 0 Then
									.ItOxygen -= 1
									.Oxygen = 99
									.UsingOxygen = 1
								Else				'Oxygen is spent... you die
									.Oxygen	= 0
									.Died = 1
								End If
							End If
						Else
							.UsingOxygen = 0						'Out of water
							If .Oxygen < 10 Then .Oxygen += 1		'Increases oxygen if less than 10 (out of water)
						End If
					End If
				End With 'VPlayer
				
				'Check moving objects
				'---------------------------------
				If Started = 1 Then
					With VPlayer
						'Checks in the opposite direction of the player's movement
						If .CurrDirection = 1 Or (.CurrDirection = 0 And .LastDirection = 1) Then
							Push1 = Mine.Width
							Push2 = 0
							Push3 = -1
						Else
							Push1 = 0
							Push2 = Mine.Width
							Push3 = 1
						End If
					End With
					
					'checks the whole mine - object by object
					For F = Push1 To Push2 Step Push3
						For G = Mine.Height To 0 Step -1	'From down to up
						 	With Object (F, G)
								'Moving or being pushed?
								If .StepNumber > 0 Or .BeingPushed > 0 Then
									'Gives sequence
									.StepNumber += 1
									If .tp >= 77 And .Tp <= 80 Then			'Activated bomb
										.Tp = 77 + 2 * Int((.tp - 77) / 2) + (.StepNumber Mod 2)
										If .StepNumber >= Game.Steps * 6 Then
											Explode (f, g, Int((.tp - 77) / 2) )
										End If
									End If
									
									'Object falls over player while climbing
									If .IsFalling = 1 And VPlayer.X = F And VPlayer.Y = G + 2 And VPlayer.CurrDirection = 3 And (VPlayer.StepNumber + .StepNumber >= Game.Steps) Then
										If VPlayer.Died = 0 Then
											VPlayer.Died = 1
											.StepNumber -= 1
										End If
									End If
									
									'Movement is completed?
									If .StepNumber = Game.Steps And (.tp < 77 Or .tp > 80)Then
										'Fall completed - change object position
										If .IsFalling = 1 Then
											Object (F, G + 1).WasFalling = 1
											Object (F, G + 1).Tp = .Tp
											Object (F, G + 1).StepNumber = 0
											Object (F, G + 1).BeingPushed = 0
											Object (F, G + 1).IsFalling = 0
											.WasFalling = 0
											.StepNumber = 0
											.BeingPushed = 0
											.IsFalling = 0
											.Tp = 0
											
											'Sound: Object falls over another
											If Object (f, g + 2).IsFalling = 0 And Behavior (TpObject(Object (f, g + 2).tp).Kind).Empty = 0 Then
												SoundPlay (Behavior (TpObject(Object (f, g + 1).tp).Kind).Sound, Behavior (TpObject(Object (f, g + 2).tp).Kind).Sound) = 1
											End If
										End If
									End If
									
									
								'Object seems to be not falling, but is falling since previous cycle
								ElseIf .WasFalling = 1 Then
									
									'check if is falling no more
									If Behavior (TpObject(Object (f, g + 1).Tp).Kind).Support = 1 Then
										.WasFalling = 0
										
									'check if falls over player
									ElseIf VPlayer.Died = 0 And (VPlayer.Y = G + 1 And ((VPlayer.X = F And VPlayer.CurrDirection < 4 And (VPlayer.CurrDirection = 0 Or VPlayer.StepNumber < Int((Game.Steps - 1) * .8))) Or _
									(VPlayer.X = F - 1 And VPlayer.CurrDirection = 1) Or (VPlayer.X = F + 1 And VPlayer.CurrDirection = 2))) Then
										VPlayer.Died = 1
										
									Else	'If not, keeps falling
										.IsFalling	= 1
										.StepNumber	= 1
									End If
									
									
								'Check if object begins to fall
								ElseIf Behavior (TpObject(.tp).Kind).Fall = 1 And G < Mine.Height And Behavior (TpObject(Object (F, G + 1).tp).Kind).Support = 0 And _
								Object (F - 1,G + 1).BeingPushed <> 1 And Object (F + 1, G + 1).BeingPushed <> 2 Then
									If VPlayer.Died = 0 And (VPlayer.Y = g + 1 And (VPlayer.X = F Or (VPlayer.X = F - 1 And VPlayer.CurrDirection = 1) Or _
									(VPlayer.X = F + 1 And VPlayer.CurrDirection = 2))) Then
										
										.WasFalling = 0		'Was not falling before!!!
										
									Else	'Doesn't fall
										.IsFalling	= 1
										.StepNumber	= 1
									End If
								End If
							End With
						Next
					Next
				End If 
				
				If Started = 0 And Mine.Gems > 0 Then	'Waiting to start
					DrawScene
					If Game.Status = Testing Then
						ShowMSG 1, 2, TXT(60), TXT(96), ""
					Else
						ShowMSG 1, 2, TXT(60), TXT (61) & " . . . " & Str(Int (StartTime - Timer + 1)), ""
					End If
					For F = 0 To 9
						Msg(f).Cycle = 0
					Next
				Else
					For f = 1 To 6 		'Sounds
						For g = 1 To 4
							If SoundPlay(f, g) = 1 Then
								midiOutShortMsg(hMidiOut, VSound (f, g).COn1)
								midiOutShortMsg(hMidiOut, VSound (f, g).COn2)
								VSound (f, g).Time = 8
							End If
						Next
					Next
					
					DrawScene
				End If
			Else
				AllSoundOff
			End If
		'-------------------------------------------------------------------------------------------
		
		
		Case Paused
			
			DrawMenuBackground
			ShowMSG 7, 2, TXT(62), TXT(63), ""
			If KBKey <> "" And KBKey <> LastKBKey Then
				Game.Status = Game.OldStatus
			End If
			
		'-------------------------------------------------------------------------------------------
		
		
		Case GameOver
		
			DrawScene
			GameOverRandomSound
			
			'"GAME OVER" in movement
			If XM < 30 Then
				Put ( 240 + XM * 3, XM * 8.5), BMP (212), (0, 0) - (112, 28), Trans
				Put ( 452 - xm * 3, 580- xm * 8.5), BMP (212), (18, 33) - (127, 63), Trans
				XM += 1
			ElseIf XM < 60 Then
				Put (334 + Rnd * (60 - XM), 268+Rnd * (60 - XM)), BMP (212), Trans
				XM += 1
			ElseIf XM < 2000 Then
				Put (334 + Rnd * (260-XM)/75, 268 + Rnd * (260-XM)/75), BMP (212), Trans
				XM += 1
			Else
				midiOutShortMsg (hMidiOut, &H6f0087 Or LastNoteGameOver)
				KBKey = "A"
			End If
			
			'Go back to menu
			If KBKey <> "" And KBKey <> LastKBKey Then
				midiOutShortMsg (hMidiOut, &H6f0087 Or LastNoteGameOver)
				PosTop10 = VerifyRecord ()
				If PosTop10 > 0 Then
					ChangeStatus Top10
				Else
					ChangeStatus MenuScreen
				End If
				ResetGame
				ResetLife
				TTDemo1 = Timer
				
				'Changes screen colors
				VRed = Int (Rnd * 2)
				VGreen = Int (Rnd * 2)
				VBlue = Int (Rnd * 2)
				If VRed + VGreen + VBlue = 0 Then VBlue = 1		'Black not allowed
			End If
			
		'-------------------------------------------------------------------------------------------
		
		Case MapMode
		
			Select Case KBKey	'Move
			Case "U"
				MapY -= 1
				If MapY < 0 Then MapY = 0
			Case "D"
				MapY += 1
				If MapY > Mine.Height - 16 Then MapY -= 1
			Case "R"
				Mapx += 1
				If MapX > Mine.Width - 24 Then MapX -= 1
			Case "L"
				MapX -= 1
				If MapX < 0 Then MapX = 0
			Case "" 	'no key
				'Nothing to do
			Case Else	' Another key (not empty)
				If LastKBKey <> KBKey Then Game.Status = Game.OldStatus
			End Select
			
			'Time doesn't stop in map mode... Is time over? Then you die...
			If (Game.SeqCycle Mod 5=0) And (Game.Cycle=0) And (Started > 0) And (VPlayer.Died = 0) Then
				VPlayer.Time += 1
				If (VPlayer.Time>=Mine.Time) And (Mine.Time>0) Then
					VPlayer.Died = 1
					Game.Status = Game.OldStatus
				End If
			End If
			
			DrawScene
			'overrides info bar	(thi could be improved - moved into sub drawscene)
			Line(2,551)-(545,596),Point(2,551),b
			Line(3,552)-(544,595), Point(3,552),b
			Line(4,553)-(543,594), Point(4,553),b
			Line (5,554)-(542,593),Point(5,554),bf
			Line(2,597)-(545,597),Point(2,597)
			Line(110,554)-(110,593),Point(2,551)
			WriteTXT TXT(64), 10, 560, 0, 0
			WriteTXT TXT(65), 127, 552, 0, 0
			WriteTXT TXT(66), 115, 572, 0, 0
			If Int (Timer * 10) Mod 5 <=2 Then
				ShowMSG 2, 0, TXT(64), "", "", 750 - TextWidth (txt(64), 1)/2, 500
			End If
			
		'-------------------------------------------------------------------------------------------
		
		Case Instruc 'FreeBasic Miner?
		
			DrawMenuBackground
			Line (0, 565) - (799, 599), RGB(48 * VRed, 48 * VGreen, 48 * VBlue), BF
			
			If (LastKBKey <> KBKey And KBKey <>"") Or (MouseClicked = 1) Then	'Waits for mouse or key pressed
				ChangeStatus MenuScreen
				Game.Cycle=0
				Game.SeqCycle=0
			End If
			
			PutLogo 290, 40
			WriteCentered TXT(67), 570, 1, 1
			WriteCentered TXT(68), 150
			WriteCentered TXT(69), 180
			WriteCentered TXT(70), 210
			WriteCentered TXT(71), 240
			WriteCentered TXT(72), 270
			WriteCentered TXT(73), 305
			WriteCentered TXT(74), 340,1
			Put (370,430), BMP(252), Trans
			WriteCentered TXT(75), 480, 1, 1
			
		'-------------------------------------------------------------------------------------------
		
		Case WonMine
		
			DrawScene
			If Game.OldStatus = Testing Then
				F = AskToFinishTest
			Else
				If Mine.Kind = 0 Then		'Internal mines
					If VPlayer.CurrentMine < Game.HowManyMines Then
						ShowMSG 2, 6, TXT(76), TXT(77) & ": " & Str(PtBonus), ""
					Else
						'Last mine!
						ShowMSG 2, 6, TXT(76), TXT(77) & ": " & Str(PtBonus), TXT(94) & ": " & Str(VPlayer.Lives) & " x 1000 = " & Str(VPlayer.Lives * 1000)
					End If
				Else
					'Custom mine
					ShowMSG 2, 6, TXT(78), TXT(77) & ": " & Str(PtBonus), TXT(79) & Str(VPlayer.Score + PtBonus)
				End If
				
				If KBKey <> "" And KBKey <> LastKBKey Then
					If Mine.Kind = 0 Then
						If VPlayer.CurrentMine = Game.HowManyMines Then		'Won game
							ChangeStatus WonGame
							NotesGameWon = 0
							LastNoteGameOver = 0
							Game.SeqCycle =- 1
						Else
							VPlayer.CurrentMine +=1							'Go to next mine
							If VPlayer.CurrentMine > Game.MaxReached Then	'Save highest reached mine, if this is
								Game.MaxReached  = VPlayer.CurrentMine
								SaveConfigs
							End If
							ResetLife
							ChangeStatus Playing
							ReadInternalMine VPlayer.CurrentMine			'Reads next mine
							Started = 0	
							StartTime = Timer + 5
						End If
						VPlayer.Score += PtBonus		'Add time bonus to score
						If VPlayer.CurrentMine = Game.HowManyMines Then VPlayer.Score += VPlayer.Lives * 1000	'Add extra life bonus to score (if won game)
					Else
						ChangeStatus MenuScreen		'If custom mine, goes back to menu
					End If				
				End If
			End If
		'-------------------------------------------------------------------------------------------
		
		Case WonGame
		
			For f=0 To 19
				g=Int(Rnd*100)
				h=Int(Rnd*60)
				FrGround (g,h)=0
				BkGround (g,h)=1
				Object (g,h).tp = 40 + Int(Rnd*16)
			Next
			
			GameWonRandomSound			'Generate random sounds ARRRG!!!
			
			DrawScene
			Game.Cycle = Game.Steps - 1
			ShowMSG 0, 12, TXT(80), TXT(81), ""
			If KBKey <> "" And KBKey <> LastKBKey Then			'Key pressed...
				midiOutShortMsg (hMidiOut, &H6f0080 Or LastNoteGameOver)
				midiOutShortMsg (hMidiOut, &H5f0080 Or (LastNoteGameOver + 513))
				PosTop10 = VerifyRecord()
				If PosTop10 > 0 Then			'Check if in top 10 high scores
					ChangeStatus Top10
				Else
					ChangeStatus MenuScreen
				End If
				ResetGame
				ResetLife
				ClearMine
				TTDemo1 = Timer
				VRed = Int (Rnd * 2)	'Changes background colors
				VGreen = Int (Rnd * 2)
				VBlue = Int (Rnd * 2)
				If VRed + VGreen + VBlue = 0 Then VBlue = 1		'black not allowed
				Game.SeqCycle = 0
			End If
			
		'-------------------------------------------------------------------------------------------
		
		Case Top10
		
			DrawMenuBackground
			DrawBox 14, 11, 3, 400, 310
			PutLogo 290, 40
			WriteCentered "Top 10", 140, 2, 1
		
			For f = -1 To 9
				Line(197, 200 + f * 30) - Step (394, 0), RGB (128, 128, 128)
			Next
			
			If PosTop10 > 0 Then	'Highlight your score, if among top 10
				Line(187, 175 + (PosTop10 - 1) * 30) - Step (413, 31), RGB (80 + 80 * VRed, 80 + 80 * VGreen, 80 + 80 * VBlue), bf
				Line(190, 178 + (PosTop10 - 1) * 30) - Step (407, 25), RGB (48 + 48 * VRed, 48 + 48 * VGreen, 48 + 48 * VBlue), bf
			End If
			
			For f=0 To 9
				g = len (Toppt(f).Name)
				
				'Truncates the names, if too long to fit
				While TextWidth (left(Toppt(f).Name, g), 1) > 399 - ((TextWidth ("0",1)+2) * (1+len (str(Toppt(f).Score))))
					g -= 1
				Wend
				WriteTXT Left(toppt(f).Name, g), 198, 180 + f * 30, 1, 0
				WriteTXT Str(toppt (f).Score), 602 - ((TextWidth ("0",1) +2)* ( 1 + len (str(Toppt(f).Score)))), 180 + f * 30, 1, 0
			Next
			
			If ConfirmDel = 0 Then
				WriteCentered TXT(82), 520, 1, 0
			ElseIf ConfirmDel = 1 Then
				ShowMSG 1, 5, TXT(83), TXT(84), "", , , Option1
			ElseIf ConfirmDel = 2 Then
				ShowMSG 0, 5, TXT(90), TXT(91), "", , , Option1
			End If
			
			If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
			
			'Deal options: reset top scores / reset highest reached mine
			
			If (KBKey <> LastKBKey And KBKey <> "") Or (MouseClicked = 1) Then
				If ConfirmDel = 0 Then
					If KBKey = "<" Then
						ConfirmDel = 1
						Option1 = 1
					Else
						PosTop10 = 0
						ChangeStatus MenuScreen
					End If
				Else
					If KBKey = "ESC" Then
						ConfirmDel = 0
					ElseIf (KBKey = "U") Or (KBKey = "D") Or (KBKey = "R") Or (KBKey = "L") Then
						Option1 = 1 - Option1
					ElseIf (KBKey ="[") Or (KBKey = "]") Or (MouseClicked = 1) Then
						Select Case ConfirmDel
						Case 1
							If Option1 = 0 Then
								ResetRecordFile
								PosTop10 = 0
							End If
							ConfirmDel = 2
							Option1 = 1

						Case 2
							If Option1 = 0 Then
								Game.MaxReached = 1
								SaveConfigs
								ConfirmDel = 0
							Else 
								ConfirmDel = 0
							End If
						End Select
					End If
				End If
			End If
			
		'-------------------------------------------------------------------------------------------
		
		Case Editor
			
			DoEdit
			If Game.Status = Editor Then DrawScene
			
		'-------------------------------------------------------------------------------------------
			
		End Select
		
		SwapScreens

FinishCycle:
	Wend
	
End Sub

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------

'Pick up gems or other objects

Sub PickUpObj (POX As Integer, POY As Integer)
	With VPlayer
		Select Case TpObject (Object (POX,POY).TP).Item
		Case 1
			.ItOxygen+=1
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn2)
			VSoundEx (4).Time = 10
		Case 2
			.ItScaffold+=1
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn2)
			VSoundEx (4).Time = 10
		Case 3
			.ItPickaxe+=1
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn2)
			VSoundEx (4).Time = 10
		Case 4
			.ItDrill+=1
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn2)
			VSoundEx (4).Time = 10
		Case 5
			.ItBombS+=1
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn2)
			VSoundEx (4).Time = 10
		Case 6
			.ItBombB+=1
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(4).COn2)
			VSoundEx (4).Time = 10
		
		'Gems
		Case 7 To 22
			midiOutShortMsg (hMidiOut, VSoundEx(5).COn1)
			midiOutShortMsg (hMidiOut, VSoundEx(5).COn2)
			VSoundEx (5).Time = 10
			CheckIfGotLife GemValue(TpObject (Object (POX, POY).TP).Item)
			MarkGemPoints (GemValue(TpObject (Object (POX, POY).TP).Item), POX, POY)
			.Score += GemValue(TpObject (Object (POX, POY).TP).Item)
			Mine.Gems -= 1
			
			If Mine.Gems = 0 Then	'All gems where taken
				Game.SeqCycle = 0
				
				If Game.Status = Playing Or Game.Status = Testing Then 
					Game.OldStatus = Game.Status
					ChangeStatus WonMine
					CalcTimeBonus
					
				Else 'If demo, finishes it
					ChangeStatus MenuScreen
					VRed = Int(Rnd*2)
					VGreen = Int(Rnd*2)
					VBlue = Int(Rnd*2)
					If VRed + VGreen + VBlue = 0 Then VBlue = 1
				End If
			End If
		End Select

	End With

	'Clear cell
	If Object (POX, POY).Tp <77 Or Object (POX, POY).Tp > 80 Then			'If activated bomb, does nothing
		If Behavior (TpObject(Object (POX, POY).Tp).Kind).Walk = 1 then		'Don't clear stairs
			Object (POX,POY).Tp = 0
		End If
		Object (POX,POY).IsFalling = 0
		Object (POX,POY).WasFalling = 0
		Object (POX,POY).BeingPushed = 0
		Object (POX,POY).StepNumber = 0
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Check if objects can be pushed, and then start it

Function PushObj (ByVal POX As Integer, ByVal POY As Integer, ByVal MDir As Integer, ByVal Weight As Integer, ByVal Amount As Integer) As Integer 
	Dim As Integer Results, XR, WeightTemp
	Results = Behavior (TpObject(Object (POX, POY).Tp).Kind).PushWeight
	XR = 3 - (MDir * 2)
	
	'First, check if object is falling or will fall now
	If (Behavior (TpObject(Object (POX, POY).tp).Kind).Fall = 1 And POY < Mine.Height And Behavior (TpObject(Object (POX, POY + 1).tp).Kind).Support = 0) Or Object (POX, POY).IsFalling = 1 Then
		Results = 5			'Can't push
	Else	
		
		'Objects at corner can't be pushed
		If POX > 0 And POX < Mine.Width Then
			If Results + Weight > 2 Then
				Results = 3	
				
			ElseIf Results = 2 Then			'Only 1 heavy object can be pushed (wood boxes)
				If Amount = 1 And Behavior (TpObject(Object (POX + XR, POY).Tp).Kind).Empty = 1 And Object (POX + XR, POY - 1).IsFalling = 0 Then
					Results = 2	
				Else
					Results = 3	
				End If
				
			ElseIf Results = 1 Then			'A lightweight object (straw) can be pushed along with another equal or lighter (cars)
				If Amount = 1 Then
					If Behavior (TpObject(Object (POX + XR, POY).Tp).Kind).Empty=1 And Object (POX + XR, POY - 1).IsFalling=0 Then
						Results = 1	
					Else
						WeightTemp = PushObj (POX + XR, POY, MDir, 1, 2)
						If WeightTemp <= 1 Then
							Results = WeightTemp + 1
						Else
							Results = 3
						End If
					End If
				
				ElseIf Amount = 2 And Weight < 2 Then
					If Behavior (TpObject(Object (POX + XR, POY).Tp).Kind).Empty=1 And Object (POX + XR, POY - 1).IsFalling=0 Then
						Results = 1
					Else
						Results = 3
					End If
				Else
					Results = 3
				End If
				
			ElseIf Results = 0 Then
				If Weight > 0 And Amount > 2 Then	
					Results = 3
				Else
					If Behavior (TpObject (Object (POX + XR, POY).Tp).Kind).Empty = 1 And Object (POX + XR, POY - 1).IsFalling = 0 Then
						Results = Weight
					Else
						WeightTemp = PushObj (POX + XR, POY, MDir, Weight, Amount + 1)
						If WeightTemp <= 1 Then
							Results = Weight
						Else
							Results=3
						End If
					End If
				End If
			End If
		Else
			Results = 3
		End If
	End If

	If Results < 3 Then						'If possible, start pushing
		Object (POX,POY).BeingPushed = MDir
		Object (POX,POY).StepNumber = 0
	End If

	Return Results
End Function

'-------------------------------------------------------------------------------------------

'Start a Explosion (bomb or player death)

Sub Explode (ByVal EXX As Integer, ByVal EXY As Integer, ByVal XSize As Integer)
	Dim As Integer LF, LG, NSize
	NSize = XSize
	midiOutShortMsg (hMidiOut, VSoundEx(XSize+1).COn1)
	midiOutShortMsg (hMidiOut, VSoundEx(XSize+1).COn2)
	VSoundEx (XSize + 1).Time = 16

	If XSize = 2 Then XSize = 1
	Object (EXX, EXY).tp = 0
	For LF = -1 To 1
		For lg = -XSize To XSize
			With Object (EXX + LF, EXY + LG)
				If .Tp >= 77 And .Tp <= 80 Then
					Explode (EXX + LF, EXY + LG, Int((.tp - 77) / 2))
				ElseIf Behavior (TpObject(.Tp).Kind).Destroyable>0 Then
					.Tp=0
				End If
			End With
		Next
	Next

	With VPlayer	'Player is near the explosion and must die?
		If .Died = 0 And .x >= EXX - 2 And .X <=EXX + 2 Then 
			If (.X = EXX - 2 And .CurrDirection = 1 And .StepNumber >= Game.Steps * .4) Or (.X = EXX - 1 And (.CurrDirection <> 2 Or .StepNumber <= Game.Steps * .6)) _
			 Or .x = EXX Or (.x = EXX + 1 And (.CurrDirection <> 1 Or .StepNumber <= Game.Steps * .6)) Or (.X = EXX + 2 And .CurrDirection = 2 And .StepNumber >= Game.Steps * .4) Then
				If XSize = 0 Then
					If (.Y = EXY - 1 And .CurrDirection > 3 And .StepNumber >= Game.Steps * .4) Or (.Y = EXY And (.CurrDirection < 3 Or .StepNumber <= Game.Steps * .6)) _
					 Or (.Y = EXY + 1 And .CurrDirection = 3 And .StepNumber >= Game.Steps * .3) Then .Died = 1
				Else
					If (.Y = EXY - 2 And .CurrDirection > 3 And .StepNumber >= Game.Steps * .4) Or (.Y = EXY - 1 And (.CurrDirection <> 3 Or .StepNumber <= Game.Steps * .6)) _
					 Or .Y = EXY Or (.Y = EXY + 1 And (.CurrDirection < 4 Or .StepNumber <= Game.Steps * .6)) _
					  Or (.Y = EXY + 2 And .CurrDirection = 3 And .StepNumber >= Game.Steps * .4) Then .Died = 1
				End If
			End If
		End If
	End With

	'Mark to be drawn by sub DrawScene
	Game.LastExplosion = (Game.LastExplosion + 1) Mod 11
	With Explosion(Game.LastExplosion)
		.X = EXX
		.Y = EXY
		.Kind = XSize + 1
		.Time = 1
	End With

End Sub


'-------------------------------------------------------------------------------------------

'Empties the contents of the array of Mine

Sub ClearMine
	Dim as integer F, G
	For f = -1 To 100
		For g = -1 To 60
			FrGround (f, g) = 0
			BkGround (f, g) = 1
			Object (f, g).tp = 0
			Object (f, g).IsFalling = 0
			Object (f, g).WasFalling = 0
			Object (f, g).BeingPushed = 0
			Object (f, g).StepNumber = 0
		Next
	Next
	Mine.Width = 99
	Mine.Height = 59
	Mine.X = 0
	Mine.Y = 0
	VPlayer.X = 0
	VPlayer.Y = 0
	MAPX = 0
	MAPY = 0
End Sub

'-------------------------------------------------------------------------------------------

'Resets high scores table, and save the file

Sub ResetRecordFile
	Dim as integer F
	Kill "Top10.min"
	CreateRecordTable
	Open "Top10.min" For Output As #1
	For f = 0 To 9
		Print #1, toppt(f).Name; ", " ; Str (toppt(f).Score)
	Next
	Close #1
End Sub

'-------------------------------------------------------------------------------------------

'Chek if among top 10 - asks for the name - saves the file

Function VerifyRecord As Integer
	Dim as integer F
	Dim Posit As Integer
	Dim XKey As String
	Posit = 10
	For F = 9 To 0 Step -1
		If VPlayer.Score > TopPt(f).Score Then Posit = F
	Next
	If Posit < 10 Then
		For f = 9 To Posit Step -1
			TopPt(f+1).Score = TopPt(f).Score
			TopPt(F+1).Name = TopPt(f).Name
		Next
		TopPt(Posit).Score = VPlayer.Score
		EmptyKeyboard
		XKey=""
		
		While XKey <> Chr(13)
			XKey=Inkey
			If Len(XKey)>0 Then
				If InStr(" " + Lt, XKey)>0 And Len (VPlayer.Name) < 20 And XKey <> "," Then VPlayer.Name += XKey
				If XKey=Chr(8) Or XKey=Chr(255)+Chr(83) And Len(VPlayer.Name)>0 Then VPlayer.Name=Left(VPlayer.Name, Len(VPlayer.Name)-1)
			End If
			DrawMenuBackground
			ShowMSG 4, 10, TXT(85), TXT(86), "", , 220
			If VPlayer.Name="" Then
				ShowMSG 2, 10, " ", Chr (32 + 63 * ((Timer * 2) Mod 2)), " ",, 360
			Else
				ShowMSG 2, 10, " ", VPlayer.Name & Chr (32 + 63 * ((Timer * 2) Mod 2)), " ",, 360
			End If
			SwapScreens
		Wend
		Cls
		LastKBKey = "["
		KBKey = "["
		If VPlayer.Name = "" Then VPlayer.Name = "?"
		TopPt(Posit).Name = VPlayer.Name
		
		EmptyKeyboard
		
		Kill "Top10.min"
		Open "Top10.min" For Output As #1
		For f=0 To 9
			Print #1, toppt(f).Name; ", " ; Str(toppt(f).Score)
		Next
		Close #1
	End If

	If Posit < 10 Then Return (Posit + 1) Else Return 0
	
End Function

'-------------------------------------------------------------------------------------------

'Read top 10 file

Sub ReadRecordTable
	Dim as integer F
	If FileExists("Top10.min") Then
		Open "Top10.min" For Input As #1
		For f=0 To 9
			Input #1, TopPt(f).Name, TopPt(f).Score
		Next
		Close #1
	Else
		CreateRecordTable	'file not found
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Resets TOP 10

Sub CreateRecordTable
	TopPt(0).Name = "Top1" : TopPt(0).Score = 15000
	TopPt(1).Name = "Top2" : TopPt(1).Score = 12500
	TopPt(2).Name = "Top3" : TopPt(2).Score = 10000
	TopPt(3).Name = "Top4" : TopPt(3).Score =  9000
	TopPt(4).Name = "Top5" : TopPt(4).Score =  8000
	TopPt(5).Name = "Top6" : TopPt(5).Score =  7000
	TopPt(6).Name = "Top7" : TopPt(6).Score =  5000
	TopPt(7).Name = "Top8" : TopPt(7).Score =  4000
	TopPt(8).Name = "Top9" : TopPt(8).Score =  3000
	TopPt(9).Name = "Top10" : TopPt(9).Score = 2000
End Sub


'-------------------------------------------------------------------------------------------

'FPS Adjust and flip screen

Sub SwapScreens
	Dim As Integer TimeInterval, TimeRemaining

	ScreenSet 1 - ActiveScreen,  ActiveScreen
	ActiveScreen = 1 - ActiveScreen
	
	OldTimer = NewTimer
	NewTimer = Int(Timer * 1000)
	TimeRemaining = 1
	TimeInterval = NewTimer - OldTimer
	TimeRemaining = Game.DelayMSec - TimeInterval 
	If TimeRemaining < 1 Then TimeRemaining = 1
	If MultiKey(SC_LSHIFT) Or MultiKey(SC_RSHIFT) Then
		Sleep 1, 1
	Else
		Sleep TimeRemaining, 1
	End If
 End Sub

'-------------------------------------------------------------------------------------------

'Draw box and show messages

Sub ShowMSG (MColor As Integer, MType As Integer, T1 As String, T2 As String, T3 As String, OX As Integer = 400, OY As Integer= 300, MOption As Integer = 0)

'Types:
'0-No icon + press any key
'1-no icon + yes / no
'2-exclamation + press any key
'3-exclamation + yes / no
'4-Question + press any key
'5-Question + yes / no
'6-Ok + press any key
'7-Ok + + yes / no
'8-Wait + press any key
'9-Wait + yes / no
'10-Medal + press any key
'12-ByNIZ + press any key

	Dim As Integer Larg, Alt, V, F
	Dim As String Tex (2)
	
	If T2 = "" Then
		Alt = 1
	ElseIf T3 = "" Then
		Alt = 2
	Else
		Alt = 3
	End If
	V = Alt
	
	Tex(0) = T1
	Tex(1) = T2
	Tex(2) = T3
	
	Larg = 10
	For F = 0 To 2
		If TextWidth (Tex (f), - (f = 0)) > Larg Then Larg = TextWidth (Tex (f), - (f = 0))
	Next
	
	Larg = Int (Larg / 32) + 1
	If MType > 1 Then Larg += 2
	If (MType Mod 2 = 1) And (Larg < 7) Then Larg = 7
	If MType Mod 2 = 1 Then Alt += 2
	If MType > 1 And Alt < 2 Then Alt = 2

	DrawBox Larg, Alt, MColor, OX, OY
	For F = 0 To V - 1
		WriteTXT Tex(F), OX - 24 * (MType > 1) - TextWidth(Tex(F), - (f = 0)) /2  , OY - Alt * 16 + F * 32 + 4, - (f = 0), 0
	Next
	If MType > 1 Then Put (OX - Larg * 16, OY - Alt * 16), BMP (252 + Int(MType / 2)),Trans

	MouseYesNo = 0

	If MType Mod 2 = 1 Then
		Put (OX - 66 + MOption * 76, Oy + Alt * 16 - 38), BMP (276), (576, 0) - (630, 32), Trans
		Put (OX + 10 - 76 * MOption, Oy + Alt * 16 - 38), BMP (276), (576, 33) - (630, 65), Trans
		WriteTXT TXT(58), OX - 38 - TextWidth (TXT (58), 0)/2, Oy + Alt * 16 - 32, 0, 0
		WriteTXT TXT(59), OX + 38 - TextWidth (TXT (59), 0)/2, Oy + Alt * 16 - 32, 0, 0
		Put (OX - 66 + MOption * 76, Oy + Alt * 16 - 40), BMP (276), (576, 66) - (630, 102), Trans
		If (MouseY > OY + Alt * 16 - 39) And (MouseY < Oy + Alt * 16 - 4) Then						'Mouse over options YES or NO?
			If MouseX > OX - 67 And MouseX < OX - 9 Then MouseYesNo = 1
			If MouseX > OX + 9 And MouseX < OX + 67 Then MouseYesNo = 2
		End If
	End If

End Sub

'-------------------------------------------------------------------------------------------

'Draw box for messages

Sub DrawBox (H As Integer, V As Integer, QCor As Integer, OX As Integer = 400, OY As Integer = 300)
	Dim as integer F, G
	If QCor < 4 Then
		Put (OX - 16 - H * 16, OY - 16 - V * 16), BMP (248 + QCor), (0, 0) - Step (15, 15), Alpha
		Put (OX - 16 - H * 16, OY + V * 16), BMP (248 + QCor), (0, 48) - Step (15, 15), Alpha
		Put (OX + H * 16, OY - 16 - V * 16), BMP (248 + QCor), (48, 0) - Step (15, 15), Alpha
		Put (OX + H * 16, OY + V * 16), BMP (248 + QCor), (48, 48) - Step (15, 15), Alpha
		For F = 0 To H - 1
			Put (OX - H * 16 + F * 32, OY - 16 - V * 16), BMP (248 + QCor), (16, 0) - Step (31, 15), Alpha
			Put (OX - H * 16 + F * 32, OY + V * 16), BMP (248 + QCor), (16, 48) - Step (31, 15), Alpha
			For G = 0  To V - 1
				Put (OX - H * 16 + F * 32, OY - V * 16 + G * 32), BMP (248 + QCor), (16, 16) - Step (31, 31), Alpha
			Next
		Next
		For G = 0  To V - 1
			Put (OX - 16- H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (0, 16) - Step (15, 31), Alpha
			Put (OX + H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (48, 16) - Step (15, 31), Alpha
		Next
	Else
		QCor -= 4
		Put (OX - 16 - H * 16, OY - 16 - V * 16), BMP (248 + QCor), (0, 0) - Step (15, 15), Trans
		Put (OX - 16 - H * 16, OY + V * 16), BMP (248 + QCor), (0, 48) - Step (15, 15), Trans
		Put (OX + H * 16, OY - 16 - V * 16), BMP (248 + QCor), (48, 0) - Step (15, 15), Trans
		Put (OX + H * 16, OY + V * 16), BMP (248 + QCor), (48, 48) - Step (15, 15), Trans
		For F = 0 To H - 1
			Put (OX - H * 16 + F * 32, OY - 16 - V * 16), BMP (248 + QCor), (16, 0) - Step (31, 15), Trans
			Put (OX - H * 16 + F * 32, OY + V * 16), BMP (248 + QCor), (16, 48) - Step (31, 15), Trans
			For G = 0  To V - 1
				Put (OX - H * 16 + F * 32, OY - V * 16 + G * 32), BMP (248 + QCor), (16, 16) - Step (31, 31), Trans
			Next
		Next
		For G = 0  To V - 1
			Put (OX - 16- H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (0, 16) - Step (15, 31), Trans
			Put (OX + H * 16, OY - V * 16 + G * 32), BMP (248 + QCor), (48, 16) - Step (15, 31), Trans
		Next
	End If
End Sub
 
'-------------------------------------------------------------------------------------------

'Draws the Game LOGO

Sub PutLogo (LX As Integer, LY As Integer)
	Put (LX, LY), BMP (211), Trans
End Sub

'-------------------------------------------------------------------------------------------

Function CTRX As Integer
	With VPlayer
		If .X < 12 Then
			Return .X * 32 + 16
		ElseIf .X > Mine.Width - 12 Then
			Return 784 - (Mine.Width - .X) * 32
		Else	
			Return 399
		End If
	End With
End Function

'-------------------------------------------------------------------------------------------

Function CTRY As Integer
	With VPlayer
		If .Y < 8 Then
			Return .Y * 32 + 16
		ElseIf .Y > Mine.Height - 8 Then
			Return 500 - (Mine.Height - .Y) * 32
		Else	
			Return 240
		End If
	End With
End Function

'-------------------------------------------------------------------------------------------

Sub MarkGemPoints (Points As Integer, X As Integer, Y As Integer)
	With  MSG (NextMSG)
		.Cycle = 63
		.Score = Points
		.X = X
		.Y = Y
	End With
	NextMSG = (NextMSG + 1) Mod 10
End Sub

'-------------------------------------------------------------------------------------------

'Returns keys for demo mode

Function NextKeyForDemo As String
	Dim KeyTemp As String
	Dim As Integer ValTemp, BX, BY

	BX = VPlayer.X
	BY = VPlayer.Y
	If VPlayer.StepNumber = Game.Steps Then
		Select Case VPlayer.CurrDirection
		Case 1
			bx = bx + 1
		Case 2
			bx = bx - 1
		Case 3 
			by = by - 1
		Case 4, 5
			by = by + 1
		End Select
	End If
	If MensTime > 0 Then
		MensTime = MensTime-1
		If MensTime > 0 Then
			Return " " 
			GoTo SaiDaqui
		End If
	End If
	MSGDemo = 0

NextOne:
	If PositDemo > Len (KBKeysDemo)/3 Then
		PositDemo = 0
		Return "ESC"
	Else
		KeyTemp = Mid(KBKeysdemo, positdemo * 3 + 1, 1)
		Select Case KeyTemp
		
		Case "M"
			MSGDemo = Val(Mid(KBKeysdemo, positdemo * 3 + 2, 2))
			MensTime = 250
			PositDemo = PositDemo + 1
			Return " "
			
		Case "#"
			Return "ESC"
			PositDemo = 0
			
		Case "W"
			ValTemp=Val(Mid(KBKeysdemo, positdemo * 3 + 2, 2))
			If DemoW1 = 0 Then
				DemoW1 = ValTemp
				DemoW2 = 0
			Else
				DemoW2 = DemoW2 + 1
				If DemoW2 >= DemoW1 Then
					DemoW1 = 0
					DemoW2 = 0
					PositDemo = PositDemo + 1
					GoTo NextOne
				End If
			End If
			Return ""
			
		Case "I"
			KeyTemp = Mid(KBKeysdemo, positdemo * 3 + 2, 1)
			If KeyTemp="D" Then KeyTemp="V"
			If KeyTemp="C" Then
				If Mid(KBKeysdemo, positdemo * 3 + 3, 1) = "R" Then
					VPlayer.DrillDirection = 1
				ElseIf Mid(KBKeysdemo, positdemo * 3 + 3, 1) = "L" Then
					VPlayer.DrillDirection = 2
				End If
			End If
			PositDemo = PositDemo + 1
			Return KeyTemp
			
		Case "R"
			ValTemp=Val(Mid(KBKeysdemo, positdemo * 3 + 2, 2))
			If bX < ValTemp Then
				Return KeyTemp
			Else
				PositDemo = PositDemo + 1
				GoTo NextOne
			End If
			
		Case "L"
			ValTemp=Val(Mid(KBKeysdemo, positdemo * 3 + 2, 2))
			If bX > ValTemp Then
				Return KeyTemp
			Else
				PositDemo = PositDemo + 1
				GoTo NextOne
			End If
			
		Case "U", "D"
			ValTemp=Val(Mid(KBKeysdemo, positdemo * 3 + 2, 2))
			If bY <> ValTemp Then
				Return KeyTemp
			Else
				PositDemo = PositDemo + 1
				GoTo NextOne
			End If
		End Select
	End If

SaiDaqui:

End Function

'-------------------------------------------------------------------------------------------

'Read internal mine from minas.bin

Sub ReadInternalMine (MineNumber As Integer, AmountOnly As Integer = 0)
	Dim As LongInt FilePos, FileTam
	Dim As UShort MineTemp, MinesCount
	Dim As UByte TimeIntervalrary1
	Randomize

	ClearMine
	Mine.Gems = 0
	
	If FileExists ("MINAS.Bin") Then
		Open "MINAS.Bin" For Binary As #1
		FileTam = Lof (1)
		If FileTam > 20 Then
			Get #1, , MinesCount
			Game.HowManyMines = MinesCount
			
			FilePos = 3
			
			If AmountOnly = 0 Then
				
				Get #1, , MineTemp
				Get #1, , Mine.Width
				Get #1, , Mine.Height
				Get #1, , Mine.DarkType
				Get #1, , Mine.Time
				
				While MineTemp < MineNumber		'Search our mine
					
					FilePos = FilePos + ((Mine.Height * Mine.Width) * 3) + 9
					Get #1, FilePos, MineTemp
					Get #1, , Mine.Width
					Get #1, , Mine.Height
					Get #1, , Mine.DarkType
					Get #1, , Mine.Time
				Wend
				
				ReadMineDetails 0				'Read cells
				
			End If
		Else		'Anything wrong with minas.bin
			MessageBox NULL,TXT(87), TXT(0), MB_ICONERROR
			ChangeStatus MenuScreen
		End If
		
		Close #1
		
	Else  'file not found
		MessageBox NULL, TXT(88), TXT(0), MB_ICONERROR
		ChangeStatus MenuScreen
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Read mine cells (tiles)

Sub ReadMineDetails (Editing As Integer = 0)
	Dim As Integer MXR, MYR, F, G
	MXR=0
	MYR=0

	If Editing = 0 Then
		If Mine.Width < 24 Then MXR = Int (25 - Mine.Width) / 2
		If Mine.Height < 16 Then MYR = Int(17 - Mine.Height) / 2
		For f = -1 To Mine.Width
			For g = -1 To Mine.Height
				Object (mxr + f, myr + g).tp = 31
			Next
		Next
	End If
	
	Mine.Width -= 1
	Mine.Height -= 1
	
	'Reads line by line
	For g = 0 To Mine.Height

		For f = 0 To Mine.Width
			Get #1, , BkGround (MXR + f, MYR + g)
			Get #1, , FrGround (MXR + f, MYR + g)
			Get #1, , Object (MXR + f, MYR + g).tp
			
			'Player position?
			If Object (MXR + f, MYR + g).tp = 85 Then
				Mine.X = MXR + F
				Mine.Y = MYR + G
				VPlayer.X = Mine.X
				VPlayer.Y = Mine.Y
				Object (MXR + f, MYR + g).tp = 0
			ElseIf TpObject(Object (MXR+f,MYR+g).Tp).Kind = 5 Then		'Counts gems
				Mine.Gems += 1
			End If
		Next
	Next
	Sleep 1, 1
	Mine.Width += MXR
	Mine.Height += MYR
	Game.LastExplosion = 0
	Game.Cycle = 0
	Started = 0
End Sub

'-------------------------------------------------------------------------------------------

'Search for custom mines in directory "MINAS"

Sub SearchCustomMines
	Dim As String VarFileName
	Dim As Integer SeqNumber, F
	
	ScreenSet ActiveScreen,  ActiveScreen
	SeqNumber = 0
	
	Line (298, 320) - (502, 344), &HFFFFFF, b
	
	For F = 0 To 999
		line (300 + f/5, 322) - step (0, 20), &H7080F0
		VarFileName = "Minas\M" + Right("000" & Str(f), 3) + ".MAP"
		If FileExists (VarFileName) Then
			CustomMine (SeqNumber) = F
			SeqNumber +=1
		End If
	Next
	If SeqNumber < 999 Then
		For F = SeqNumber To 999
			CustomMine (f) = 0
		Next
	End If
	VPlayer.CurrentMine = CustomMine (0)
	CustomMineQt = SeqNumber
End Sub

'-------------------------------------------------------------------------------------------

'Random sound for game over ARRRG

Sub GameOverRandomSound
	Dim Nota As Integer
	
	Randomize
	
	If Game.Status <> GameOver Or (Rnd * 500) < 10 Then
		Nota = (Int(Rnd * 32) + 64) Shl 8
		midiOutShortMsg (hMidiOut, &H65c7)
		midiOutShortMsg (hMidiOut, &H600087 Or LastNoteGameOver)
		midiOutShortMsg (hMidiOut, &H600097 Or Nota)
		LastNoteGameOver = Nota
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Random sound for game won ARRRG

Sub GameWonRandomSound
	Dim Nota As Integer
	
	Randomize
	
	If (NotesGameWon = 0) Or (NotesGameWon < 6 And Timer - GameWonNoteTimer >= .11) Then
		NotesGameWon += 1
		If NotesGameWon = 1 Then
			Nota = (Int(Rnd * 32) + 36) Shl 8
		Else
			Nota = (Int(Rnd * 6) + (LastNoteGameOver Shr 8) - 1) Shl 8
			If Nota = LastNoteGameOver Then Nota -= 512
		End If
		midiOutShortMsg (hMidiOut, &H76c0)  '26, 29, 2d, 6b
		midiOutShortMsg (hMidiOut, &H6bc1)  '26, 29, 2d, 6b
		midiOutShortMsg (hMidiOut, &H5f0080 Or (LastNoteGameOver + 513))
		midiOutShortMsg (hMidiOut, &H6f0080 Or LastNoteGameOver)
		midiOutShortMsg (hMidiOut, &H600090 Or (Nota + 513))	
		midiOutShortMsg (hMidiOut, &H6f0090 Or Nota)	
		LastNoteGameOver = Nota
		GameWonNoteTimer = Timer 
	ElseIf Timer - GameWonNoteTimer >= .6 Then
		NotesGameWon = 0
	End If
End Sub


'-------------------------------------------------------------------------------------------

'Save configs

Sub SaveConfigs

	Kill "Config.min"
	Open "Config.min" For Output As #1
	Print #1, Game.Volume
	Print #1, Game.MaxReached
	Print #1, CurrentLanguage
	Close #1
End Sub

'-------------------------------------------------------------------------------------------

'Read language pack

Function ReadLanguagePack (LanguageN As String) As Integer
	Dim as integer F

	If LanguageN = "Portugues" Then
		ReadPortuguese
	Else
		If FileExists ("lang\" + LanguageN + ".Lng") Then
			Open "lang\" + LanguageN + ".LNG" For Input As #1
			F = 0
			While Not Eof (1)
				Input #1, TXT(F)
				F += 1
			Wend
			Close #1
			Return 0
			
		Else
			ReadPortuguese
			Return 1
		End If
	End If
End Function

'-------------------------------------------------------------------------------------------

'Search language pack files (dir LANG)

Sub SearchLanguagePacks ()
	Dim As String Arquivo
	Dim as integer F
	
	LanguangesQtt = 0
	Arquivo = Dir ("Lang\*.Lng")
	While Len(Arquivo) > 0 And LanguangesQtt < 9
		LanguangesQtt += 1
		Language (LanguangesQtt) = Left(Arquivo, Len(Arquivo) - 4)
		Arquivo = Dir ()
	Wend
	
	'Marks the current language
	LangNumber = 0
	For f = 0 To LanguangesQtt
		If Language (F) = CurrentLanguage Then LangNumber = F
	Next
	
End Sub

'-------------------------------------------------------------------------------------------

'Check if must earn a life

Sub CheckIfGotLife (AddPoints As Integer)
	If Int(VPlayer.Score / 1000) < Int ((VPlayer.Score + AddPoints) / 1000) Then
		VPlayer.Lives += 1
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Calculate time bonus

Sub CalcTimeBonus
	If Mine.Time = 0 Then
		PtBonus = (300 - VPlayer.Time)
		If PtBonus > 100 Then PtBonus = 100
	Else
		PtBonus = (Mine.Time - VPlayer.Time)
		If PtBonus > 100 Then PtBonus = 100
	End If
	CheckIfGotLife PtBonus
End Sub

'-------------------------------------------------------------------------------------------

'Portuguese texts

Sub ReadPortuguese
	TXT(00) = "Erro"
	TXT(01) = "Dispositivo MIDI não pode ser aberto."
	TXT(02) = "Iniciar"
	TXT(03) = "Selecionar fase"
	TXT(04) = "Recordes"
	TXT(05) = "FreeBasic Miner ?"
	TXT(06) = "Volume"
	TXT(07) = "Selecionar Idioma (Language)"
	TXT(08) = "Fases personalizadas"
	TXT(09) = "Criar e editar minas"
	TXT(10) = "Sair"
	TXT(11) = "O objetivo do jogo é coletar todas as pedras preciosas existentes em cada mina."
	TXT(12) = "Você é capaz? Se ficar preso ou desistir, pressione ESC para suicidar e recomeçar"
	TXT(13) = "Quando não houver nada sob seus pés, você cairá. Vejamos..."
	TXT(14) = "Agora vamos passar por baixo de um objeto. Enquanto estamos embaixo, os objetos"
	TXT(15) = "permanecem suspensos, e caem depois que saimos."
	TXT(16) = "Ao lado, temos carrinhos, que podem ser empurrados, independente da quantidade."
	TXT(17) = "Eles também cairão quando não houver nada abaixo."
	TXT(18) = "Agora vamos empurrar palha. É possível empurrar até dois blocos simultaneamente."
	TXT(19) = "Se houver palha e um carrinho lado a lado, também podemos empurrar o par,"
	TXT(20) = "mas não é possível empurrar mais do que 2 desses objetos."
	TXT(21) = "Ao lado, vamos empurrar uma caixa de madeira. Ela é mais pesada,"
	TXT(22) = "por isso só é possível empurrar uma de cada vez."
	TXT(23) = "Ao lado há duas caixas, e por isso não conseguiremos empurrar."
	TXT(24) = "Agora vamos andar pela terra, escavando-a."
	TXT(25) = "Existem solos de cores e texturas diferentes, mas todos se comportam da mesma"
	TXT(26) = "maneira: simplesmente são eliminados quando passamos por eles."
	TXT(27) = "Ao lado, vamos pegar uma furadeira, e em seguida vamos, usá-la, pressionado C."
	TXT(28) = "Veja ao lado os tipos de paredes que podem ser destruídas."
	TXT(29) = "Agora acabamos de pegar uma pequena bomba. Vamos acioná-la pressionando D"
	TXT(30) = "e sair do local antes que ela exploda!!!"
	TXT(31) = "Como você viu, também dá pra destruir as rochas. Em seguida, vamos"
	TXT(32) = "pegar e utilizar uma picareta, pressionando B."
	TXT(33) = "Perfuramos o chão, destruindo-o, e por isso acabamos descendo."
	TXT(34) = "Vamos pegar bombas maiores e mais poderosas, que acionaremos pressionando E."
	TXT(35) = "Veja que as rochas serão destruídas, mas o piso ficará intacto, pois foi feito de"
	TXT(36) = "materiais indestrutíveis. Ao acionar bombas, não se esqueça de se afastar!"
	TXT(37) = "Agora vamos pegar um suporte. Ele serve para que os objetos acima não caiam."
	TXT(38) = "Vamos acioná-lo pressionando A abaixo da rocha à direita."
	TXT(39) = "Viu? A rocha não caiu! Agora vamos tentar experimentar explodir uma"
	TXT(40) = "estrutura de aço..."
	TXT(41) = "Vamos perder tempo, pois isso não será destruído... Vamos procurar uma saída."
	TXT(42) = "Abaixo há uma garrafa de oxigênio. Com ela, será possível passar mais tempo na água."
	TXT(43) = "Sem essas garrafas, é possível passar um período bem curto na água."
	TXT(44) = "Vamos correr, antes que o oxigênio se esgote! Vamos achar uma escada para"
	TXT(45) = "sairmos da água!"
	TXT(46) = "É isso!  E recolhendo todas as pedras, você passa de fase."
	TXT(47) = "Você pode tentar coisas como sair debaixo de uma pedra e voltar rapidamente..."
	TXT(48) = "Veja aqui a indicação de quantas pedras ainda restam a recolher. Nos quadros"
	TXT(49) = "ao lado também aparecerão outros itens que forem recolhidos."
	TXT(50) = "Falha na leitura do arquivo da mina."
	TXT(51) = "Use as setas para mover. Ao selecionar, pressione ENTER ou ESPAÇO."
	TXT(52) = "Pressione ESC para sair. Use (Page UP) e (Page Down) para avançar."
	TXT(53) = "Pressione ESPAÇO ou ENTER ao terminar."
	TXT(54) = "Obs.: afeta o volume do sintetizador de SW do Windows."
	TXT(55) = "Não há nenhuma mina personalizada salva."
	TXT(56) = "Pressione alguma tecla para retornar ao menu."
	TXT(57) = "Deseja mesmo encerrar?"
	TXT(58) = "Sim"
	TXT(59) = "Não"
	TXT(60) = "Prepare-se para iniciar"
	TXT(61) = "> Seja rápido!"
	TXT(62) = "PAUSA"
	TXT(63) = "Pressione qualquer tecla"
	TXT(64) = "Modo Mapa"
	TXT(65) = "Use: Setas para movimentar - ESC ou M para sair"
	TXT(66) = "Atenção! O tempo continua contando no modo mapa"
	TXT(67) = "Aguarde alguns segundos na tela do menu para ver uma demonstração"
	TXT(68) = "A ideia do jogo é simples: recolher todas as pedras preciosas que existem em cada uma das"
	TXT(69) = "minas. O desafio está em ser capaz de chegar até elas. Escave a terra, empurre objetos,"
	TXT(70) = "destrua paredes, recolha e utilize as ferramentas e bombas, e tome cuidado com certos"
	TXT(71) = "objetos, e também evite afogar-se ou ficar preso em um lugar de onde não consiga sair."
	TXT(72) = "Se ficar preso, ou quando quiser, pressione ESC para morrer e tentar de novo."
	TXT(73) = "Se preferir, pressionando SHIFT o jogo fica acelerado."
	TXT(74) = "Dica: Quanto mais rápido recolher tudo, mais pontos irá ganhar!"
	TXT(75) = "Agradecimento Especial (Special Thanks to): The FreeBASIC development team"
	TXT(76) = "Passou!!! Parabéns!!!"
	TXT(77) = "Pontos pelo tempo"
	TXT(78) = "Bom trabalho nessa mina personalizada"
	TXT(79) = "Pontos totais: "
	TXT(80) = "VENCEU"
	TXT(81) = "Parabéns! Você concluiu o jogo!"
	TXT(82) = "Pressione DELETE para apagar os recordes"
	TXT(83) = "Tem certeza de que deseja apagar os recordes,"
	TXT(84) = "eliminando seus registros de pontuação?"
	TXT(85) = "Parabéns!! Você entrou para a lista de recordistas!"
	TXT(86) = "Digite seu nome e pressione ENTER"
	TXT(87) = "Arquivo MINAS.BIN está corrompido ou foi alterado."
	TXT(88) = "Arquivo MINAS.BIN não foi encontrado"
	TXT(89) = "Para alternar entre janela e tela cheia: ALT + ENTER"
	TXT(90) = "Quer apagar o registro de minas alcançadas?"
	TXT(91) = "(Só poderá iniciar o jogo na primeira mina)"
	TXT(92) = "Procurando minas personalizadas."
	TXT(93) = "Aguarde um instante . . ."
	TXT(94) = "Bonus extra pelas vidas"
	TXT(95) = "Encerrar o teste e retornar para o editor?"
	TXT(96) = "Para encerrar o teste, pressione ESC."
	TXT(97) = "Pressione TAB para iniciar uma mina em branco, e ESC para sair."
	TXT(98) = "A mina sofreu alterações e não foi salva."
	TXT(99) = "Fechar a mina e iniciar uma nova (em branco)?"
	TXT(100)= "Não é permitido uma mina sem pedras preciosas."
	TXT(101)= "Digite o número para gravar a mina (0 a 999). Tecle ESC para desistir"
	TXT(102)= "Obs.: Se houver arquivo com nome igual, será substituído."
	TXT(103)= "A mina deve ser solucionada no claro?"
	TXT(104)= "(Escolha SIM para claro e NÃO para escuro)"
	TXT(105)= "Fechar o editor?"
	TXT(106)= "Digite o tempo para completar a mina (em segundos aprox.)."
	TXT(107)= "Obs.: Digite 0 se o tempo for livre."
	TXT(108)= "Testar a mina?"
	TXT(109)= "Delimite a área a editar. Pressione ESC para desistir."
	TXT(110)= "Setas de direção: mover  - ESPAÇO, ENTER ou ESC: terminar"
	TXT(111)= "Delimite a área a apagar. Pressione ESC para desistir."
	TXT(112)= "A mina foi salva com sucesso."
	TXT(113)= "Fechar a mina para abrir outra?"
	TXT(114)= ""
	TXT(115)= ""
	TXT(116)= ""
	TXT(117)= ""
	TXT(118)= ""
	TXT(119)= ""
	TXT(120)= ""
	TXT(121)= ""
	TXT(122)= ""
	TXT(123)= ""
	TXT(124)= ""
	TXT(125)= ""
	TXT(126)= ""
	TXT(127)= ""
	TXT(128)= ""
	TXT(129)= ""
	TXT(130)= ""
	TXT(131)= ""
	TXT(132)= ""
	TXT(133)= ""
	TXT(134)= ""
	TXT(135)= ""
	TXT(136)= ""
	TXT(137)= ""
	TXT(138)= ""
	TXT(139)= ""
	TXT(140)= ""
	TXT(141)= ""
	TXT(142)= ""
	TXT(143)= ""
	TXT(144)= ""
	TXT(145)= ""
	TXT(146)= ""
	TXT(147)= ""
	TXT(148)= ""
	TXT(149)= ""
	TXT(150)= ""
End Sub

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------

'EDITOR

'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------
'-------------------------------------------------------------------------------------------



'-------------------------------------------------------------------------------------------

'Writes row / col numbers

Sub WriteNumberLit (ByVal Number As Integer, X1 As Integer, Y1 As Integer)

	Put (x1, Y1), BMP (274), (Int(Number/10) * 6, 0) - Step(5, 7), Trans
	Put (x1 + 6, Y1), BMP (274), ((Number Mod 10) * 6, 0)- Step(5, 7), Trans

End Sub

'-------------------------------------------------------------------------------------------

'Draws a box

Sub DrawLine (x1 As Integer, y1 As Integer, x2 As Integer, y2 As Integer, WColor As Integer)
	Select Case WColor
	Case 0
		ColorRGB = &H00FF00
	Case 1
		ColorRGB = &HFFFF00
	Case 2
		ColorRGB = &HFF4040
	Case 3
		ColorRGB = &H9F0000
	End Select
	Line (x1, y1) - (x2, y1 + 2), ColorRGB, BF
	Line (x1, y1) - (x1 + 2, y2), ColorRGB, BF
	Line (x1, y2 - 2) - (x2, y2), ColorRGB, BF
	Line (x2 - 2, y1) - (x2, y2), ColorRGB, BF
End Sub

'-------------------------------------------------------------------------------------------

'Count gems in the mine

Function CountGems As Integer
	Dim as integer F, G
	Dim CountAmount As Integer
	CountAmount = 0
	For f = 0 To 99
		For g = 0 To 59
			If (Object (f, g).TP >= 40) And (Object (f, g).TP <= 55) Then CountAmount += 1
		Next
	Next
	Return CountAmount
End Function

'-------------------------------------------------------------------------------------------

'Returns the lowest row

Function LastRow As Integer
	Dim As integer LMax, f, g
	LMax = 1
	
	For F = 0 To 99
		For G = 0 To 59
			If Object (f,g).TP > 0 Or BkGround (f, g) <> 1 Or FrGround (f,g )>0 Then
				If G > LMaX Then LMaX = G
			End If
		Next
	Next
	Return LMax
End Function

'-------------------------------------------------------------------------------------------

'Returnsthe rightmost column

Function LastCol As Integer
	Dim as integer LMax, f, g
	LMax = 1
	
	For F = 0 To 99
		For G = 0 To 59
			If Object (f,g).TP > 0 Or BkGround (f, g) <> 1 Or FrGround (f,g )>0 Then
				If F > LMaX Then LMaX = F
			End If
		Next
	Next
	Return LMax
End Function

'-------------------------------------------------------------------------------------------

'Save the mine  - ask file name (number)


Sub SaveMine (ForTest As Integer = 0)
	Dim As String RowNumber, VarFileName, LMNum, LocalKey 
	Dim As Integer MineNumber, MaiorX, MaiorY, ValTemp, f, g

	Mine.Gems = CountGems ()
	
	Cls
	SwapScreens

	If Mine.Gems = 0 Then	'Not allowed
		EmptyKeyboard 
		Cls
		ShowMSG 5, 8, TXT (100), "", ""
		SwapScreens
		Cls
		While inkey <> ""
			sleep 1, 1
		Wend
		While Inkey = ""
			Sleep 1, 1
		Wend
		EmptyKeyboard
	Else
		If ForTest = 0 Then		'Ask for file name (mine number)
			
			LMNum= Str (Mine.Number)
			EmptyKeyboard
			LocalKey = ""
			
			While LocalKey <> Chr(27) And LocalKey <> Chr(13)
				Cls
				ShowMSG 5, 4, TXT(101), TXT(102), LMNum & Chr (32 + 63 * ((Timer * 2) Mod 2))
				
				If LocalKey >= "0" And LocalKey <= "9" And Len (LMNum) < 3 Then
					If LMNum = "0" Then LMNum = "0"
					LMNum += LocalKey
				ElseIf LocalKey = Chr(8) Or LocalKey = c255 + Chr(83) Then
					lMNum = Left (LMNum, Len (LMNum) - 1)
				End If		
				SwapScreens	
				LocalKey = Inkey 
					
			Wend
			Cls
			SwapScreens
			
			VarFileName = "Minas\M" + Right("000" & Str(LMNum),3) + ".MAP"
			Mine.Number= Val(LMNum)
		Else
			VarFileName = "Minas\TESTE.MAP"
		End If
		
		Cls
		
		If ForTest <> 0 Or LocalKey = Chr (13) Then		'Ask for light / dark
		
			If ForTest = 0 Then
				LocalKey=""
				While Inkey<>""
					Sleep 10, 1
				Wend
				Option1 = Mine.DarkType
				While LocalKey <> " " And LocalKey <> Chr(27) And LocalKey <> Chr(13)
					Cls
					ShowMSG 5, 5, TXT(103), TXT(104), "", , , Option1
					LocalKey=Inkey
					ReadMouse
					If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
					If (MouseClicked = 1) And (MouseYesNo > 0) Then LocalKey = " "
					If (LocalKey = c255+ "H") Or (LocalKey = c255+ "K") Or (LocalKey = c255+ "M") Or (LocalKey = c255+ "P") Then Option1 = 1 - Option1
					SwapScreens
				Wend
				Cls
			End If
			
			If ForTest <> 0 Or LocalKey <> Chr(27) Then		'Ask for time to solve the mine (or 0 for free)
				If ForTest = 0 Then
					Mine.DarkType = Option1

					LMNum = Str(Mine.Time)
				
					While Inkey <> ""
						Sleep 10
					Wend
					LocalKey = ""
					While LocalKey <> Chr(27) And LocalKey <> Chr(13)
						Cls
						ShowMSG 5, 4, TXT(106), TXT(107), LMNum & Chr (32 + 63 * ((Timer * 2) Mod 2))
						If (LocalKey >= "0") And (LocalKey <= "9") And (Len (LMNum) < 5) Then
							If LMNum = "0" Then LMNum = ""
							LMNum += LocalKey
						ElseIf LocalKey = Chr(8) Or LocalKey = c255 + Chr(83) Then
							lMNum = Left(LMNum, Len (LMNum) - 1)
						End If
						LocalKey = Inkey
						SwapScreens
					Wend
					Cls
				End If
				
				If ForTest <> 0 Or LocalKey = Chr(13) Then
					If ForTest = 0 Then
						Mine.Time=Val(LMNum)
						Mine.Changed = 0
						EdShow = 2
					End If
					
					'Save the file
					
					Mine.Width = LastCol () + 1
					Mine.Height = LastRow () + 1
					
					'Size and other informations
					Kill VarFileName
					Open VarFileName For Binary As #1
					Put #1,, Mine.Width
					Put #1,, Mine.Height
					Put #1,, Mine.DarkType
					Put #1,, Mine.Time
				 
					'Row by row
					For g=0 To Mine.Height-1
						
						For f= 0 To Mine.Width - 1
							Put #1,,BkGround(f, g)
							Put #1,,FrGround (f, g)
							If VPlayer.x=f And VPlayer.y = g Then	'Player position
								Object (f, g).TP = 85
								Put #1,,Object (f, g).TP
								Object (f, g).TP = 0
							Else
								Put #1,, Object (f, g).TP
							End If
						Next
					Next
					Close #1
										
					Cls
					SwapScreens
					Cls
					If ForTest = 0 Then					'Success message
						ShowMSG 6, 6, TXT(112), "", ""
						SwapScreens
						While Inkey <> ""
							Sleep 1, 1
						Wend
						While Inkey = ""
							Sleep 1, 1
						Wend
						Cls
					End If
					EmptyKeyboard
				Else
					LastKBKey = "ESC"
				End If
			Else
				LastKBKey = "ESC"
			End If
		Else
			LastKBKey = "ESC"
		End If
	End If 

	EmptyKeyboard
	
End Sub

'-------------------------------------------------------------------------------------------

'Editor main sub

Sub DoEdit

	Dim as integer F, G
	MousePos = MousePosEd ()

	Select Case Game.EdStatus
	Case Editing
		EdX1 = Int (MouseX / 32)
		EdY1 = Int (MouseY / 32)
		Select Case KBKey
		Case "ESC"
			If KBKey <> LastKBKey Then Game.EdStatus = AnswerExit
		Case "U"
			MapY -= 1
			If MapY < 0 Then MapY = 0
		Case "D"
			MapY += 1
			If MapY > 43 Then MapY = 43
		Case "R"
			Mapx += 1
			If MapX > 75 Then MapX = 75
		Case "L"
			MapX-=1
			If MapX < 0 Then MapX = 0
		End Select
		
		If (MouseClicked = 1) Or ((MouseB > 0) And ((MousePos = EdBottomBar) Or (MousePos = EdLeft) Or (MousePos = EdRight))) Then
			Select Case MousePos
			Case EdOutOfScreen
				'Nothing to do
			Case EdScreen
				EdX2 = EDX1
				EdY2 = EDY1
				EdXX1 = EDX1
				EdXX2 = EDX2
				EdYY1 = EDY1
				EdYY2 = EDY2
				If SelectedItem = 0 Then
					If (VPlayer.x <> Mapx + edx1) Or (VPlayer.y <> Mapy + edy1) Then
						SaveUndo
						VPlayer.x = Mapx + edx1
						VPlayer.y = Mapy + edy1
						Mine.Changed = 1
					End If
				Else
					Game.EdStatus = Selecting
				End If
			Case EdBegin
				FirstItemShowed = 0
			Case EdLeft
				FirstItemShowed -= 1
				If FirstItemShowed < 0 Then FirstItemShowed = 0
			Case EdRight
				FirstItemShowed += 1
				If FirstItemShowed > 100 Then FirstItemShowed = 100
			Case EdEnd
				FirstItemShowed = 100
			Case EdBottomBar
				FirstItemShowed = Int ((MouseX - 80) / 4.48)
				If FirstItemShowed < 0 Then FirstItemShowed = 0
				If FirstItemShowed > 100 Then FirstItemShowed = 100
			Case EdItem
				SelectedItem = FirstItemShowed + Int (MouseX / 34)
			Case EdNew
				Game.EdStatus = AnswerNew
			Case EdOpen
				Game.EdStatus = AnswerOpen
			Case EdMove
				Game.EdStatus = EdMoving
				EdMovingUndo = 0
			Case EdSave
				Game.EdStatus = AnswerSave
				UMTec = Str(Mine.Number)
			Case EdView
				EdShow = (Edshow + 1) Mod 4
			Case EdChangeGrid
				EdGrid = (EdGrid + 1) Mod 8
			Case EdClearArea
				EdXX1 = -1
				EdXX2 = -1
				EdYY1 = -1
				EdYY2 = -1
				EdX1 = -1
				EdY1 = -1
				Game.EdStatus = Clearing0
			Case EdTestMine
				Game.EdStatus = AnswerTest
			Case EdUndo
				DoUndo
			Case EdRedo
				DoRedo
			Case EdExit
				Game.EdStatus = AnswerExit
			End Select
		End If
		
	Case Selecting
		If MousePos = EdScreen Then
			EdX2 = Int (MouseX / 32)
			EdY2 = Int (MouseY / 32)
			SwapEDXY
			If (KBKey = "ESC") And (LastKBKey <> KBKey) Then
				Game.EdStatus = Editing
			Else
				If MouseReleased = 1 Then
					
					Game.EdStatus = Editing
					SaveUndo
					Mine.Changed = 1
					For F = EDXX1 To EDXX2
						For G = EDYY1 To EDYY2
							Select Case SelectedItem
							Case 1 To 25
								BkGround (MAPX + F, MAPY + G) = SelectedItem - 1
							Case 26 To 37
								FrGround (MAPX + F, MAPY + G) = SelectedItem - 26
							Case 38 To 114
								Object (MAPX + F, MAPY + G).TP = SelectedItem - 38
							Case Else
								Object (MAPX + F, MAPY + G).TP = SelectedItem - 33
							End Select
						Next
					Next
				
				End If
			End If
		End If
		
	Case AnswerNew
		If AskToClose () = 1 Then
			SaveUndo
			For f = -1 To 100
				For g = -1 To 60
					Object (f, g).TP = 0
					BkGround  (f, g) = 1
					FrGround (f, g) = 0
				Next
			Next
			VPlayer.x = 0
			VPlayer.y = 0
		End If
		Game.EdStatus = Editing		
		
	Case AnswerOpen
		If AskToClose () = 1 Then
			Option1 = 0
			VPlayer.CurrentMine = 0
			Cls
			SwapScreens
			Cls
			ShowMSG 7, 8, TXT(92), TXT(93), " "
			SearchCustomMines
			SwapScreens
			Cls
			ChangeStatus Configs
		Else
			Game.EdStatus = Editing
		End If
		
	Case EdMoving
		If LastKBKey <> KBKey Then
			Select Case KBKey
			Case "U"
				If EdMovingUndo = 0 Then SaveUndo : EdMovingUndo = 1
				Mine.Changed = 1
				For f = 0 To 99
					For g = 0 To 59
						Object (f, g) = Object (f, g + 1)
						BkGround  (f, g) = BkGround  (f, g + 1)
						FrGround (f, g) = FrGround (f, g + 1)
					Next
				Next
				If VPlayer.y > 0 Then VPlayer.y -= 1
				Object (VPlayer.x, VPlayer.y).tp = 0
			Case "D"
				If EdMovingUndo = 0 Then SaveUndo : EdMovingUndo = 1
				Mine.Changed = 1
				For f = 0 To 99
					For g = 59 To 0 Step -1
						Object (f, g) = Object (f, g - 1)
						BkGround  (f, g) = BkGround  (f, g - 1)
						FrGround (f, g) = FrGround (f, g - 1)
					Next
				Next
				If VPlayer.y < 59 Then VPlayer.y += 1
				Object (VPlayer.x, VPlayer.y).tp = 0
			Case "R"
				If EdMovingUndo = 0 Then SaveUndo : EdMovingUndo = 1
				Mine.Changed = 1
				For f = 99 To 0 Step -1
					For g = 0 To 59
						Object (f, g) = Object (f - 1, g)
						BkGround(f, g)  = BkGround  (f - 1, g)
						FrGround (f, g) = FrGround (f - 1, g)
					Next
				Next
				If VPlayer.x < 99 Then VPlayer.x += 1
				Object (VPlayer.x, VPlayer.y).tp = 0
			Case "L"
				If EdMovingUndo = 0 Then SaveUndo : EdMovingUndo = 1
				Mine.Changed = 1
				For f = 0 To 99
					For g = 0 To 59
						Object (f, g) = Object (f + 1, g)
						BkGround  (f, g) = BkGround  (f + 1, g)
						FrGround (f, g) = FrGround (f + 1, g)
					Next
				Next
				If VPlayer.x > 0 Then VPlayer.x -= 1
				Object (VPlayer.x, VPlayer.y).tp = 0
			Case "[", "]", "ESC"
				Game.EdStatus = Editing
				EdMovingUndo = 0
			End Select
		End If
		
	Case AnswerSave
		SaveMine
		Game.EdStatus = Editing
		
	Case Clearing0
		If MousePos = EdScreen Then
			EdX1 = Int (MouseX / 32)
			EdY1 = Int (MouseY / 32)
		End If
		If KBKey = "ESC" And LastKBKey <> KBKey Then
			Game.EdStatus = Editing
		End If
		If MouseClicked = 1 Then
			If MousePos = EdScreen Then
				EdMon = 1
				EdX2 = EDX1
				EdY2 = EDY1
				EdXX1 = EDX1
				EdXX2 = EDX2
				EdYY1 = EDY1
				EdYY2 = EDY2
				Game.EdStatus = Clearing1
			End If
		End If
		
	Case Clearing1
		If MousePos = EdScreen Then
			EdX2 = Int (MouseX / 32)
			EdY2 = Int (MouseY / 32)
			SwapEDXY
			If (KBKey = "ESC") And (LastKBKey <> KBKey) Then
				Game.EdStatus = Editing
			Else
				If MouseReleased = 1 Then
					Game.EdStatus = Editing
					SaveUndo
					Mine.Changed = 1
					For F = EDXX1 To EDXX2
						For G = EDYY1 To EDYY2
							BkGround (MAPX + F, MAPY + G) = 1
							FrGround (MAPX + F, MAPY + G) = 0
							Object (MAPX + F, MAPY + G).TP = 0
						Next
					Next
				End If
			End If
		End If
		
	Case AnswerTest
		Option1 = 0
		LMTec = ""
		If CountGems () = 0 Then
			Cls
			SwapScreens
			Cls
			ShowMSG 5, 8, TXT(100), "", ""
			Game.EdStatus = Editing
			SwapScreens
			Cls
			While Inkey = ""
				Sleep 1, 1
			Wend
			EmptyKeyboard
		Else
			While lmtec <> " " And LMTec <> Chr(13) And lmtec <> Chr(27)
				Cls
				ShowMSG 4, 5, TXT (108), "", "", 400, 300, Option1
				LMTec=Inkey
				ReadMouse
				If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
				If (MouseClicked = 1) And (MouseYesNo > 0) Then LMTec = " "
				If (LmTec = c255+ "H") Or (LmTec = c255+ "K") Or (LmTec = c255+ "M") Or (LmTec = c255+ "P") Then Option1 = 1 - Option1
				SwapScreens
				Game.seqCycle=(Game.seqCycle+1) Mod 360
			Wend
			Cls
			If Option1 = 1 Or LMTec = Chr(27) Then
				Game.EdStatus = Editing
			Else
				SaveMine -1
				ReadCustomMine -1, 0
				ResetLife
				ChangeStatus Testing
			End If
			
			EmptyKeyboard 1
			
		End If
		
	Case AnswerExit
		Option1 = 1
		LMTec = ""
		While lmtec <> " " And LMTec <> Chr(13) And lmtec <> Chr(27)
			Cls
			If Mine.Changed = 1 Then
				ShowMSG 4, 5, TXT (98), TXT (105), "", 400, 300, Option1
			Else
				ShowMSG 4, 5, TXT (105), "", "", 400, 300, Option1
			End If
			LMTec=Inkey
			ReadMouse
			If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
			If (MouseClicked = 1) And (MouseYesNo > 0) Then LMTec = " "
			If (LmTec = c255+ "H") Or (LmTec = c255+ "K") Or (LmTec = c255+ "M") Or (LmTec = c255+ "P") Then Option1 = 1 - Option1
			SwapScreens
			Game.seqCycle=(Game.seqCycle+1) Mod 360
		Wend
		Cls
		If Option1 = 1 Or LMTec = Chr(27) Then
			Game.EdStatus = Editing
		Else
			ChangeStatus MenuScreen
		End If
		
		EmptyKeyboard 1
		
	End Select 
	
	Object (VPlayer.x, VPlayer.y).Tp = 0
		
End Sub

'-------------------------------------------------------------------------------------------

Sub FinishTest
	ReadCustomMine -1, 1
	ChangeStatus Editor
	Kill "Minas\TESTE.MAP"
End Sub

'-------------------------------------------------------------------------------------------

'Draw an item (for editor tool bar)

Sub DrawItem (ITX As Integer, ITY As Integer, ITN As Integer)
	If ITN = 0 Then	'VPlayer (ITN = 0)
		Put (ITX, ITY), BMP (116), Trans
	ElseIf ITN = 1 Then	'BkGround 0 = água (ITN = 1)
		Put (ITX, ITY), BMP (213), PSet
	ElseIf ITN = 2 Then 'BkGround 1 = empty
		Line (ITX, ITY) - Step (31, 31), &HFFFFFF, B
		WriteTXT "no", ITX + 7, ITY - 1
		WriteTXT "BG", ITX + 7, ITY + 13
		Line (ITX, ITY + 31) - Step (31, -31), &HFFFFFF
	ElseIf ITN  < 26 Then	'BkGrounds 1 a 24 (ITN = 2 a 25)
		Put (ITX, ITY), BMP (ITN - 1), PSet
	ElseIf ITN = 26 Then	'foreground 0 = empty
		Line (ITX, ITY) - Step (31, 31), &HFFFFFF, B
		WriteTXT "no", ITX + 7, ITY - 1
		WriteTXT "FG", ITX + 7, ITY + 13
		Line (ITX, ITY + 31) - Step (31, -31), &HFFFFFF
	ElseIf ITN < 38 Then	'Frentes 0 a 10
		Put (ITX, ITY), BMP (ITN - 2), Trans
	ElseIf ITN = 38 Then	'Object 0 = empty
		Line (ITX, ITY) - Step (31, 31), &HFFFFFF, B
		WriteTXT "no", ITX + 3, ITY - 1
		WriteTXT "Obj", ITX + 7, ITY + 13
		Line (ITX, ITY + 31) - Step (31, - 31), &HFFFFFF
	ElseIf ITN < 115 Then
		Put (ITX, ITY), BMP (TpObject(ITN - 38).img), Trans
	ElseIf ITN < 123 Then
		Put (ITX, ITY), BMP (TpObject(ITN - 33).img), Trans
	Else 
		WriteTXT "?", ITX + 10, ITY + 7
	End If
End Sub

'-------------------------------------------------------------------------------------------

'What mouse is over

Function MousePosEd () As Integer
	Dim VarAnswer As Integer
	If MouseY >= 544 Then
		If MouseX < 611 Then
			If MouseY > 564 Then
				VarAnswer = EdItem
			Else
				If MouseX < 23 Then
					VarAnswer = EdBegin
				ElseIf MouseX < 46 Then
					VarAnswer = EdLeft
				ElseIf MouseX < 565 Then
					VarAnswer = EdBottomBar
				ElseIf MouseX < 588 Then
					VarAnswer = EdRight
				Else
					VarAnswer = EdEnd
				End If
			End If
		ElseIf MouseX > 612 Then
			If MouseX < 640 Then
				If MouseY < 572 Then
					VarAnswer = EdNew
				Else
					VarAnswer = EdMove
				End If
			ElseIf MouseX < 667 Then
				If MouseY < 572 Then
					VarAnswer = EdOpen
				Else
					VarAnswer = EdSave
				End If
			ElseIf MouseX < 719 Then
				VarAnswer = EdView
			ElseIf MouseX < 746 Then
				If MouseY < 572 Then
					VarAnswer = EdChangeGrid
				Else
					VarAnswer = EdUndo
				End If
			ElseIf MouseX < 773 Then
				If MouseY < 572 Then
					VarAnswer = EdClearArea
				Else
					VarAnswer = EdRedo
				End If
			Else
				If MouseY < 572 Then
					VarAnswer = EdTestMine
				Else
					VarAnswer = EdExit
				End If
			End If
		End If
	ElseIf MouseY > 0 And MouseX >0 And MouseX <= 799 Then
		VarAnswer = EdScreen
	Else
		VarAnswer = EdOutOfScreen
	End If
	Return VarAnswer
End Function

'-------------------------------------------------------------------------------------------

'Clear mine information used by editor

Sub ClearMineEditor
	Dim as integer F, G, H
	For H = 0 To MaxUndo
		For f = -1 To 100
			For g = -1 To 60
				UndoFrGround (h, f, g) = 0
				UndoBkGround  (h, f, g) = 1
				UndoObject (h, f, g) = 0
			Next
		Next
		VPlayerX (h) = 0
		VPlayerY (h) = 0
	Next

	Mine.Changed = 0
	LMTec = ""
	UMTec = ""
	FirstItemShowed = 0
	SelectedItem = 0
	EdShow = 2
	EdGrid = 0
	CurMatrix = 0
	LimitForRedo = 0
	LimitForUndo = 0
	EdMovingUndo = 0
	Mine.Time = 0
	Mine.Number = 0
	Mine.DarkType = 0
End Sub

'-------------------------------------------------------------------------------------------

'Ask before closing the mine

Function AskToClose () As Integer
	Dim OpTXT As Integer
	If Game.EdStatus = AnswerNew Then
		OpTXT = 99
	ElseIf Game.EdStatus = AnswerOpen Then
		OpTXT = 113
	End If
	Option1 = 1
	LMTec = ""
	While lmtec <> " " And LMTec <> Chr(13) And lmtec <> Chr(27)
		Cls
		If Mine.Changed = 1 Then
			ShowMSG 4, 5, TXT (98), TXT (OpTXT), "", 400, 300, Option1
		Else
			ShowMSG 4, 5, TXT (OpTXT), "", "", 400, 300, Option1
		End If
		LMTec=Inkey
		ReadMouse
		If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
		If (MouseClicked = 1) And (MouseYesNo > 0) Then LMTec = " "
		If (LmTec = c255+ "H") Or (LmTec = c255+ "K") Or (LmTec = c255+ "M") Or (LmTec = c255+ "P") Then Option1 = 1 - Option1
		SwapScreens
		Game.seqCycle=(Game.seqCycle+1) Mod 360
	Wend
	Cls
	EmptyKeyboard 1
		
	If Option1 = 1 Or LMTec = Chr(27) Then
		Return 0
	Else
		Return 1
	End If
		
End Function

'-------------------------------------------------------------------------------------------

'Orders coords

Sub SwapEDXY
	If EDX2 > EDX1 Then
		EDXX1 = EDX1
		EDXX2 = EDX2
	Else
		EDXX1 = EDX2
		EDXX2 = EDX1
	End If
	If EDY2 > EDY1 Then
		EDYY1 = EDY1
		EDYY2 = EDY2
	Else
		EDYY1 = EDY2
		EDYY2 = EDY1
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Save data for undo

Sub SaveUndo
	Dim as integer F, G
	
	For f = -1 To 100
		For g = -1 To 60
			UndoFrGround (CurMatrix, f, g) = FrGround (f, g)
			UndoBkGround  (CurMatrix, f, g) = BkGround  (f, g)
			UndoObject (CurMatrix, f, g) = Object (F, g).tp			
		Next
	Next
	
	VPlayerX (CurMatrix) = VPlayer.X
	VPlayerY (CurMatrix) = VPlayer.Y
	
	If CurMatrix = MaxUndo Then
		CurMatrix = 0
	Else
		CurMatrix += 1
	End If
	LimitForRedo = CurMatrix
	
	If CurMatrix = LimitForUndo Then
		If LimitForUndo = MaxUndo then
			LimitForUndo = 0
		Else
			LimitForUndo += 1
		End If
	End If

End Sub


'-------------------------------------------------------------------------------------------

'Do a undo

Sub DoUndo
	Dim as integer F, G
	If CurMatrix = LimitForRedo Then
		For f = -1 To 100
			For g = -1 To 60
				UndoFrGround (CurMatrix, f, g) = FrGround (f, g)
				UndoBkGround  (CurMatrix, f, g) = BkGround  (f, g)
				UndoObject (CurMatrix, f, g) = Object (F, g).tp			
			Next
		Next
		VPlayerX (CurMatrix) = VPlayer.X
		VPlayerY (CurMatrix) = VPlayer.Y
	End If

	If CurMatrix <> LimitForUndo Then
		If CurMatrix = 0 then
			CurMatrix = MaxUndo
		Else
			CurMatrix -= 1
		End If
		For f = -1 To 100
			For g = -1 To 60
				FrGround (f, g)    = UndoFrGround (CurMatrix, f, g)
				BkGround  (f, g)    = UndoBkGround  (CurMatrix, f, g)
				Object (F, g).tp = UndoObject (CurMatrix, f, g)
			Next
		Next
		VPlayer.X = VPlayerX (CurMatrix)
		VPlayer.Y = VPlayerY (CurMatrix)
	End If
End Sub

'-------------------------------------------------------------------------------------------

'Do a redo

Sub DoRedo
	Dim as integer F, G
	If CurMatrix <> LimitForRedo Then
		If CurMatrix = MaxUndo then
			CurMatrix = 0
		Else
			CurMatrix += 1
		End If
		For f = -1 To 100
			For g = -1 To 60
				FrGround (f, g)    = UndoFrGround (CurMatrix, f, g)
				BkGround  (f, g)    = UndoBkGround  (CurMatrix, f, g)
				Object (F, g).tp = UndoObject (CurMatrix, f, g)
			Next
		Next
		VPlayer.X = VPlayerX (CurMatrix)
		VPlayer.Y = VPlayerY (CurMatrix)
	End If
End Sub

'-------------------------------------------------------------------------------------------

Sub EmptyKeyboard (IncLMTec As Integer = 0)
	Dim as integer EsperaMais, f
	
	If IncLMTec <> 0 Then
		If LMTec = " " Then
			LastKBKey = "]"
			KBKey = "]"
		ElseIf LMTec = Chr(13) Then
			LastKBKey = "["
			KBKey = "["
		ElseIf LMTec = Chr(27) Then
			LastKBKey = "ESC"
			KBKey = "ESC"
		End If
	End If
	
	EsperaMais = 1 
	While EsperaMais = 1 
		EsperaMais = 0
		For F = 0 To 127
			If MultiKey (f) Then EsperaMais = 1
		Next
		Sleep 1, 1
	Wend
	
	While Inkey <> ""
		Sleep 1, 1
	Wend
End Sub

'-------------------------------------------------------------------------------------------

'get mouse stats

Sub ReadMouse
	MouseXOld = MouseX
	MouseYOld = MouseY
	MouseBOld = MouseB
	'MouseW, MouseWOld, MouseWDir
	MouseWOld = MouseW
	GetMouse (MouseX, MouseY, MouseW, MouseB)	
	MouseB = MouseB And 1
	If MouseB = 1 And MouseBOld = 0 Then MouseClicked = 1 Else MouseClicked = 0
	If MouseB = 0 And MouseBOld = 1 Then MouseReleased = 1 Else MouseReleased = 0
	If (MouseXOld <> MouseX) Or (MouseYOld <> MouseY) Then MouseMoved = 1 Else MouseMoved = 0
	MouseWDir = Sgn (MouseW - MouseWOld)
End Sub

'-------------------------------------------------------------------------------------------

'Change status

Sub ChangeStatus (NewStatus As Integer)
	Game.OldStatus = Game.Status
	Select Case NewStatus
	Case MenuScreen
		EmptyKeyboard
		TTDemo1 = Timer
	Case GameOver
		GameOverRandomSound
		XM =0
	Case Instruc
		'nothing to do
	Case Top10
		ReadRecordTable
	Case Editor
		Game.EdStatus = Editing
		EdShow = 2
		EdMOn=0
		EdGrid=0
	Case Configs
		'nothing to do
	Case Playing
		'nothing to do
	Case DemoMode
		'nothing to do
	Case Testing
		'nothing to do
	Case Paused
		'nothing to do
	Case MapMode
		'nothing to do
	Case WonMine
		Option1 = 0
	Case WonGame
		'nothing to do
	Case SelectLanguage
		'nothing to do
	End Select
	Game.Status = NewStatus
End Sub

'-------------------------------------------------------------------------------------------

'Sounds off

Sub AllSoundOff
	Dim as integer F, G
	For f = 1 To 6
		For g = 1 To 4
			midiOutShortMsg(hMidiOut, VSound (f, g).COff)
		Next
	Next
	For f = 1 To 7
		midiOutShortMsg(hMidiOut, VSoundEx (f).COff)
	Next
End Sub

'-------------------------------------------------------------------------------------------

'Ask before finishing test

Function AskToFinishTest() as Integer
	ShowMSG 0, 5, TXT (95), "", "", 400, 300, Option1
	If (KBKey <> LastKBKey) And (KBKey = "R" or KBKey = "U" Or KBKey = "D" Or KBKey = "L") Then
		Option1 = 1 - Option1
	End If
	If ((MouseMoved = 1) Or (MouseClicked = 1)) And (MouseYesNo > 0) Then Option1 = MouseYesNo - 1
	If (Option1 = 1 and ((MouseClicked = 1) or ((KBKey <> LastKBKey) And (KBKey = "[" Or KBKey = "]")))) Or (KBKey = "ESC" and LastKBKey <> KBKey) then
		ChangeStatus Testing
		ReadCustomMine -1, 0
		Started = 0
		ResetLife	
		Return 1
	Elseif Option1 = 0 Then
		If (MouseClicked = 1) or ((KBKey <> LastKBKey) and (KBKey = "[" or KBKey = "]")) Then
			FinishTest
			Return 2
		End If
	Else
		Return 0
	End If
End Function
