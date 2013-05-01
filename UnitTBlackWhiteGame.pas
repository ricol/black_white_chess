unit UnitTBlackWhiteGame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ExtCtrls, StdCtrls, ToolWin, UnitCommon, UnitTBoardGame, UnitTStateNode, UnitTStateTree;

type

  TBlackWhiteGame = class(TBoardGame)
  protected
    function Process(i, j, k1, k2: Integer; piece: TPiece): Integer;
    procedure Reverse(i, j, number, k1, k2: Integer);
    function GetResult(i, j: Integer; piece: TPiece): Integer;
    function GetPieceFromTurn(turn: TTurn): TPiece;
    procedure ReArrange(i, j: integer; piece: TPiece);
    function AnalyzeTheStateTree(stateTree: TStateTree; turn: TTurn): TPoint;
    procedure SetIsPlaying(const Value: Boolean); override;
    procedure DrawBoard();
    procedure DrawLastMove();
    function TimeToCheck(): Boolean;
    procedure DrawPiece(piece: TPiece; i, j: integer);
    procedure DrawAvailableMove();
    function GoToLevel(var x, y: Integer; piece: TPiece): boolean;
    function AnalyzeToLevel(level: Integer; var x, y: Integer; piece: TPiece): boolean;
    procedure NextLevel(const totalLevel: Integer; piece: TPiece; const step: TPoint; gameOld: TBlackWhiteGame; var stateTree: TStateTree; var currentNode: TStateNode);
  public
    constructor Create(PaintBox: TPaintBox; size: Integer; TempObject: Boolean); overload; override;
    constructor Create(blackWhiteGame: TBoardGame); overload; override;
    destructor Destroy(); override;
    function GetPiecesNumber(piece: TPiece): Integer;
    function IsAvailableMove(i, j: Integer; piece: TPiece): Boolean;
    procedure PlayAtMove(i, j: Integer; piece: TPiece);
    procedure CheckAndEndGame();
    function GetAllAvailableMove(var data: TListOfPoints; piece: TPiece): Integer;
    procedure DrawAllAvailableMoves(turn: TTurn);
    function AutoPlay(var i, j: Integer; piece: TPiece): Boolean;
    procedure BlinkLastMove();
    procedure About(); override;
    procedure NewGame(); override;
    procedure CloseGame(); override;
    procedure ResetGame; override;
    procedure SaveGame(); override;
    procedure LoadGame(); override;
    procedure Swap(); override;
    procedure Refresh(); override;
  end;


implementation

uses
  UnitTBlackWhiteGameStateTree;

var
  GStateTree: TStateTree;

{ TBlackWhiteGame }

procedure TBlackWhiteGame.About;
begin
  MessageBox(Application.Handle,
             'Game: BlackWhiteChess' + #$D + #$A +
             'Programmer: Ricol Wang' + #$D + #$A +
             'Date: 28/08/2012 - V1.0' + #$D + #$A +
             'Date: 01/05/2013 - V2.0', 'About', MB_OK);
end;

function TBlackWhiteGame.AnalyzeTheStateTree(
  stateTree: TStateTree; turn: TTurn): TPoint;
var
  tmpStateTree: TStateTree;
  tmpAllLeaves: TListOfNodes;
  tmpCurrentNode: TStateNode;
  tmpGameCurrent: TBlackWhiteGame;
  tmpMax, k, l, tmpNumberOfBlack, tmpNumberOfWhite, tmpResult: Integer;
  tmpPoint: TPoint;
begin
  //analyze the state tree and find the optimum node
  tmpStateTree := stateTree;
  tmpAllLeaves := tmpStateTree.getAllLeaves(True);

  tmpMax := 0;
  tmpResult := 0;
  l := 0;
  OutputDebugString(PChar(Format('Analyzing...Total Leaves: %d', [tmpAllLeaves.Count])));

  if turn = WHITE then
  begin
    for k := 0 to tmpAllLeaves.Count - 1 do
    begin
      tmpCurrentNode := tmpAllLeaves[k];
      tmpGameCurrent := TBlackWhiteGame(tmpCurrentNode.data);

      tmpNumberOfBlack := tmpGameCurrent.GetPiecesNumber(PIECE_BLACK);
      tmpNumberOfWhite := tmpGameCurrent.GetPiecesNumber(PIECE_WHITE);

      if tmpNumberOfBlack <= 0 then
      begin
        l := k;
        OutputDebugString(PChar(Format('#######: Found The Optimal Result! Level %d', [TStateTree.getLevel(tmpCurrentNode)])));
        Beep;
        break;
      end else
        tmpResult := tmpNumberOfWhite - tmpNumberOfBlack;

      if tmpResult > tmpMax then
      begin
        l := k;
        tmpMax := tmpResult;
      end;
    end;
  end else begin
    for k := 0 to tmpAllLeaves.Count - 1 do
    begin
      tmpCurrentNode := tmpAllLeaves[k];
      tmpGameCurrent := TBlackWhiteGame(tmpCurrentNode.data);

      tmpNumberOfBlack := tmpGameCurrent.GetPiecesNumber(PIECE_BLACK);
      tmpNumberOfWhite := tmpGameCurrent.GetPiecesNumber(PIECE_WHITE);

      if tmpNumberOfWhite <= 0 then
      begin
        l := k;
        OutputDebugString(PChar(Format('#######: Found The Optimal Result! Level %d', [TStateTree.getLevel(tmpCurrentNode)])));
        Beep;
        break;
      end else
        tmpResult := tmpNumberOfBlack - tmpNumberOfWhite;

      if tmpResult > tmpMax then
      begin
        l := k;
        tmpMax := tmpResult;
      end;
    end;
  end;

  tmpCurrentNode := tmpAllLeaves[l];
  tmpPoint.X := tmpCurrentNode.step_i;
  tmpPoint.Y := tmpCurrentNode.step_j;
  FreeAndNil(tmpAllLeaves);

  Result := tmpPoint;
