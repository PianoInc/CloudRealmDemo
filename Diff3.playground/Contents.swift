//: Playground - noun: a place where people can play

import UIKit
import Foundation

enum DiffStatus: CustomStringConvertible {
    case stable(String)
    case conflict(String,String,String)
    
    var description: String {
        switch self {
        case .stable(let s): return "stable: \(s)"
        case .conflict(let an, let a, let b): return "conflicted \no: \(an)\na: \(a)\nb: \(b)"
        }
    }
    
    var isConflict: Bool {
        switch self {
        case .stable: return false
        case .conflict: return true
        }
    }
}

class ReferenceArray<T>: CustomStringConvertible {
    var description: String {
        return array.description
    }
    
    var count: Int {
        return array.count
    }
    
    private var array:[T] = []
    
    
    func append(_ newElement: T) {
        array.append(newElement)
    }
    
    subscript(_ index: Int) -> T {
        get {
            return array[index]
        } set {
            array[index] = newValue
        }
    }
    
}

extension ReferenceArray where T == Int {
    func getFirstElement(largerThan value: Int) -> Int? {
        guard let index = array.index(where: { (element) -> Bool in
            return element >= value
        }) else {return nil}
        
        return array[index]
    }
}


extension Array where Element == String {
    func combineChunks() -> String {
        return String(self.reduce("") { (resultString, element) -> String in
            resultString+element+"\n"
        }.dropLast())
    }
}

extension Array where Element == DiffStatus {
    func getResolvedString() -> String {
        return self.reduce("") { (resultString, diffStatus) -> String in
            var diffString = ""
            switch diffStatus {
            case .stable(let stableString): diffString = stableString
            case .conflict(let ancestor, let myString, let serverString):
                if ancestor == myString {
                    diffString = serverString
                } else if ancestor == serverString || myString == serverString {
                    diffString = myString
                } else {
                    //serious conflict!
                    diffString = """
                    Serious Conflict!!!
                    
                    my
                    ---------------------
                    \(myString)
                    ---------------------
                    server
                    \(serverString)
                    ---------------------
                    """
                }
            }
            return resultString + diffString + "\n"
        }
    }
}



class Diff3 {
    
