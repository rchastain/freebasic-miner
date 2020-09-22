
sub InitSound
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
end sub

sub LoadSounds
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
end sub

sub FreeSound
#ifdef __FB_WIN32__
  if hMidiOut <> 0 then midiOutClose hMidiOut
#else
#endif
end sub

sub Silencia
  dim as integer f, g
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
end sub

sub Sound01(OpMenu as integer, NewOpMenu as integer)
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, &H7f4080 + (OpMenu * 256))
  midiOutShortMsg (hMidiOut, &H76c0)
  midiOutShortMsg (hMidiOut, &H7f4090 + (NewOpMenu * 256))
#else
#endif
end sub

sub Sound02
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(6).COn1)
  midiOutShortMsg (hMidiOut, SomEx(6).COn2)
#else
#endif
end sub

sub Sound03
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(7).COff)
#else
#endif
end sub

sub Sound04
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, Som(6, 1).COn1)
  midiOutShortMsg (hMidiOut, Som(6, 1).COn2)
#else
#endif
  Som (6,1).Tempo = 1
end sub

sub Sound05
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(7).COn1)
  midiOutShortMsg (hMidiOut, SomEx(7).COn2)
#else
#endif
end sub

sub Sound06
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(6).COn1)
  midiOutShortMsg (hMidiOut, SomEx(6).COn2)
#else
#endif
  SomEx (6).Tempo = 10
end sub

sub Sound07(ASom as integer)
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, Som(5, ASom).COn1)
  midiOutShortMsg (hMidiOut, Som(5, ASom).COn2)
#else
#endif
  Som(5, ASom).Tempo = 16
end sub

sub Sound08
  dim as integer f, g
  for f = 1 to 6 'Rotina para gerar o som
    for g = 1 to 4
      if toca(f, g) = 1 then
#ifdef __FB_WIN32__
        midiOutShortMsg(hMidiOut, Som (f, g).COn1)
        midiOutShortMsg(hMidiOut, Som (f, g).COn2)
#else
#endif
        Som (f, g).Tempo = 8
      end if
    next
  next
end sub

sub Sound09
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, &H6f0087 Or UltNotaGameOver)
#else
#endif
end sub

sub Sound10
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, &H6f0080 Or UltNotaGameOver)
  midiOutShortMsg (hMidiOut, &H5f0080 Or (UltNotaGameOver + 513))
#else
#endif
end sub

sub Sound11
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(4).COn1)
  midiOutShortMsg (hMidiOut, SomEx(4).COn2)
#else
#endif
  SomEx (4).Tempo = 10
end sub

sub Sound12
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(5).COn1)
  midiOutShortMsg (hMidiOut, SomEx(5).COn2)
#else
#endif
  SomEx (5).Tempo = 10
end sub

sub Sound13(XTam1 as integer)
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, SomEx(XTam1).COn1)
  midiOutShortMsg (hMidiOut, SomEx(XTam1).COn2)
#else
#endif
  SomEx (XTam1).Tempo = 16
end sub

sub Sound14(Nota as integer)
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, &H65c7)
  midiOutShortMsg (hMidiOut, &H600087 Or UltNotaGameOver)
  midiOutShortMsg (hMidiOut, &H600097 Or Nota)
#else
#endif
  UltNotaGameOver = Nota
end sub

sub Sound15(Nota as integer)
#ifdef __FB_WIN32__
  midiOutShortMsg (hMidiOut, &H76c0)  '26, 29, 2d, 6b
  midiOutShortMsg (hMidiOut, &H6bc1)  '26, 29, 2d, 6b
  midiOutShortMsg (hMidiOut, &H5f0080 Or (UltNotaGameOver + 513))
  midiOutShortMsg (hMidiOut, &H6f0080 Or UltNotaGameOver)
  midiOutShortMsg (hMidiOut, &H600090 Or (Nota + 513))
  midiOutShortMsg (hMidiOut, &H6f0090 Or Nota)
#else
#endif
  UltNotaGameOver = Nota
end sub

'Desativa os sons ligados

sub DesligaSons
  dim as integer F, G
  for f = 1 to 6
    for g = 1 to 4
#ifdef __FB_WIN32__
      midiOutShortMsg(hMidiOut, Som (f, g).COff)
#else
#endif
    next
  next
  for f = 1 to 7
#ifdef __FB_WIN32__
    midiOutShortMsg(hMidiOut, SomEx (f).COff)
#else
#endif
  next
end sub