end;

function TBlackWhiteGame.AnalyzeToLevel(level: Integer; var x, y: Integer; piece: TPiece): boolean;
var
  k: Integer;
  tmpNumber: Integer;
  tmpData: TListOfPoints;
  tmpGame: TBlackWhiteGame;

  tmpCurrentNode: TStateNode;
  tmpPoint: TPoint;
  tmpHead: TBoardGame;
begin
  //create the State Tree and save all possible chess state into the tree
  tmpHead := TBlackWhiteGame.Create(Self);
  GStateTree := TBlackWhiteGameStateTree.Create(tmpHead);
  GStateTree.ListBox := Self.ListBox;
  tmpCurrentNode := GStateTree.Head;

  //get all possible moves for piece.
  tmpNumber := GetAllAvailableMove(tmpData, piece);

  if tmpNumber > 0 then
  begin
    FProgressBar.Min := 0;
    FProgressBar.Max := tmpNumber - 1;
    FProgressBar.Position := 0;
    FProgressBar.Visible := True;
    for k := 0 to tmpNumber - 1 do
    begin
      FProgressBar.Position := k;
      Application.ProcessMessages;
      tmpGame := TBlackWhiteGame.Create(Self);
      tmpGame.IsTempGame := True;
      tmpPoint := tmpData[k];
      tmpGame.PlayAtMove(tmpPoint.x, tmpPoint.y, piece);
      tmpCurrentNode := GStateTree.InsertTheNode(tmpGame, tmpPoint.x, tmpPoint.y, tmpCurrentNode);

      self.NextLevel(level, piece, tmpPoint, tmpGame, GStateTree, tmpCurrentNode);

      tmpCurrentNode := tmpCurrentNode.parentNode;
    end;
    //return a optimal result by analyzing the state tree.
    tmpPoint := Self.AnalyzeTheStateTree(GStateTree, Self.Turn);
    x := tmpPoint.X;
    y := tmpPoint.Y;
    OutputDebugString(PChar(Format('Choose: %d, %d', [x + 1, y + 1])));
    Result := true;
    FreeAndNil(tmpData);
    GStateTree.Print;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
    exit;
  end else
  begin
    result := False;
    FreeAndNil(tmpData);
    GStateTree.Print;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
  end;
end;

procedure TBlackWhiteGame.NextLevel(const totalLevel: Integer; piece: TPiece; const step: TPoint; gameOld: TBlackWhiteGame; var stateTree: TStateTree; var currentNode: TStateNode);
var
  tmpNumberOld, tmpNumberNew: Integer;
  kOld, kNew: Integer;
  tmpGameOld, tmpGameNew: TBlackWhiteGame;
  tmpDataOld, tmpDataNew: TListOfPoints;

  tmpPoint: TPoint;
begin
  tmpGameOld := gameOld;
  //get all possible moves for the opponent of piece
  tmpNumberOld := tmpGameOld.GetAllAvailableMove(tmpDataOld, TBlackWhiteGame.GetOpponent(piece));
  if tmpNumberOld > 0 then
  begin
    for kOld := 0 to tmpNumberOld - 1 do
    begin
      tmpGameNew := TBlackWhiteGame.Create(tmpGameOld);
      tmpGameNew.IsTempGame := True;
      tmpPoint := tmpDataOld[kOld];
      tmpGameNew.PlayAtMove(tmpPoint.x, tmpPoint.y, TBlackWhiteGame.GetOpponent(piece));
      currentNode := GStateTree.InsertTheNode(tmpGameNew, tmpPoint.x, tmpPoint.y, currentNode);

      //get all possible moves for piece
      tmpNumberNew := tmpGameNew.GetAllAvailableMove(tmpDataNew, piece);
      if tmpNumberNew > 0 then
      begin
        for kNew := 0 to tmpNumberNew - 1 do
        begin
          tmpGameOld := TBlackWhiteGame.Create(tmpGameNew);
          tmpGameOld.IsTempGame := True;
          tmpPoint := tmpDataNew[kNew];
          tmpGameOld.PlayAtMove(tmpPoint.X, tmpPoint.Y, piece);
          tmpPoint := step;
          currentNode := GStateTree.InsertTheNode(tmpGameOld, tmpPoint.X, tmpPoint.Y, currentNode);
          if TStateTree.getLevel(currentNode) <= totalLevel then
            self.NextLevel(totalLevel, piece, step, tmpGameOld, stateTree, currentNode);
          currentNode := currentNode.parentNode;
        end;
      end;
      FreeAndNil(tmpDataNew);

      currentNode := currentNode.parentNode;
    end;
  end;
  FreeAndNil(tmpDataOld);
