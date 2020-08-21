unit UnitTBlackWhiteGameStateTree;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ExtCtrls, ToolWin, StdCtrls, UnitCommon, UnitTBoardGame, UnitTStateNode, UnitTStateTree, Generics.Collections;

type
  TBlackWhiteGameStateTree = class(TStateTree)
  protected
    procedure PrintNode(node: TStateNode; var list: TStringList); override;
    procedure PrintNodeToTreeView(node: TStateNode; var treeNode: TTreeNode; var treeList: TTreeNodes); override;
  end;

implementation

uses
  UnitTBlackWhiteGame;

{ TBlackWhiteGameStateTree }

procedure TBlackWhiteGameStateTree.PrintNode(node: TStateNode;
  var list: TStringList);
var
  s, turn: String;
  lvl: Integer;
  i: Integer;
  game: TBlackWhiteGame;
  lastMove: TPoint;
  numBlack, numBlank, numWhite, res: Integer;
begin
  inherited;
  if node <> nil then
  begin
    s := '|';
    lvl := getLevel(node);
    game := TBlackWhiteGame(node.data);
    numBlack := game.GetPiecesNumber(PIECE_BLACK);
    numWhite := game.GetPiecesNumber(PIECE_WHITE);
    numBlank := game.GetPiecesNumber(PIECE_BLANK);
    res := numBlack - numWhite;
    lastMove := game.LastMove;
    for i := 0 to lvl - 1 do
    begin
      s := s + '-----|';
    end;
    if game.LastTurn = BLACK then
    begin
      turn := 'BLACK';
    end
    else
    begin
      turn := 'WHITE';
      res := res * -1;
    end;
    list.Add(s + Format(' [%x] %s Played at (%d, %d) -> (White: %d, Black: %d, Blank: %d) - (Result: %d)',
          [Integer(node), turn, lastMove.X + 1, lastMove.Y + 1, numWhite, numBlack, numBlank, res]));
  end;
end;

procedure TBlackWhiteGameStateTree.PrintNodeToTreeView(node: TStateNode;
  var treeNode: TTreeNode; var treeList: TTreeNodes);
var
  s, t: String;
  game: TBlackWhiteGame;
  lastMove: TPoint;
  numBlack, numBlank, numWhite, res: Integer;
begin
  inherited;
  if node <> nil then
  begin
    game := TBlackWhiteGame(node.data);
    numBlack := game.GetPiecesNumber(PIECE_BLACK);
    numWhite := game.GetPiecesNumber(PIECE_WHITE);
    numBlank := game.GetPiecesNumber(PIECE_BLANK);
    res := numBlack - numWhite;
    lastMove := game.LastMove;
    if game.LastTurn = BLACK then
    begin
      t := 'BLACK';
    end
    else
    begin
      t := 'WHITE';
      res := res * -1;
    end;
    s := s + Format(' [%x] %s Played at (%d, %d) -> (White: %d, Black: %d, Blank: %d) - (Result: %d)',
          [Integer(node), t, lastMove.X + 1, lastMove.Y + 1, numWhite, numBlack, numBlank, res]);

    treeNode := treeList.Add(treeNode, s);
  end;
end;

end.