    static func makeItUP(ancestor: String, a: String, b: String) -> String {
        var Lo = 0
        var La = 0
        var Lb = 0
        var commonLength = 0
        var oWordIndices: [String: ReferenceArray<Int>] = [:]
        var aWordIndices: [String: ReferenceArray<Int>] = [:]
        var bWordIndices: [String: ReferenceArray<Int>] = [:]
        
        //chunk it up & make indice lists
        
        let oChunks = ancestor.components(separatedBy: "\n")
        let aChunks = a.components(separatedBy: "\n")
        let bChunks = b.components(separatedBy: "\n")
        var finalChunks:[DiffStatus] = []
        
        for (index, string) in oChunks.enumerated() {
            let array = oWordIndices[string] ?? ReferenceArray<Int>()
            
            if oWordIndices[string] == nil { oWordIndices[string] = array }
            
            array.append(index)
        }
        
        
        for (index, string) in aChunks.enumerated() {
            let array = aWordIndices[string] ?? ReferenceArray<Int>()
            
            if aWordIndices[string] == nil { aWordIndices[string] = array }
            
            array.append(index)
        }
        
        for (index, string) in bChunks.enumerated() {
            let array = bWordIndices[string] ?? ReferenceArray<Int>()
            
            if bWordIndices[string] == nil { bWordIndices[string] = array }
            
            array.append(index)
        }
        
        while(Lo+commonLength<oChunks.count && La+commonLength<aChunks.count
                && Lb+commonLength<bChunks.count) {
            // whole loop -> add finite conditions!
            
            //first step - find longest stable chunk
            if oChunks[Lo+commonLength] == aChunks[La+commonLength] &&
                oChunks[Lo+commonLength] == bChunks[Lb+commonLength] && !oChunks[Lo+commonLength].isEmpty {
                commonLength += 1
                continue
            }
            
            
            //second step
            if commonLength == 0 {
                // conflict occured!
                
                var oOffset = 0
                var trueOffset = 0
                var a: Int? = nil
                var b: Int? = nil
                var minB = Int.max
                var trueA: Int? = nil
                var trueB: Int? = nil
                
                while(Lo+oOffset<oChunks.count && oOffset < minB) {
                    let currentOWord = oChunks[Lo+oOffset]
                    
                    if let aWordIndex = aWordIndices[currentOWord], let bWordIndex = bWordIndices[currentOWord] {
                        
                        a = aWordIndex.getFirstElement(largerThan: La)
                        b = bWordIndex.getFirstElement(largerThan: Lb)
                        
                        if a == nil || b == nil || currentOWord.isEmpty {
                            oOffset += 1
                            continue
                        }
                        
                        
                        let tempMinB = (a!-La) + (b!-Lb) + oOffset
                        
                        //count and compare minB
                        if (tempMinB < minB) {
                            trueOffset = oOffset
                            trueA = a
                            trueB = b
                            minB = tempMinB
                        }
                    }
                    
                    oOffset += 1
                }

                
                guard let a1 = trueA, let b1 = trueB else {break}
                let o = Lo+trueOffset
                
                let originalChunk = oChunks[Lo..<o].joined(separator: "\n")
                let aChunk = aChunks[La..<a1].joined(separator: "\n")
                let bChunk = bChunks[Lb..<b1].joined(separator: "\n")
                
                Lo = o
                La = a1
                Lb = b1
                
                finalChunks.append(.conflict(originalChunk, aChunk, bChunk))
                //first match o with a&b, then pop them
                //l+offset -> o-1, l+offset -> a-1, l+offset -> b-1 conflict!!!
                //l = o, a, b
                //if no o then break
            } else {
                // common block add
                //l -> l+offset common block
                //l = l+offset+1
                
                let commonChunks = oChunks[Lo..<Lo+commonLength]
                
                Lo += commonLength
                La += commonLength
                Lb += commonLength
                
                finalChunks.append(.stable(commonChunks.joined(separator: "\n")))
                commonLength = 0
            }
        }
        
        //third step
        //add final chunks
        
        if commonLength > 0 {
            let commonChunks = oChunks[Lo..<Lo+commonLength]
            
            Lo += commonLength
            La += commonLength
            Lb += commonLength
            
            finalChunks.append(.stable(commonChunks.joined(separator: "\n")))
        }
        
        let originalChunk = oChunks[Lo..<oChunks.count].joined(separator: "\n")
        let aChunk = aChunks[La..<aChunks.count].joined(separator: "\n")
        let bChunk = bChunks[Lb..<bChunks.count].joined(separator: "\n")
        
        finalChunks.append(.conflict(originalChunk, aChunk, bChunk))
//        finalChunks.forEach{
//            print($0)
//        }
        
//        print("********************************************")
        return finalChunks.getResolvedString()
    }
}

let origin = """
//////////////////////////////////////////////////////////////////////////
// File: Bug_ReporterApp.h
//
// Description:
//   Contains main entry point to the executable.
//
// Header File:
//   NA
//
// Copyright:
//   Copyright � 1996-2010 WysiCorp, Inc.
//   All contents of this file are considered WysiCorp Software proprietary.
//////////////////////////////////////////////////////////////////////////

Option Strict On

Public Class frmMain
Inherits System.Windows.Forms.Form

Public Event SaveWhileClosingCancelled As System.EventHandler
Public Event ExitApplication As System.EventHandler

Private m_Dirty As Boolean = False
Private m_ClosingComplete As Boolean = False
Private m_DocumentName As String
Private m_FileName As String

#Region " Windows Form Designer generated code "

Public Sub New()
MyBase.New()

InitializeComponent()

Dim ainfo As New AssemblyInfo()

Me.mnuAbout.Text = String.Format("&About {0} ...", ainfo.Title)

End Sub

Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
If disposing Then
If Not (components Is Nothing) Then
components.Dispose()
End If
End If
MyBase.Dispose(disposing)
End Sub

Private components As System.ComponentModel.IContainer

Friend WithEvents mnuMain As System.Windows.Forms.MainMenu
Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
<System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
Dim resources As System.Resources.ResourceManager = New System.Resources.ResourceManager(GetType(frmMain))
Me.mnuMain = New System.Windows.Forms.MainMenu()
Me.MenuItem1 = New System.Windows.Forms.MenuItem()
Me.SuspendLayout()
'
'mnuMain
'
Me.mnuMain.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.mnuFile, Me.mnuHelp})
'
'mnuFile
'
Me.mnuFile.Index = 0
Me.mnuFile.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.mnuNew, Me.mnuClose, Me.MenuItem1, Me.mnuSave, Me.MenuItem2, Me.mnuExit})
Me.mnuFile.Text = "&File"
'
'mnuExit
'
Me.mnuExit.Index = 5
Me.mnuExit.Text = "E&xit"

End Sub

#End Region
"""