end;

//return a optimal position (i and j) for the current player which holds "piece"
//if there is no available move, then return "false", else return "true"
function TBlackWhiteGame.AutoPlay(var i: Integer; var j: Integer; piece: TPiece): Boolean;
begin
//  Result := self.AnalyzeToLevel(3, i, j, piece);
  Result := self.GoToLevel(i, j, piece);
end;

function TBlackWhiteGame.GoToLevel(var x, y: Integer;
  piece: TPiece): boolean;
var
  k, k1, k2, k3, k4, k5, k6: Integer;
  tmpNumber, tmpNumber1, tmpNumber2, tmpNumber3, tmpNumber4, tmpNumber5, tmpNumber6: Integer;
  tmpData, tmpData1, tmpData2, tmpData3, tmpData4, tmpData5, tmpData6: TListOfPoints;
  tmpGame, tmpGame1, tmpGame2, tmpGame3, tmpGame4, tmpGame5, tmpGame6: TBlackWhiteGame;

  tmpCurrentNode: TStateNode;
  tmpPoint: TPoint;
  tmpHead: TBoardGame;
begin
  //create the State Tree and save all possible chess state into the tree
  tmpHead := TBlackWhiteGame.Create(Self);
  GStateTree := TBlackWhiteGameStateTree.Create(tmpHead);
  GStateTree.ListBox := Self.ListBox;
  tmpCurrentNode := GStateTree.Head;

  //get all possible moves for piece.
  tmpNumber := GetAllAvailableMove(tmpData, piece);

  if tmpNumber > 0 then
  begin
    FProgressBar.Min := 0;
    FProgressBar.Max := tmpNumber - 1;
    FProgressBar.Position := 0;
    FProgressBar.Visible := True;
    for k := 0 to tmpNumber - 1 do
    begin
      FProgressBar.Position := k;
      Application.ProcessMessages;
      tmpGame := TBlackWhiteGame.Create(Self);
      tmpGame.IsTempGame := True;
      tmpPoint := tmpData[k];
      tmpGame.PlayAtMove(tmpPoint.x, tmpPoint.y, piece);
      tmpCurrentNode := GStateTree.InsertTheNode(tmpGame, tmpPoint.x, tmpPoint.y, tmpCurrentNode);

      //==========Level 1=============
      //get all possible moves for the opponent of piece.
      tmpNumber1 := tmpGame.GetAllAvailableMove(tmpData1, TBlackWhiteGame.GetOpponent(piece));
      if tmpNumber1 > 0 then
      begin
        for k1 := 0 to tmpNumber1 - 1 do
        begin
          tmpGame1 := TBlackWhiteGame.Create(tmpGame);
          tmpGame1.IsTempGame := True;
          tmpPoint := tmpData1[k1];
          tmpGame1.PlayAtMove(tmpPoint.x, tmpPoint.y, TBlackWhiteGame.GetOpponent(piece
          ));
          tmpPoint := tmpData[k];
          tmpCurrentNode := GStateTree.InsertTheNode(tmpGame1, tmpPoint.x, tmpPoint.y, tmpCurrentNode);

          //get all possible moves for the piece
          tmpNumber2 := tmpGame1.GetAllAvailableMove(tmpData2, piece);
          if tmpNumber2 > 0 then
          begin
            for k2 := 0 to tmpNumber2 - 1 do
            begin
              tmpGame2 := TBlackWhiteGame.Create(tmpGame1);
              tmpGame2.IsTempGame := True;
              tmpPoint := tmpData2[k2];
              tmpGame2.PlayAtMove(tmpPoint.X, tmpPoint.Y, piece);
              tmpPoint := tmpData[k];
              tmpCurrentNode := GStateTree.InsertTheNode(tmpGame2, tmpPoint.X, tmpPoint.Y, tmpCurrentNode);

              //==============Level 2===============

              //get all possible moves for the opponent of piece
              tmpNumber3 := tmpGame2.GetAllAvailableMove(tmpData3, TBlackWhiteGame.GetOpponent(piece
              ));
              if tmpNumber3 > 0 then
              begin
                for k3 := 0 to tmpNumber3 - 1 do
                begin
                  tmpGame3 := TBlackWhiteGame.Create(tmpGame2);
                  tmpGame3.IsTempGame := True;
                  tmpPoint := tmpData3[k3];
                  tmpGame3.PlayAtMove(tmpPoint.X, tmpPoint.Y, TBlackWhiteGame.GetOpponent(piece));
                  tmpPoint := tmpData[k];
                  tmpCurrentNode := GStateTree.InsertTheNode(tmpGame3, tmpPoint.X, tmpPoint.Y, tmpCurrentNode);

                  //get all possible moves for piece
                  tmpNumber4 := tmpGame3.GetAllAvailableMove(tmpData4, piece);
                  if tmpNumber4 > 0 then
                  begin
                    for k4 := 0 to tmpNumber4 - 1 do
                    begin
                      tmpGame4 := TBlackWhiteGame.Create(tmpGame3);
                      tmpGame4.IsTempGame := True;
                      tmpPoint := tmpData4[k4];
                      tmpGame4.PlayAtMove(tmpPoint.X, tmpPoint.Y, piece);
                      tmpPoint := tmpData[k];
                      tmpCurrentNode := GStateTree.InsertTheNode(tmpGame4, tmpPoint.X, tmpPoint.Y, tmpCurrentNode);
                      {
                      //================Level 3 begin================
                      //get all possible moves for the opponent of piece
                      tmpNumber5 := tmpGame4.GetAllAvailableMove(tmpData5, TBlackWhiteGame.GetOpponent(piece));
                      if tmpNumber5 > 0 then
                      begin
                        for k5 := 0 to tmpNumber5 - 1 do
                        begin
                          tmpGame5 := TBlackWhiteGame.Create(tmpGame4);
                          tmpGame5.IsTempGame := True;
                          tmpPoint := tmpData5[k5];
                          tmpGame5.PlayAtMove(tmpPoint.X, tmpPoint.Y, TBlackWhiteGame.GetOpponent(piece));
                          tmpPoint := tmpData[k];
                          tmpCurrentNode := GStateTree.InsertTheNode(tmpGame5, tmpPoint.X, tmpPoint.Y, tmpCurrentNode);

                          //get all possible moves for piece
                          tmpNumber6 := tmpGame5.GetAllAvailableMove(tmpData6, piece);
                          if tmpNumber6 > 0 then
                          begin
                            for k6 := 0 to tmpNumber6 - 1 do
                            begin
                              tmpGame6 := TBlackWhiteGame.Create(tmpGame5);
                              tmpGame6.IsTempGame := True;
                              tmpPoint := tmpData6[k6];
                              tmpGame6.PlayAtMove(tmpPoint.X, tmpPoint.Y, piece);
                              tmpPoint := tmpData[k];
                              tmpCurrentNode := GStateTree.InsertTheNode(tmpGame6, tmpPoint.X, tmpPoint.Y, tmpCurrentNode);
                              tmpCurrentNode := tmpCurrentNode.parentNode;
                            end;
                          end;
                          FreeAndNil(tmpData6);
                          tmpCurrentNode := tmpCurrentNode.parentNode;
                        end;
                      end;
                      FreeAndNil(tmpData5);
                      //==============Level 3 end============
                      }
                      tmpCurrentNode := tmpCurrentNode.parentNode;
                    end;
                  end;
                  FreeAndNil(tmpData4);
                  tmpCurrentNode := tmpCurrentNode.parentNode;
                end;
              end;
              FreeAndNil(tmpData3);
              //================Level 2 end================
              tmpCurrentNode := tmpCurrentNode.parentNode;
            end;
          end;
          FreeAndNil(tmpData2);
          tmpCurrentNode := tmpCurrentNode.parentNode;
        end;
      end;
      FreeAndNil(tmpData1);
      //==================Level 1 end=================
      tmpCurrentNode := tmpCurrentNode.parentNode;
    end;

    //return a optimal result by analyzing the state tree.
    tmpPoint := Self.AnalyzeTheStateTree(GStateTree, Self.Turn);
    x := tmpPoint.X;
    y := tmpPoint.Y;
    OutputDebugString(PChar(Format('Choose: %d, %d', [x + 1, y + 1])));
    Result := true;
    FreeAndNil(tmpData);
    GStateTree.Print;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
    exit;
  end else
  begin
    result := False;
    FreeAndNil(tmpData);
    GStateTree.Print;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
  end;
