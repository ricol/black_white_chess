program BlackWhiteChess;

uses
  Forms,
  fMain in 'fMain.pas' {FormMain},
  Common in 'Common.pas',
  BlackWhiteGame in 'BlackWhiteGame.pas',
  BoardGame in 'BoardGame.pas',
  StateTree in 'StateTree.pas',
  StateNode in 'StateNode.pas',
  fData in 'fData.pas' {FormStateTreeData},
  BlackWhiteGameStateTree in 'BlackWhiteGameStateTree.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.CreateForm(TFormStateTreeData, FormStateTreeData);
  Application.Run;
end.
