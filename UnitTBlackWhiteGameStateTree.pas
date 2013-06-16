unit UnitTBlackWhiteGameStateTree;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ExtCtrls, ToolWin, StdCtrls, UnitCommon, UnitTBoardGame, UnitTStateNode, UnitTStateTree, Generics.Collections;

type
  TBlackWhiteGameStateTree = class(TStateTree)
  protected
    procedure PrintNode(node: TStateNode; var list: TStringList); override;
    procedure PrintNodeToTreeView(node: TStateNode; var treeNode: TTreeNode); override;
  end;

implementation

uses
  UnitTBlackWhiteGame;

{ TBlackWhiteGameStateTree }

procedure TBlackWhiteGameStateTree.PrintNode(node: TStateNode;
  var list: TStringList);
var
  tmpString, tmpStringTurn: String;
  tmpLevel: Integer;
  i: Integer;
  tmpGame: TBlackWhiteGame;
  tmpLastMove: TPoint;
  tmpNumberOfBlack, tmpNumberOfBlank, tmpNumberOfWhite, tmpResult: Integer;
begin
  inherited;
  if node <> nil then
  begin
    tmpString := '|';
    tmpLevel := getLevel(node);
    tmpGame := TBlackWhiteGame(node.data);
    tmpNumberOfBlack := tmpGame.GetPiecesNumber(PIECE_BLACK);
    tmpNumberOfWhite := tmpGame.GetPiecesNumber(PIECE_WHITE);
    tmpNumberOfBlank := tmpGame.GetPiecesNumber(PIECE_BLANK);
    tmpResult := tmpNumberOfBlack - tmpNumberOfWhite;
    tmpLastMove := tmpGame.LastMove;
    for i := 0 to tmpLevel - 1 do
    begin
      tmpString := tmpString + '-----|';
    end;
    if tmpGame.LastTurn = BLACK then
    begin
      tmpStringTurn := 'BLACK';
    end
    else
    begin
      tmpStringTurn := 'WHITE';
      tmpResult := tmpResult * -1;
    end;
    list.Add(tmpString + Format(' [%x] %s Played at (%d, %d) -> (White: %d, Black: %d, Blank: %d) - (Result: %d)',
          [Integer(node), tmpStringTurn, tmpLastMove.X + 1, tmpLastMove.Y + 1, tmpNumberOfWhite, tmpNumberOfBlack, tmpNumberOfBlank, tmpResult]));
  end;
end;

procedure TBlackWhiteGameStateTree.PrintNodeToTreeView(node: TStateNode;
  var treeNode: TTreeNode);
var
  tmpString, tmpStringTurn: String;
  tmpLevel: Integer;
  i: Integer;
  tmpGame: TBlackWhiteGame;
  tmpLastMove: TPoint;
  tmpNumberOfBlack, tmpNumberOfBlank, tmpNumberOfWhite, tmpResult: Integer;
begin
  inherited;
  if node <> nil then
  begin
//    tmpString := '|';
    tmpLevel := getLevel(node);
    tmpGame := TBlackWhiteGame(node.data);
    tmpNumberOfBlack := tmpGame.GetPiecesNumber(PIECE_BLACK);
    tmpNumberOfWhite := tmpGame.GetPiecesNumber(PIECE_WHITE);
    tmpNumberOfBlank := tmpGame.GetPiecesNumber(PIECE_BLANK);
    tmpResult := tmpNumberOfBlack - tmpNumberOfWhite;
    tmpLastMove := tmpGame.LastMove;
//    for i := 0 to tmpLevel - 1 do
//    begin
//      tmpString := tmpString + '-----|';
//    end;
    if tmpGame.LastTurn = BLACK then
    begin
      tmpStringTurn := 'BLACK';
    end
    else
    begin
      tmpStringTurn := 'WHITE';
      tmpResult := tmpResult * -1;
    end;
    tmpString := tmpString + Format(' [%x] %s Played at (%d, %d) -> (White: %d, Black: %d, Blank: %d) - (Result: %d)',
          [Integer(node), tmpStringTurn, tmpLastMove.X + 1, tmpLastMove.Y + 1, tmpNumberOfWhite, tmpNumberOfBlack, tmpNumberOfBlank, tmpResult]);

    treeNode := Self.TreeView.Items.Add(treeNode, tmpString);
  end;
end;

end.