end;

//Check who wins the game and end the game
procedure TBlackWhiteGame.CheckAndEndGame;
var
  tmpWhiteNumber, tmpBlackNumber: Integer;
begin
  inherited;
  tmpWhiteNumber := GetPiecesNumber(PIECE_WHITE);
  tmpBlackNumber := GetPiecesNumber(PIECE_BLACK);
  if tmpWhiteNumber > tmpBlackNumber then
  begin
    MessageBox(Application.Handle,
               PChar('Congratulation, White Win!' + #$D + #$A +
               Format('White pieces: %d', [tmpWhiteNumber]) + #$D + #$A +
               Format('Black pieces: %d', [tmpBlackNumber])), 'Result', MB_OK);
  end else if tmpWhiteNumber = tmpBlackNumber then
  begin
    MessageBox(Application.Handle,
               PChar('This is a draw' + #$D + #$A +
               Format('White pieces: %d', [tmpWhiteNumber]) + #$D + #$A +
               Format('Black pieces: %d', [tmpBlackNumber])), 'Result', MB_OK);
  end else begin
    MessageBox(Application.Handle,
               PChar('Congratulation, Black Win!' + #$D + #$A +
               Format('Black pieces: %d', [tmpBlackNumber]) + #$D + #$A +
               Format('White pieces: %d', [tmpWhiteNumber])), 'Result', MB_OK)
  end;
  IsPlaying := False;
  DrawLastMove();
  DrawAllAvailableMoves(Turn);
