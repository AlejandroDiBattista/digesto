Attribute VB_Name = "Formato"
Const Raiz = "/Users/alejandro/Dropbox/limpiar/copia_fiel/"
Const NombreFuente = "Book Antiqua"
'Const NombreFuente = "Segoe UI"

Sub Fecha()
    FormatoParrafo 0, 9, wdAlignParagraphRight
    FormatoFuente
End Sub

Sub Ordenanza()
    FormatoParrafo 24, 9, wdAlignParagraphLeft
    FormatoFuente , True
End Sub

Sub FormatoSeccion()
    FormatoParrafo 12, 3, wdAlignParagraphLeft
    FormatoFuente , True
End Sub

Sub Sanciona()
    FormatoParrafo 12, 12, wdAlignParagraphCenter
    FormatoFuente , True
End Sub

Sub FormatoPiePagina()
  FormatoFuente 10, False, False, False
  Selection.Font.Color = -603946753
End Sub

Sub Normal()
    FormatoFuente
    FormatoParrafo 0, 9, wdAlignParagraphJustify
End Sub

Sub Articulo()
    FormatoFuente , , , True
End Sub

Sub Anexo()
    FormatoFuente 14, True, False, False
    FormatoParrafo 0, 18, wdAlignParagraphCenter
End Sub

Private Sub FormatoFuente(Optional ByVal tamanio As Integer, Optional ByVal negrita As Boolean, Optional ByVal italica As Boolean, Optional ByVal subrayado As Boolean)
    With Selection.Font
        .Name = NombreFuente
        .Size = IIf(tamanio = 0, 12, tamanio)
        .Bold = negrita
        .Italic = italica
        .Underline = IIf(subrayado, wdUnderlineSingle, wdUnderlineNone)
    End With
End Sub

Private Sub FormatoParrafo(Optional ByVal antes As Integer, Optional ByVal despues As Integer, Optional ByVal alineacion As Integer)
    Dim centrado As Boolean
    alineacion = IIf(alineacion = 0, wdAlignParagraphLeft, alineacion)
    centrada = (alineacion = wdAlignParagraphCenter)
    With Selection.ParagraphFormat
        .LeftIndent = CentimetersToPoints(IIf(centrada, 3.25, 0))
        .RightIndent = CentimetersToPoints(IIf(centrada, 3.25, 0))
        .SpaceBefore = antes
        .SpaceAfter = despues
        .Alignment = alineacion
        
        .SpaceBeforeAuto = False
        .SpaceAfterAuto = False
        .LineSpacingRule = wdLineSpaceSingle
        .WidowControl = True
        .KeepWithNext = True
        .KeepTogether = False
        .PageBreakBefore = False
        .NoLineNumber = False
        .Hyphenation = True
        .FirstLineIndent = CentimetersToPoints(0)
        .OutlineLevel = wdOutlineLevelBodyText
        .CharacterUnitLeftIndent = 0
        .CharacterUnitRightIndent = 0
        .CharacterUnitFirstLineIndent = 0
        .LineUnitBefore = 0
        .LineUnitAfter = 0
        .MirrorIndents = False
        .TextboxTightWrap = wdTightNone
    End With
End Sub

Public Sub Margenes()
    With Selection.PageSetup
        .LineNumbering.Active = False
        .Orientation = wdOrientPortrait
        .TopMargin = CentimetersToPoints(2.5)
        .BottomMargin = CentimetersToPoints(2)
        .LeftMargin = CentimetersToPoints(3)
        .RightMargin = CentimetersToPoints(2)
        .Gutter = CentimetersToPoints(0)
        .HeaderDistance = CentimetersToPoints(1.25)
        .FooterDistance = CentimetersToPoints(1.25)
        .PageWidth = CentimetersToPoints(21)
        .PageHeight = CentimetersToPoints(29.7)
        .FirstPageTray = wdPrinterDefaultBin
        .OtherPagesTray = wdPrinterDefaultBin
        .SectionStart = wdSectionNewPage
        .OddAndEvenPagesHeaderFooter = False
        .DifferentFirstPageHeaderFooter = False
        .VerticalAlignment = wdAlignVerticalTop
        .SuppressEndnotes = False
        .MirrorMargins = False
        .TwoPagesOnOne = False
        .BookFoldPrinting = False
        .BookFoldRevPrinting = False
        .BookFoldPrintingSheets = 1
        .GutterPos = wdGutterPosLeft
    End With
End Sub

Sub MetrosCuadrados()
  Selection.HomeKey Unit:=wdStory
  With Selection.Find
    .ClearFormatting
    .Text = "[0-9]mts2"
    .Forward = True
    .Wrap = wdFindStop
    .Format = True
    .MatchCase = False
    .MatchWholeWord = False
    .MatchAllWordForms = False
    .MatchSoundsLike = False
    .MatchWildcards = True
  End With
  
  With Selection
    While .Find.Execute
      .MoveRight Unit:=wdCharacter, Count:=1
      .MoveLeft Unit:=wdCharacter, Count:=1, Extend:=wdExtend
      .Font.Superscript = True
      .MoveRight Unit:=wdCharacter, Count:=1
    Wend
  End With
