object FormMain: TFormMain
  Left = 264
  Top = 163
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'BlackWhiteChess - Ricol'
  ClientHeight = 410
  ClientWidth = 391
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020100000000000E80200001600000028000000200000004000
    0000010004000000000080020000000000000000000000000000000000000000
    0000000080000080000000808000800000008000800080800000C0C0C0008080
    80000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF002222
    000000002222222FFFFFFFFF222222000000000000222FFFFFFFFFFFF2222200
    0000000000222FFFFFFFFFFFFF222000000000000002FFFFFFFFFFFFFFF20000
    000000000000FFFFFFFFFFFFFFF20000000000000000FFFFFFFFFFFFFFFF0000
    000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000
    000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFF22000
    000000000002FFFFFFFFFFFFFFF222000000000000222FFFFFFFFFFFFF222200
    0000000000222FFFFFFFFFFFF2222222000000002222222FFFFFFFFF22222222
    F000000FF22222000FFFFF000222222FFFFFFFFFFF22200000000000002222FF
    FFFFFFFFFFF2200000000000002222FFFFFFFFFFFFF200000000000000022FFF
    FFFFFFFFFFFF00000000000000022FFFFFFFFFFFFFF00000000000000000FFFF
    FFFFFFFFFFF00000000000000000FFFFFFFFFFFFFFF00000000000000000FFFF
    FFFFFFFFFFF00000000000000000FFFFFFFFFFFFFFF00000000000000000FFFF
    FFFFFFFFFFF000000000000000002FFFFFFFFFFFFFFF00000000000000022FFF
    FFFFFFFFFFFF000000000000000222FFFFFFFFFFFFF2200000000000002222FF
    FFFFFFFFFFF22000000000000022222FFFFFFFFFFF2222000000000002222222
    FFFFFFFFF2222220000000002222222222FFFFF2222222222000002222220000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    0000000000000000000000000000000000000000000000000000000000000000
    000000000000000000000000000000000000000000000000000000000000}
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object PaintBoxMain: TPaintBox
    Left = 0
    Top = 0
    Width = 391
    Height = 391
    Align = alClient
    OnMouseUp = PaintBoxMainMouseUp
    OnPaint = PaintBoxMainPaint
    ExplicitWidth = 400
    ExplicitHeight = 400
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 391
    Width = 391
    Height = 19
    Panels = <
      item
        Text = 'Computer:'
        Width = 250
      end
      item
        Text = 'Status:'
        Width = 50
      end>
  end
  object ProgressBar1: TProgressBar
    Left = 136
    Top = 328
    Width = 150
    Height = 17
    TabOrder = 1
  end
  object MainMenu1: TMainMenu
    Left = 16
    Top = 24
    object MenuGame: TMenuItem
      Caption = 'Game'
      object MenuGame_NewGame: TMenuItem
        Caption = 'Start Game'
        OnClick = MenuGame_NewGameClick
      end
      object MenuGame_CloseGame: TMenuItem
        Caption = 'End Game'
        Enabled = False
        OnClick = MenuGame_CloseGameClick
      end
      object MenuGame_Seperator1: TMenuItem
        Caption = '-'
      end
      object MenuGame_SaveGame: TMenuItem
        Caption = 'Save Game'
      end
      object MenuGame_LoadGame: TMenuItem
        Caption = 'Load Game'
      end
      object MenuGame_Seperator2: TMenuItem
        Caption = '-'
      end
      object MenuGame_Exit: TMenuItem
        Caption = 'Exit'
        OnClick = MenuGame_ExitClick
      end
    end
    object MenuConfig: TMenuItem
      Caption = 'Config'
      object MenuConfig_Swap: TMenuItem
        Caption = 'SwapTurn'
      end
      object MenuConfig_Difficulties: TMenuItem
        Caption = 'Difficulties'
      end
      object MenuConfig_Color: TMenuItem
        Caption = 'Color'
      end
      object MenuConfig_Music: TMenuItem
        Caption = 'Music'
      end
      object MenuConfig_SoundEffect: TMenuItem
        Caption = 'Sound'
      end
    end
    object MenuNetwork: TMenuItem
      Caption = 'Network'
      object MenuNetwork_NewServer: TMenuItem
        Caption = 'New Server'
      end
      object MenuNetwork_ConnectTo: TMenuItem
        Caption = 'Connect to...'
      end
      object MenuNetwork_Seperator1: TMenuItem
        Caption = '-'
      end
      object MenuNetwork_StartGame: TMenuItem
        Caption = 'Start Game'
      end
      object MenuNetwork_CloseGame: TMenuItem
        Caption = 'End Game'
      end
      object MenuNetwork_Seperator2: TMenuItem
        Caption = '-'
      end
      object MenuNetwork_SendMessage: TMenuItem
        Caption = 'Send Message'
      end
      object MenuNetwork_Seperator3: TMenuItem
        Caption = '-'
      end
      object MenuNetwork_AboutNetwork: TMenuItem
        Caption = 'About'
      end
    end
    object MenuHelp: TMenuItem
      Caption = 'Help'
      object MenuHelp_About: TMenuItem
        Caption = 'About'
        OnClick = MenuHelp_AboutClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object ComputerCalculateLevel1: TMenuItem
        Caption = 'Computer Calculate Level'
        object MenuComputerLevelLow: TMenuItem
          AutoCheck = True
          Caption = 'Low'
          RadioItem = True
          OnClick = ComputerCalculateLevelClick
        end
        object MenuComputerLevelMedium: TMenuItem
          AutoCheck = True
          Caption = 'Medium'
          Checked = True
          RadioItem = True
          OnClick = ComputerCalculateLevelClick
        end
        object MenuComputerLevelHigh: TMenuItem
          AutoCheck = True
          Caption = 'High'
          RadioItem = True
          OnClick = ComputerCalculateLevelClick
        end
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object AutoplayByLoop: TMenuItem
        Caption = 'Autoplay-Loop'
        OnClick = AutoplayByLoopClick
      end
      object AutoplayByRecursive: TMenuItem
        Caption = 'Autoplay-Recursive'
        OnClick = AutoplayByRecursiveClick
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object MenuHelpStateTreeInfor: TMenuItem
        Caption = 'State Tree Infor'
        OnClick = MenuHelpStateTreeInforClick
      end
    end
  end
end