end;

//close the current game
procedure TBlackWhiteGame.CloseGame;
begin
  inherited;
  IsPlaying := False;
  Self.Refresh;
end;

//copy constructor
//return a object whose properties and values are identical to the "blackWhiteGmae"
constructor TBlackWhiteGame.Create(blackWhiteGame: TBoardGame);
var
  tmpBlackWhiteGame: TBlackWhiteGame;
begin
  inherited Create(blackWhiteGame);
  tmpBlackWhiteGame := TBlackWhiteGame(blackWhiteGame);
  FGridColor := tmpBlackWhiteGame.FGridColor;
  FBlackColor := tmpBlackWhiteGame.FBlackColor;
  FWhiteColor := tmpBlackWhiteGame.FWhiteColor;
  FTurn := tmpBlackWhiteGame.FTurn;
  FLastMove := tmpBlackWhiteGame.FLastMove;
  FOldLastMove := tmpBlackWhiteGame.FOldLastMove;
  FOldAvailableMoveNumber := tmpBlackWhiteGame.FOldAvailableMoveNumber;
  if not FIsTempGame then
  begin
    FOldAvailableMoveData := TListOfPoints.Create(tmpBlackWhiteGame.FOldAvailableMoveData);
    FAvailableMoveData := TListOfPoints.Create(tmpBlackWhiteGame.FAvailableMoveData);
  end;
  FProgressBar := tmpBlackWhiteGame.FProgressBar;
  FListBox := tmpBlackWhiteGame.FListBox;
end;

//constructor
constructor TBlackWhiteGame.Create(PaintBox: TPaintBox; size: Integer; TempObject: Boolean);
var
  i, j: integer;
begin
  inherited Create(PaintBox, size, TempObject);
  for i := 0 to size - 1 do
    for j := 0 to size - 1 do
      FBoard[i, j] := PIECE_BLANK;
  Self.FWhiteColor := COLOR_WHITE;
  Self.FGridColor := COLOR_GRID;
  Self.FBlackColor := COLOR_BLACK;
  Self.FTurn := WHITE;
  Self.FOldAvailableMoveNumber := 0;
  Self.FAvailableMoveNumber := 0;
end;

//destructor
destructor TBlackWhiteGame.Destroy;
begin
  FreeAndNil(FOldAvailableMoveData);
  FreeAndNil(FAvailableMoveData);
  inherited;
end;

//draw the chess board
procedure TBlackWhiteGame.DrawBoard;
var
  tmpX, tmpY, i: Integer;
begin
  inherited;
  if Self.IsTempGame then Exit;

  tmpX := FPaintBox.Width;
  tmpY := FPaintBox.Height;
  with FPaintBox do
  begin
    Canvas.Brush.Color := FBackgroundColor;
    Canvas.Pen.Color := FGridColor;
    Canvas.Pen.Width := 1;
    Canvas.Rectangle(0, 0, tmpX, tmpY);
    for i := 0 to Self.FSize - 1 do
    begin
      Canvas.MoveTo(0, FLenY * i);
      Canvas.LineTo(tmpX, FLenY * i);
      Canvas.MoveTo(FLenX * i, 0);
      Canvas.LineTo(FLenX * i, tmpY);
    end;
  end;
end;

//draw the last move and highlight the move
procedure TBlackWhiteGame.DrawLastMove;
var
  tmpX, tmpY, tmpStartX, tmpStartY, tmpStartLenX, tmpStartLenY: Integer;