End Sub

'-[Modulo 1]---------------------------------------------------------

Private Sub BorrarFormato()
    Selection.WholeStory
    Selection.ClearFormatting
    Selection.Font.Size = 10
    Selection.Font.Name = "Times New Roman"
    Selection.MoveDown Unit:=wdLine, Count:=1
    Selection.MoveUp Unit:=wdLine, Count:=1
    ActiveDocument.Save
End Sub

Private Function Buscar(ByVal Texto As String) As Boolean
    With Selection.Find
        .ClearFormatting
        .MatchWholeWord = False
        .MatchCase = False
        .Execute FindText:=Texto
        Buscar = .Found
        If .Found Then SeleccionarParrafo
    End With
End Function

Private Function Avanzar(ParamArray textos()) As Boolean
    Dim linea As String
    Avanzar = False
    linea = UCase(Selection.Text)
    For Each Texto In textos
        If linea Like "*" + UCase(Texto) + "*" Then
            IrProximoParrafo
            Avanzar = True
            Exit For
        End If
    Next
End Function

Private Function Borrar(ByVal lineas As Integer, Optional ByVal Texto As String) As String
    Debug.Print "  Borrar"; lineas; "lineas"
    ActiveDocument.Bookmarks(Index:="buscar").Select
    Selection.MoveDown Unit:=wdParagraph, Count:=lineas - 1, Extend:=wdExtend

    Borrar = Selection.Text
    Selection.Text = ""
End Function

Private Sub IrComienzo()
    Selection.GoTo What:=wdGoToPage, Which:=wdGoToFirst, Name:=""
    Selection.Find.ClearFormatting
End Sub

Private Sub IrProximoParrafo(Optional ByVal cantidad As Integer = 1)
    Selection.HomeKey Unit:=wdLine
    Selection.MoveDown Unit:=wdParagraph, Count:=cantidad
    SeleccionarParrafo
End Sub

Private Sub SeleccionarParrafo()
    Selection.HomeKey Unit:=wdLine
    Selection.MoveDown Unit:=wdParagraph, Count:=1, Extend:=wdExtend
End Sub

Public Function BorrarCopiaFiel() As Boolean
    Dim lineas As Integer
    BorrarCopiaFiel = False
    IrComienzo
    If Buscar("es copia fiel del original") Then
        ActiveDocument.Bookmarks.Add Name:="buscar", Range:=Selection.Range
        IrProximoParrafo
        lineas = 1
        If Avanzar("firmado") Then
            lineas = lineas + 1
            If Avanzar("secretaria", "director", "presidente") Then
                lineas = lineas + 1
                If Avanzar("buena") Then lineas = lineas + 1
                If Avanzar("secretaria", "secretaría", "presidencia") Then lineas = lineas + 1
                If Avanzar("cargo presidencia") Then lineas = lineas + 1
                While Avanzar("///")
                   lineas = lineas + 1
                Wend
                If Avanzar("ordenanza") Then lineas = lineas + 1

                Borrar lineas
                BorrarCopiaFiel = True
            End If
        End If
        If ActiveDocument.Bookmarks.Exists("buscar") Then ActiveDocument.Bookmarks(Index:="buscar").Delete
     Else
        Debug.Print "  No hay nada mas"
     End If
End Function

Private Sub Reemplazar(ByVal origen As String, ByVal destino As String)
    IrComienzo
    With Selection.Find
        .ClearFormatting
        .MatchWholeWord = False
        .MatchCase = False
        .Execute FindText:=origen, ReplaceWith:=destino, Replace:=wdReplaceAll
    End With
End Sub

Private Function LimpiarCopiaFiel() As Boolean
    LimpiarCopiaFiel = False
    Reemplazar "es copia fiel concejo", "El Concejo"
    Reemplazar "es copia fiel de original", "es copia fiel del original"
    Reemplazar "es copia fiel original", "es copia fiel del original"
    For i = 1 To 30
        If Not BorrarCopiaFiel() Then Exit For
        LimpiarCopiaFiel = True
    Next
End Function

Private Sub Limpiar(ByVal origen As String)
    Debug.Print "LIMPIANDO "; origen
    Set doc = Documents.Open(FileName:=Raiz + origen + ".docx")
    ActiveWindow.ActivePane.View.Zoom.Percentage = 100
    LimpiarCopiaFiel
    doc.Save
    doc.Close
End Sub

Private Sub Probar()
    Set lista = New Collection
    For Each origen In lista
        Limpiar origen
    Next
End Sub

Private Sub ParrafoNormal()
    With Selection.ParagraphFormat
        .LeftIndent = CentimetersToPoints(3.5)
        .SpaceBeforeAuto = False
        .SpaceAfterAuto = False
    End With
End Sub

Private Sub FormatoCentrado()
End Sub