let a = """
//////////////////////////////////////////////////////////////////////////
// File: Bug_ReporterApp.h
//
// Description:
//   Contains main entry point to the executable.
//
// Header File:
//   NA
//
// Copyright:
//   Copyright � 1996-2010 WysiCorp, Inc.
//   All contents of this file are considered WysiCorp Software proprietary.
//////////////////////////////////////////////////////////////////////////

Option Strict On

Public Class frmMain
Inherits System.Windows.Forms.Form

Public Event SaveWhileClosingCancelled As System.EventHandler
Public Event ExitApplication As System.EventHandler
Public StatusMsg

Private m_Dirty As Boolean = False
Private m_ClosingComplete As Boolean = False
Private m_DocumentName As String
Private m_FileName As String
Private m_TempFileName As String
Private m_DirName As String
Private m_ErrorMessage As String

#Region " Windows Form Designer generated code "

Public Sub New()
MyBase.New()

InitializeComponent()

Dim ainfo As New AssemblyInfo()

Me.mnuAbout.Text = String.Format("&About {0} ...", ainfo.Title)

End Sub

Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
If disposing Then
If Not (components Is Nothing) Then
components.Dispose()
End If
End If
MyBase.Dispose(disposing)
End Sub

Private components As System.ComponentModel.IContainer

Friend WithEvents mnuMain As System.Windows.Forms.MainMenu
Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
<System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
Dim resources As System.Resources.ResourceManager = New System.Resources.ResourceManager(GetType(frmMain))
Me.mnuMain = New System.Windows.Forms.MainMenu()
Me.MenuItem1 = New System.Windows.Forms.MenuItem()
Me.SuspendLayout()
'
'mnuMain
'
Me.mnuMain.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.mnuFile, Me.mnuHelp})
'
'mnuFile
'
Me.mnuFile.Index = 0
Me.mnuFile.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.mnuNew, Me.mnuClose, Me.MenuItem1, Me.mnuSave, Me.MenuItem2, Me.mnuExit})
Me.mnuFile.Text = "&File"
'
mnuHelp
'
Me.mnuExit.Index = 4
Me.mnuExit.Text = "H&elp"
'
'mnuExit
'
Me.mnuExit.Index = 5
Me.mnuExit.Text = "E&xit"



End Sub

#End Region
"""

let b = """
//////////////////////////////////////////////////////////////////////////
// File: Bug_ReporterApp.h
//
// Description:
//   Contains main entry point to the executable.
//
// Header File:
//   NA
//
// Copyright:
//   Copyright � 1996-2010 WysiCorp, Inc.
//   All contents of this file are considered WysiCorp Software proprietary.
//////////////////////////////////////////////////////////////////////////

Option Strict On

Public Class frmMain
Inherits System.Windows.Forms.Form

Public Event SaveWhileClosingCancelled As System.EventHandler
Public Event ExitApplication As System.EventHandler
Public StatusMsg

Private m_Dirty As Boolean = False
Private m_ClosingComplete As Boolean = False
Private m_DocumentName As String
Private m_FileName As String
Private m_TempFileName As String
Private m_DirName As String

#Region " Windows Form Designer generated code "

Public Sub New()
MyBase.New()

InitializeComponent()

Dim ainfo As New AssemblyInfo()

Me.mnuAbout.Text = String.Format("&About {0} ...", ainfo.Title)

End Sub

Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
If disposing Then
If Not (components Is Nothing) Then
components.Dispose()
End If
End If
MyBase.Dispose(disposing)
End Sub

Private components As System.ComponentModel.IContainer

Friend WithEvents mnuMain As System.Windows.Forms.MainMenu
Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
<System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
Dim resources As System.Resources.ResourceManager = New System.Resources.ResourceManager(GetType(frmMain))
Me.mnuMain = New System.Windows.Forms.MainMenu()
Me.MenuItem1 = New System.Windows.Forms.MenuItem()
Me.SuspendLayout()
'
'mnuMain
'
Me.mnuMain.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.mnuFile, Me.mnuHelp})
'
'mnuFile
'
Me.mnuFile.Index = 0
Me.mnuFile.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.mnuNew, Me.mnuClose, Me.MenuItem1, Me.mnuSave, Me.MenuItem2, Me.mnuExit})
Me.mnuFile.Text = "&File"
'
'mnuExit
'
Me.mnuExit.Index = 5
Me.mnuExit.Text = "E&xit"

End Sub

#End Region
"""

//Diff3.makeItUP(ancestor: origin, a: a, b: b)
print(Diff3.makeItUP(ancestor: origin, a: a, b: b))