begin
  if Self.IsTempGame then Exit;
  DrawPiece(GetPiece(FOldLastMove.x, FOldLastMove.y), FOldLastMove.x, FOldLastMove.y);
  if not IsPlaying then exit;
  tmpX := JToX(FLastMove.y);
  tmpY := IToY(FLastMove.x);
  tmpStartX := 3;
  tmpStartY := 3;
  tmpStartLenX := 5;
  tmpStartLenY := 5;
  with FPaintBox do
  begin
    Canvas.Pen.Color := clRed;
    Canvas.Pen.Width := 3;
    Canvas.MoveTo(tmpX + tmpStartX, tmpY + tmpStartY);
    Canvas.LineTo(tmpX + tmpStartX, tmpY + tmpStartY + tmpStartLenY);
    Canvas.MoveTo(tmpX + tmpStartX, tmpY + tmpStartY);
    Canvas.LineTo(tmpX + tmpStartX + tmpStartLenX, tmpY + tmpStartY);
    Canvas.MoveTo(tmpX + tmpStartX, tmpY + FLenY - tmpStartY);
    Canvas.LineTo(tmpX + tmpStartX, tmpY + FLenY - tmpStartY - tmpStartLenY);
    Canvas.MoveTo(tmpX + tmpStartX, tmpY + FLenY - tmpStartY);
    Canvas.LineTo(tmpX + tmpStartX + tmpStartLenX, tmpY + FLenY - tmpStartY);
    Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + tmpStartY);
    Canvas.LineTo(tmpX + FLenX - tmpStartX - tmpStartLenX, tmpY + tmpStartY);
    Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + tmpStartY);
    Canvas.LineTo(tmpX + FLenX - tmpStartX, tmpY + tmpStartY + tmpStartLenY);
    Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + FLenY - tmpStartY);
    Canvas.LineTo(tmpX + FLenX - tmpStartX - tmpStartLenX, tmpY + FLenY - tmpStartY);
    Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + FLenY - tmpStartY);
    Canvas.LineTo(tmpX + FLenX - tmpStartX, tmpY + FLenY - tmpStartY - tmpStartLenY);
  end;
end;

//Draw "piece" at the position "i, j"
procedure TBlackWhiteGame.DrawPiece(piece: TPiece; i, j: integer);
var
  tmpX, tmpY: Integer;
begin
  if Self.IsTempGame then Exit;
  with FPaintBox do
  begin
    Canvas.Pen.Color := FGridColor;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Color := FBackgroundColor;
    tmpX := JToX(j);
    tmpY := IToY(i);
    FLenX := FPaintBox.Width div FSize;
    FLenY := FPaintBox.Height div FSize;
    Canvas.Rectangle(tmpX, tmpY, tmpX + FLenX, tmpY + FLenY);
    if FBoard[i, j] <> PIECE_BLANK then
    begin
      if FBoard[i, j] = PIECE_WHITE then
        Canvas.Brush.Color := FWhiteColor
      else if FBoard[i, j] = PIECE_BLACK then
        Canvas.Brush.Color := FBlackColor;
      Canvas.Pen.Color := Canvas.Brush.Color;
      Canvas.Pen.Width := 1;
      tmpX := JToX(j);
      tmpY := IToY(i);
      Canvas.Ellipse(tmpX + 5, tmpY + 5, tmpX + FLenX - 5, tmpY + FLenY - 5);
      if (i = FLastMove.x) and (j = FLastMove.y) then
        DrawLastMove();
    end;
  end;
end;

//"data" will contains all available moves for the player who holds the "piece" and the function returns the count of all available moves
function TBlackWhiteGame.GetAllAvailableMove(var data: TListOfPoints; piece: TPiece): Integer;
var
  i, j: integer;
  tmpPoint: TPoint;
begin
  data := TListOfPoints.Create;
  data.Clear;
  for i := 0 to FSize - 1 do
    for j := 0 to FSize - 1 do
    begin
      if FBoard[i, j] = PIECE_BLANK then
      begin
        if IsAvailableMove(i, j, piece) then
        begin
          tmpPoint.x := i;
          tmpPoint.y := j;
          data.Add(tmpPoint);
        end;
      end;
    end;
  result := data.Count;
end;

function TBlackWhiteGame.GetResult(i, j: Integer; piece: TPiece): Integer;
var
  tmpNumber: Integer;
begin
  tmpNumber := 0;
  //1
  //Up
  tmpNumber := tmpNumber + Process(i, j, -1, 0, piece);
  //2
  //UpLeft
  tmpNumber := tmpNumber + Process(i, j, -1, -1, piece);
  //3
  //Left
  tmpNumber := tmpNumber + Process(i, j, 0, -1, piece);
  //4
  //DownLeft
  tmpNumber := tmpNumber + Process(i, j, 1, -1, piece);
  //5
  //Down
  tmpNumber := tmpNumber + Process(i, j, 1, 0, piece);
  //6
  //DownRight
  tmpNumber := tmpNumber + Process(i, j, 1, 1, piece);
  //7
  //Right
  tmpNumber := tmpNumber + Process(i, j, 0, 1, piece);
  //8
  //UpRight
  tmpNumber := tmpNumber + Process(i, j, -1, 1, piece);
  result := tmpNumber;
end;

function TBlackWhiteGame.IsAvailableMove(i, j: Integer; piece: TPiece): Boolean;
begin
  result := false;
  if FBoard[i, j] = PIECE_BLANK then
  begin
    if GetResult(i, j, piece) > 0 then
      result := true;
  end;
end;

procedure TBlackWhiteGame.LoadGame;
begin
  inherited;

end;

procedure TBlackWhiteGame.NewGame;
var
  i, j: integer;
