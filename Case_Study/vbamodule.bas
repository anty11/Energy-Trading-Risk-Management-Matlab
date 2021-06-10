Attribute VB_Name = "Module1"
Option Base 1
Option Explicit

Sub RunBacktest()
    On Error GoTo eh
    
Dim backtestResults
Dim assets
Dim startDate
Dim endDate
Dim mainSheet As Worksheet
Set mainSheet = ThisWorkbook.Sheets(1)

'Read ranges from worhsheet
assets = mainSheet.Range("assets")
startDate = mainSheet.Range("startDate")
endDate = mainSheet.Range("endDate")

'Call MATLAB deployed function
backtestResults = backtestPlantPortfolio(assets, startDate, endDate)

'Insert results into worksheet
mainSheet.Range("plantStats").Value = backtestResults
mainSheet.Range("portProfit").Value = "=sum(H14:H22)"

'Insert figure
InsertFigure

Exit Sub
eh:
    Debug.Print Err.Description
    Resume Next
End Sub

Sub RunSimulation()
    On Error GoTo eh
    
Dim assetResults
Dim portResults
Dim simResultArray
Dim assets
Dim startDate As Double
Dim endDate As Double
Dim NSim
Dim mainSheet As Worksheet
Set mainSheet = ThisWorkbook.Sheets(1)

'Read ranges from worhsheet
assets = mainSheet.Range("assets")
startDate = mainSheet.Range("startDate")
endDate = mainSheet.Range("endDate")
NSim = mainSheet.Range("NSim")

'Call MATLAB deployed function
simResultArray = simulatePlantPortfolio(assets, startDate, endDate, NSim)

'Extract plant risks and portfolio risks
assetResults = simResultArray(0)
portResults = simResultArray(1)

'Insert results into worksheet
mainSheet.Range("plantRiskStats").Value = assetResults
mainSheet.Range("portProfitRisk").Value = portResults

'Insert figure
InsertFigure

Exit Sub
eh:
    Debug.Print Err.Description
    Resume Next
End Sub

Sub InsertFigure()
Dim idx As Integer
Dim mainSheet As Worksheet
Set mainSheet = ThisWorkbook.Sheets(1)

'Clean out existing figures
If mainSheet.Shapes.Count > 3 Then
    mainSheet.Shapes(1).Delete
End If

'Paste new figure
Range("g1").Select
mainSheet.Paste

'Resize figure to fill its allotted space, regardless of the screen resolution
For idx = 1 To mainSheet.Shapes.Count
    If Left(mainSheet.Shapes(idx).OLEFormat.Object.Name, 6) = "Pictur" Then
            mainSheet.Shapes(idx).Height = mainSheet.Range("G1:G11").Height
        Exit For
    End If
Next idx

End Sub

Sub ClearCells()
Dim mainSheet As Worksheet
Dim idx
Set mainSheet = ThisWorkbook.Sheets(1)
    Range("F5:F7").Value = ""
    Range("F14:K22").Value = ""
    If mainSheet.Shapes.Count > 3 Then
        mainSheet.Shapes(1).Delete
    End If
End Sub
