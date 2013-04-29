program BlackWhiteChess;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {FormMain},
  UnitCommon in 'UnitCommon.pas',
  UnitTBlackWhiteGame in 'UnitTBlackWhiteGame.pas',
  UnitTBoardGame in 'UnitTBoardGame.pas',
  UnitTStateTree in 'UnitTStateTree.pas',
  UnitTStateNode in 'UnitTStateNode.pas',
  UnitFormData in 'UnitFormData.pas' {FormStateTreeData},
  UnitTBlackWhiteGameStateTree in 'UnitTBlackWhiteGameStateTree.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormStateTreeData, FormStateTreeData);
  Application.Run;
end.