begin
  inherited;
  for i := 0 to FSize - 1 do
    for j := 0 to FSize - 1 do
      FBoard[i, j] := PIECE_BLANK;
  Self.PlayAtMove(4, 4, PIECE_WHITE);
  Self.PlayAtMove(4, 5, PIECE_BLACK);
  Self.PlayAtMove(5, 4, PIECE_BLACK);
  Self.PlayAtMove(5, 5, PIECE_WHITE);
  Self.Turn := WHITE;
  Self.IsPlaying := True;
  Self.DrawAllAvailableMoves(WHITE);
end;

function TBlackWhiteGame.Process(i, j, k1, k2: Integer; piece: TPiece): Integer;
var
  number, tmpK1, tmpK2: integer;
begin
  number := 0;
  result := number;
  tmpK1 := k1;
  tmpK2 := k2;
  while (i + tmpK1 < FSize) and (i + tmpK1 >= 0) and (j + tmpK2 < FSize) and (j + tmpK2 >= 0) do
  begin
    if FBoard[i + tmpK1, j + tmpK2] <> PIECE_BLANK then
    begin
      if FBoard[i + tmpK1, j + tmpK2] = piece then
      begin
        result := number;
        break;
      end else begin
        inc(number);
        if tmpK1 > 0 then
          inc(tmpK1)
        else if tmpK1 < 0 then
          dec(tmpK1);
        if tmpK2 > 0 then
          inc(tmpK2)
        else if tmpK2 < 0 then
          dec(tmpK2);
      end;
    end else
      break;
  end;
end;

//based on the piece placed on the current position, process the whole board and rearrange all pieces on the board to reflect the move.
procedure TBlackWhiteGame.ReArrange(i, j: integer; piece: TPiece);
begin
  //1
  //Up
  Reverse(i, j, Process(i, j, -1, 0, piece), -1, 0);
  //2
  //UpLeft
  Reverse(i, j, Process(i, j, -1, -1, piece), -1, -1);
  //3
  //Left
  Reverse(i, j, Process(i, j, 0, -1, piece), 0, -1);
  //4
  //DownLeft
  Reverse(i, j, Process(i, j, 1, -1, piece), 1, -1);
  //5
  //Down
  Reverse(i, j, Process(i, j, 1, 0, piece), 1, 0);
  //6
  //DownRight
  Reverse(i, j, Process(i, j, 1, 1, piece), 1, 1);
  //7
  //Right
  Reverse(i, j, Process(i, j, 0, 1, piece), 0, 1);
  //8
  //UpRight
  Reverse(i, j, Process(i, j, -1, 1, piece), -1, 1);
end;

//redraw the whole chess
procedure TBlackWhiteGame.Refresh;
var
  i, j: Integer;
begin
  Self.DrawBoard;
  for i := 0 to FSize - 1 do
    for j := 0 to FSize - 1 do
      DrawPiece(FBoard[i, j], i, j);
  DrawLastMove();
  DrawAllAvailableMoves(Self.Turn);
end;

procedure TBlackWhiteGame.ResetGame;
begin
  Self.CloseGame;
  Self.NewGame;
  Self.Refresh;
end;

procedure TBlackWhiteGame.Reverse(i, j, number, k1, k2: Integer);
var
  tmpK1, tmpK2, tmpK: Integer;
begin
  tmpK1 := k1;
  tmpK2 := k2;
  for tmpK := 1 to number do
  begin
    Self.SetPiece(GetPiece(i, j), i + tmpK1, j + tmpK2);
    Self.DrawPiece(GetPiece(i + tmpK1, j + tmpK2), i + tmpK1, j + tmpK2);
    if tmpK1 > 0 then
      inc(tmpK1)
    else if tmpK1 < 0 then
      dec(tmpK1);
    if tmpK2 > 0 then
      inc(tmpK2)
    else if tmpK2 < 0 then
      dec(tmpK2);
  end;
end;

//check whether it is time to end the game and print who wins the game
function TBlackWhiteGame.TimeToCheck: Boolean;
var
  tmpData: TListOfPoints;
begin
  result := false;
  if (GetAllAvailableMove(tmpData, PIECE_WHITE) = 0) and
     (GetAllAvailableMove(tmpData, PIECE_BLACK) = 0) then
    result := true;
end;

//blink the last move
procedure TBlackWhiteGame.BlinkLastMove;
begin
  if Self.IsTempGame then Exit;
  DrawPiece(GetPiece(FLastMove.x, FLastMove.y), FLastMove.x, FLastMove.y);
  Application.ProcessMessages;
  Sleep(300);
  DrawLastMove();
  Application.ProcessMessages;
  Sleep(300);
  DrawPiece(GetPiece(FLastMove.x, FLastMove.y), FLastMove.x, FLastMove.y);
  Application.ProcessMessages;
  Sleep(300);
  DrawLastMove();
end;

//play at the position (i, j) with piece
procedure TBlackWhiteGame.PlayAtMove(i, j: Integer; piece: TPiece);
begin
  SetPiece(piece, i, j);
  DrawPiece(piece, i, j);
  FOldLastMove := FLastMove;
  FLastMove.x := i;
  FLastMove.y := j;
  DrawLastMove();
  Self.ReArrange(i, j, piece);
  if piece = PIECE_BLACK then
    FLastTurn := BLACK
  else
    FLastTurn := WHITE;
end;

//for the current player, draw all possible moves
procedure TBlackWhiteGame.DrawAllAvailableMoves(turn: TTurn);
begin
  if Self.IsTempGame then Exit;
  FreeAndNil(FOldAvailableMoveData);
  if FAvailableMoveData <> nil then
    FOldAvailableMoveData := TListOfPoints.Create(FAvailableMoveData)
  else
    FOldAvailableMoveData := TListOfPoints.Create;
  FOldAvailableMoveNumber := FAvailableMoveNumber;
  FAvailableMoveNumber := GetAllAvailableMove(FAvailableMoveData, GetPieceFromTurn(turn));
  DrawAvailableMove();
end;

procedure TBlackWhiteGame.DrawAvailableMove();
var
  tmpI, tmpJ, tmpX, tmpY, tmpStartX, tmpStartY, tmpStartLenX, tmpStartLenY, k: Integer;
  tmpPoint: TPoint;
begin
  if Self.IsTempGame then Exit;
  for k := 0 to FOldAvailableMoveNumber - 1 do
  begin
    tmpPoint := FOldAvailableMoveData[k];
    tmpI := tmpPoint.x;
    tmpJ := tmpPoint.y;
    DrawPiece(GetPiece(tmpI, tmpJ), tmpI, tmpJ);
  end;
  if not IsPlaying then exit;
  for k := 0 to FAvailableMoveNumber - 1 do
  begin
    tmpPoint := FAvailableMoveData[k];
    tmpI := tmpPoint.x;
    tmpJ := tmpPoint.y;
    tmpX := JToX(tmpJ);
    tmpY := IToY(tmpI);
    tmpStartX := 3;
    tmpStartY := 3;
    tmpStartLenX := 5;
    tmpStartLenY := 5;
    with FPaintBox do
    begin
      if Turn = WHITE then
        Canvas.Pen.Color := COLOR_AVAILABLEMOVE_WHITE
      else
        Canvas.Pen.Color := COLOR_AVAILABLEMOVE_BLACK;
      Canvas.Pen.Width := 1;
      Canvas.MoveTo(tmpX + tmpStartX, tmpY + tmpStartY);
      Canvas.LineTo(tmpX + tmpStartX, tmpY + tmpStartY + tmpStartLenY);
      Canvas.MoveTo(tmpX + tmpStartX, tmpY + tmpStartY);
      Canvas.LineTo(tmpX + tmpStartX + tmpStartLenX, tmpY + tmpStartY);
      Canvas.MoveTo(tmpX + tmpStartX, tmpY + FLenY - tmpStartY);
      Canvas.LineTo(tmpX + tmpStartX, tmpY + FLenY - tmpStartY - tmpStartLenY);
      Canvas.MoveTo(tmpX + tmpStartX, tmpY + FLenY - tmpStartY);
      Canvas.LineTo(tmpX + tmpStartX + tmpStartLenX, tmpY + FLenY - tmpStartY);
      Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + tmpStartY);
      Canvas.LineTo(tmpX + FLenX - tmpStartX - tmpStartLenX, tmpY + tmpStartY);
      Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + tmpStartY);
      Canvas.LineTo(tmpX + FLenX - tmpStartX, tmpY + tmpStartY + tmpStartLenY);
      Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + FLenY - tmpStartY);
      Canvas.LineTo(tmpX + FLenX - tmpStartX - tmpStartLenX, tmpY + FLenY - tmpStartY);
      Canvas.MoveTo(tmpX + FLenX - tmpStartX, tmpY + FLenY - tmpStartY);
      Canvas.LineTo(tmpX + FLenX - tmpStartX, tmpY + FLenY - tmpStartY - tmpStartLenY);
    end;
  end;
end;

function TBlackWhiteGame.GetPieceFromTurn(turn: TTurn): TPiece;
begin
  if turn = WHITE then
    result := PIECE_WHITE
  else
    result := PIECE_BLACK;
end;

//return the count of "piece" on the current board
function TBlackWhiteGame.GetPiecesNumber(piece: TPiece): Integer;
var
  tmpCount, i, j: Integer;
begin
  tmpCount := 0;
  for i := 0 to FSize - 1 do
    for j := 0 to FSize - 1 do
    begin
      if FBoard[i, j] = piece then inc(tmpCount);
    end;
  result := tmpCount;
end;

procedure TBlackWhiteGame.SaveGame;
begin
  inherited;

end;

procedure TBlackWhiteGame.SetIsPlaying(const Value: Boolean);
begin
  inherited;
  DrawAllAvailableMoves(Turn);
  DrawLastMove();
  Application.ProcessMessages;
end;

procedure TBlackWhiteGame.Swap;
begin
  inherited;

end;

end.
