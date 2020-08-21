unit BlackWhiteGame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ExtCtrls, StdCtrls, ToolWin, Common, BoardGame, StateNode, StateTree;

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
    constructor Create(PaintBox: TPaintBox; sizeX: Integer; sizeY: Integer; TempObject: Boolean); overload; override;
    constructor Create(blackWhiteGame: TBoardGame); overload; override;
    destructor Destroy(); override;
    function GetPiecesNumber(piece: TPiece): Integer;
    function IsAvailableMove(i, j: Integer; piece: TPiece): Boolean;
    procedure PlayAtMove(i, j: Integer; piece: TPiece);
    procedure EndGameAndPrint();
    function GetAllAvailableMove(var data: TListOfPoints; piece: TPiece): Integer;
    procedure DrawAllAvailableMoves(turn: TTurn);
    function AutoPlay(var i, j: Integer; piece: TPiece; way: TWay): Boolean;
    procedure BlinkLastMove();
    procedure About(); override;
    procedure NewGame(); override;
    procedure CloseGame(); override;
    procedure ResetGame; override;
    procedure SaveGame(); override;
    procedure LoadGame(); override;
    procedure Swap(); override;
    procedure Refresh(); override;
    procedure Print(node: TStateNode);
  end;


implementation

uses
  BlackWhiteGameStateTree;

var
  GStateTree: TStateTree;

{ TBlackWhiteGame }

procedure TBlackWhiteGame.About;
begin
  MessageBox(Application.Handle,
             'Game: BlackWhiteChess' + #$D + #$A +
             'Programmer: Ricol Wang' + #$D + #$A +
             'Date: 28/08/2012 - V1.0' + #$D + #$A +
             'Date: 01/05/2013 - V2.0' + #$D + #$A +
             'Date: 09/06/2013 - V2.1', 'About', MB_OK);
end;

//return a optimal position (i and j) for the current player which holds "piece"
//if there is no available move, then return "false", else return "true"
function TBlackWhiteGame.AutoPlay(var i: Integer; var j: Integer; piece: TPiece; way: TWay): Boolean;
begin
  if way = LOOP then
    Result := self.GoToLevel(i, j, piece)
  else
    Result := self.AnalyzeToLevel(GComputerCalculateLevel, i, j, piece);
end;

//autoplay by recursive
function TBlackWhiteGame.AnalyzeToLevel(level: Integer; var x, y: Integer; piece: TPiece): boolean;
var
  k: Integer;
  num: Integer;
  data: TListOfPoints;
  game: TBlackWhiteGame;

  currentNode: TStateNode;
  point: TPoint;
  head: TBoardGame;
begin
  //create the State Tree and save all possible chess state into the tree
  OutputDebugString('Analyzing by recursive...');

  head := TBlackWhiteGame.Create(Self);
  GStateTree := TBlackWhiteGameStateTree.Create(head);
  GStateTree.ListBox := Self.ListBox;
  GStateTree.TreeView := Self.TreeView;
  currentNode := GStateTree.Head;

  //get all possible moves for piece.
  num := GetAllAvailableMove(data, piece);

  if num > 0 then
  begin
    FProgressBar.Min := 0;
    FProgressBar.Max := num - 1;
    FProgressBar.Position := 0;
    FProgressBar.Visible := True;
    for k := 0 to num - 1 do
    begin
      FProgressBar.Position := k;
      Application.ProcessMessages;
      game := TBlackWhiteGame.Create(Self);
      game.IsTempGame := True;
      point := data[k];
      game.PlayAtMove(point.x, point.y, piece);
      currentNode := GStateTree.InsertTheNode(game, point.x, point.y, currentNode);

      self.NextLevel(level, piece, point, game, GStateTree, currentNode);

      currentNode := currentNode.parentNode;
    end;
    //return a optimal result by analyzing the state tree.
    point := Self.AnalyzeTheStateTree(GStateTree, Self.Turn);
    x := point.X;
    y := point.Y;
    OutputDebugString(PChar(Format('Choose: %d, %d', [x + 1, y + 1])));
    Result := true;
    FreeAndNil(data);
    GStateTree.Print;
    GStateTree.PrintToTreeView;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
    exit;
  end else
  begin
    result := False;
    FreeAndNil(data);
    GStateTree.Print;
    GStateTree.PrintToTreeView;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
  end;
end;

procedure TBlackWhiteGame.NextLevel(const totalLevel: Integer; piece: TPiece; const step: TPoint; gameOld: TBlackWhiteGame; var stateTree: TStateTree; var currentNode: TStateNode);
var
  numOld, numNew: Integer;
  kOld, kNew: Integer;
  tmpGameOld, tmpGameNew: TBlackWhiteGame;
  dataOld, dataNew: TListOfPoints;
  point: TPoint;
begin
  if TStateTree.getLevel(currentNode) >= 2 * totalLevel then
    exit;

  tmpGameOld := gameOld;
  //get all possible moves for the opponent of piece
  numOld := tmpGameOld.GetAllAvailableMove(dataOld, TBlackWhiteGame.GetOpponent(piece));
  if numOld > 0 then
  begin
    for kOld := 0 to numOld - 1 do
    begin
      tmpGameNew := TBlackWhiteGame.Create(tmpGameOld);
      tmpGameNew.IsTempGame := True;
      point := dataOld[kOld];
      tmpGameNew.PlayAtMove(point.x, point.y, TBlackWhiteGame.GetOpponent(piece));
      currentNode := GStateTree.InsertTheNode(tmpGameNew, point.x, point.y, currentNode);

      //get all possible moves for piece
      numNew := tmpGameNew.GetAllAvailableMove(dataNew, piece);
      if numNew > 0 then
      begin
        for kNew := 0 to numNew - 1 do
        begin
          tmpGameOld := TBlackWhiteGame.Create(tmpGameNew);
          tmpGameOld.IsTempGame := True;
          point := dataNew[kNew];
          tmpGameOld.PlayAtMove(point.X, point.Y, piece);
          point := step;
//          self.Print(currentNode);
          currentNode := GStateTree.InsertTheNode(tmpGameOld, point.X, point.Y, currentNode);
//          self.Print(currentNode);
          if TStateTree.getLevel(currentNode) < 2 * totalLevel then
            self.NextLevel(totalLevel, piece, step, tmpGameOld, stateTree, currentNode);
          currentNode := currentNode.parentNode;
        end;
      end;
      FreeAndNil(dataNew);

      currentNode := currentNode.parentNode;
    end;
  end;
  FreeAndNil(dataOld);
end;

//autoplay by deep loop
function TBlackWhiteGame.GoToLevel(var x, y: Integer;
  piece: TPiece): boolean;
var
  k, k1, k2, k3, k4, k5, k6: Integer;
  num, num1, num2, num3, num4, num5, num6: Integer;
  data, data1, data2, data3, data4, data5, data6: TListOfPoints;
  game, game1, game2, game3, game4, game5, game6: TBlackWhiteGame;

  currentNode: TStateNode;
  point: TPoint;
  head: TBoardGame;
begin
  //create the State Tree and save all possible chess state into the tree
  OutputDebugString('Analyzing by loop...');

  head := TBlackWhiteGame.Create(Self);
  GStateTree := TBlackWhiteGameStateTree.Create(head);
  GStateTree.ListBox := Self.ListBox;
  GStateTree.TreeView := Self.TreeView;
  currentNode := GStateTree.Head;

  //get all possible moves for piece.
  num := GetAllAvailableMove(data, piece);

  if num > 0 then
  begin
    FProgressBar.Min := 0;
    FProgressBar.Max := num - 1;
    FProgressBar.Position := 0;
    FProgressBar.Visible := True;
    for k := 0 to num - 1 do
    begin
      FProgressBar.Position := k;
      Application.ProcessMessages;
      game := TBlackWhiteGame.Create(Self);
      game.IsTempGame := True;
      point := data[k];
      game.PlayAtMove(point.x, point.y, piece);
      currentNode := GStateTree.InsertTheNode(game, point.x, point.y, currentNode);

      //==========Level 1=============
      //get all possible moves for the opponent of piece.
      num1 := game.GetAllAvailableMove(data1, TBlackWhiteGame.GetOpponent(piece));
      if num1 > 0 then
      begin
        for k1 := 0 to num1 - 1 do
        begin
          game1 := TBlackWhiteGame.Create(game);
          game1.IsTempGame := True;
          point := data1[k1];
          game1.PlayAtMove(point.x, point.y, TBlackWhiteGame.GetOpponent(piece
          ));
          point := data[k];
          currentNode := GStateTree.InsertTheNode(game1, point.x, point.y, currentNode);

          //get all possible moves for the piece
          num2 := game1.GetAllAvailableMove(data2, piece);
          if num2 > 0 then
          begin
            for k2 := 0 to num2 - 1 do
            begin
              game2 := TBlackWhiteGame.Create(game1);
              game2.IsTempGame := True;
              point := data2[k2];
              game2.PlayAtMove(point.X, point.Y, piece);
              point := data[k];
              currentNode := GStateTree.InsertTheNode(game2, point.X, point.Y, currentNode);

              //==============Level 2===============

              //get all possible moves for the opponent of piece
              num3 := game2.GetAllAvailableMove(data3, TBlackWhiteGame.GetOpponent(piece
              ));
              if num3 > 0 then
              begin
                for k3 := 0 to num3 - 1 do
                begin
                  game3 := TBlackWhiteGame.Create(game2);
                  game3.IsTempGame := True;
                  point := data3[k3];
                  game3.PlayAtMove(point.X, point.Y, TBlackWhiteGame.GetOpponent(piece));
                  point := data[k];
                  currentNode := GStateTree.InsertTheNode(game3, point.X, point.Y, currentNode);

                  //get all possible moves for piece
                  num4 := game3.GetAllAvailableMove(data4, piece);
                  if num4 > 0 then
                  begin
                    for k4 := 0 to num4 - 1 do
                    begin
                      game4 := TBlackWhiteGame.Create(game3);
                      game4.IsTempGame := True;
                      point := data4[k4];
                      game4.PlayAtMove(point.X, point.Y, piece);
                      point := data[k];
                      currentNode := GStateTree.InsertTheNode(game4, point.X, point.Y, currentNode);
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
                      currentNode := currentNode.parentNode;
                    end;
                  end;
                  FreeAndNil(data4);
                  currentNode := currentNode.parentNode;
                end;
              end;
              FreeAndNil(data3);
              //================Level 2 end================
              currentNode := currentNode.parentNode;
            end;
          end;
          FreeAndNil(data2);
          currentNode := currentNode.parentNode;
        end;
      end;
      FreeAndNil(data1);
      //==================Level 1 end=================
      currentNode := currentNode.parentNode;
    end;

    //return a optimal result by analyzing the state tree.
    point := Self.AnalyzeTheStateTree(GStateTree, Self.Turn);
    x := point.X;
    y := point.Y;
    OutputDebugString(PChar(Format('Choose: %d, %d', [x + 1, y + 1])));
    Result := true;
    FreeAndNil(data);
    GStateTree.Print;
    GStateTree.PrintToTreeView;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
    exit;
  end else
  begin
    result := False;
    FreeAndNil(data);
    GStateTree.Print;
    GStateTree.PrintToTreeView;
    FreeAndNil(GStateTree);
    FProgressBar.Visible := False;
  end;
end;

//analyze the state tree and get the optimal result
function TBlackWhiteGame.AnalyzeTheStateTree(
  stateTree: TStateTree; turn: TTurn): TPoint;
var
  st: TStateTree;
  allLeaves: TListOfNodes;
  currentNode: TStateNode;
  gameCurrent: TBlackWhiteGame;
  max, k, l, numOfBlack, numOfWhite, res: Integer;
  point: TPoint;
begin
  //analyze the state tree and find the optimum node
  st := stateTree;
  allLeaves := st.getAllLeaves(True);

  max := 0;
  l := 0;
  OutputDebugString(PChar(Format('Analyzing...Total Leaves: %d', [allLeaves.Count])));

  if turn = WHITE then
  begin
    for k := 0 to allLeaves.Count - 1 do
    begin
      currentNode := allLeaves[k];

      gameCurrent := TBlackWhiteGame(currentNode.data);

      numOfBlack := gameCurrent.GetPiecesNumber(PIECE_BLACK);
      numOfWhite := gameCurrent.GetPiecesNumber(PIECE_WHITE);
      res := numOfWhite - numOfBlack;

      if numOfBlack <= 0 then
      begin
        l := k;
        OutputDebugString(PChar(Format('#######: Found The Optimal Result! Level %d', [TStateTree.getLevel(currentNode)])));
        OutputDebugString(PChar(Format('tmpResult: %d', [res])));
        Beep;
        break;
      end;

      if res >= max then
      begin
        l := k;
        max := res;
        OutputDebugString(PChar(Format('tmpMax: %d', [max])));
      end;
    end;
  end else begin
    for k := 0 to allLeaves.Count - 1 do
    begin
      currentNode := allLeaves[k];
      gameCurrent := TBlackWhiteGame(currentNode.data);

      numOfBlack := gameCurrent.GetPiecesNumber(PIECE_BLACK);
      numOfWhite := gameCurrent.GetPiecesNumber(PIECE_WHITE);
      res := numOfBlack - numOfWhite;

      if numOfWhite <= 0 then
      begin
        l := k;
        OutputDebugString(PChar(Format('#######: Found The Optimal Result! Level %d', [TStateTree.getLevel(currentNode)])));
        OutputDebugString(PChar(Format('tmpResult: %d', [res])));
        Beep;
        break;
      end;

      if res >= max then
      begin
        l := k;
        max := res;
        OutputDebugString(PChar(Format('tmpMax: %d', [max])));
      end;
    end;
  end;

  currentNode := allLeaves[l];
  point.X := currentNode.step_i;
  point.Y := currentNode.step_j;
  FreeAndNil(allLeaves);

  Result := point;
end;

//Check who wins the game and end the game
procedure TBlackWhiteGame.EndGameAndPrint;
var
  numWhite, numBlack: Integer;
begin
  inherited;
  numWhite := GetPiecesNumber(PIECE_WHITE);
  numBlack := GetPiecesNumber(PIECE_BLACK);
  if numWhite > numBlack then
  begin
    MessageBox(Application.Handle,
               PChar('Congratulation, White Win!' + #$D + #$A +
               Format('White pieces: %d', [numWhite]) + #$D + #$A +
               Format('Black pieces: %d', [numBlack])), 'Result', MB_OK);
  end else if numWhite = numBlack then
  begin
    MessageBox(Application.Handle,
               PChar('This is a draw' + #$D + #$A +
               Format('White pieces: %d', [numWhite]) + #$D + #$A +
               Format('Black pieces: %d', [numBlack])), 'Result', MB_OK);
  end else begin
    MessageBox(Application.Handle,
               PChar('Congratulation, Black Win!' + #$D + #$A +
               Format('Black pieces: %d', [numBlack]) + #$D + #$A +
               Format('White pieces: %d', [numWhite])), 'Result', MB_OK)
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
  bwGame: TBlackWhiteGame;
begin
  inherited Create(blackWhiteGame);
  bwGame := TBlackWhiteGame(blackWhiteGame);
  FGridColor := bwGame.FGridColor;
  FBlackColor := bwGame.FBlackColor;
  FWhiteColor := bwGame.FWhiteColor;
  FTurn := bwGame.FTurn;
  FLastMove := bwGame.FLastMove;
  FOldLastMove := bwGame.FOldLastMove;
  FOldAvailableMoveNumber := bwGame.FOldAvailableMoveNumber;
  if not FIsTempGame then
  begin
    FOldAvailableMoveData := TListOfPoints.Create(bwGame.FOldAvailableMoveData);
    FAvailableMoveData := TListOfPoints.Create(bwGame.FAvailableMoveData);
  end;
  FProgressBar := bwGame.FProgressBar;
  FListBox := bwGame.FListBox;
end;

//constructor
constructor TBlackWhiteGame.Create(PaintBox: TPaintBox; sizeX: Integer; sizeY: Integer; TempObject: Boolean);
var
  i, j: integer;
begin
  inherited Create(PaintBox, sizeX, sizeY, TempObject);
  for i := 0 to sizeX - 1 do
    for j := 0 to sizeY - 1 do
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
  x, y, i: Integer;
begin
  inherited;
  if Self.IsTempGame then Exit;

  x := FPaintBox.Width;
  y := FPaintBox.Height;
  with FPaintBox do
  begin
    Canvas.Brush.Color := FBackgroundColor;
    Canvas.Pen.Color := FGridColor;
    Canvas.Pen.Width := 1;
    Canvas.Rectangle(0, 0, x, y);
    for i := 0 to Self.FSizeX - 1 do
    begin
      Canvas.MoveTo(0, Trunc(FLenY * i));
      Canvas.LineTo(x, Trunc(FLenY * i));
      Canvas.MoveTo(Trunc(FLenX * i), 0);
      Canvas.LineTo(Trunc(FLenX * i), y);
    end;
  end;
end;

//draw the last move and highlight the move
procedure TBlackWhiteGame.DrawLastMove;
var
  x, y, startX, startY, startLenX, startLenY: Double;
begin
  if Self.IsTempGame then Exit;
  DrawPiece(GetPiece(FOldLastMove.x, FOldLastMove.y), FOldLastMove.x, FOldLastMove.y);
  if not IsPlaying then exit;
  x := IToX(FLastMove.x);
  y := JToY(FLastMove.y);
  startX := 3;
  startY := 3;
  startLenX := 5;
  startLenY := 5;
  with FPaintBox do
  begin
    Canvas.Pen.Color := clRed;
    Canvas.Pen.Width := 3;
    Canvas.MoveTo(Trunc(x + startX), Trunc(y + startY));
    Canvas.LineTo(Trunc(x + startX), Trunc(y + startY + startLenY));
    Canvas.MoveTo(Trunc(x + startX), Trunc(y + startY));
    Canvas.LineTo(Trunc(x + startX + startLenX), Trunc(y + startY));
    Canvas.MoveTo(Trunc(x + startX), Trunc(y + FLenY - startY));
    Canvas.LineTo(Trunc(x + startX), Trunc(y + FLenY - startY - startLenY));
    Canvas.MoveTo(Trunc(x + startX), Trunc(y + FLenY - startY));
    Canvas.LineTo(Trunc(x + startX + startLenX), Trunc(y + FLenY - startY));
    Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + startY));
    Canvas.LineTo(Trunc(x + FLenX - startX - startLenX), Trunc(y + startY));
    Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + startY));
    Canvas.LineTo(Trunc(x + FLenX - startX), Trunc(y + startY + startLenY));
    Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + FLenY - startY));
    Canvas.LineTo(Trunc(x + FLenX - startX - startLenX), Trunc(y + FLenY - startY));
    Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + FLenY - startY));
    Canvas.LineTo(Trunc(x + FLenX - startX), Trunc(y + FLenY - startY - startLenY));
  end;
end;

//Draw "piece" at the position "i, j"
procedure TBlackWhiteGame.DrawPiece(piece: TPiece; i, j: integer);
var
  x, y: Double;
begin
  if Self.IsTempGame then Exit;
  with FPaintBox do
  begin
    Canvas.Pen.Color := FGridColor;
    Canvas.Pen.Width := 1;
    Canvas.Brush.Color := FBackgroundColor;
    x := IToX(i);
    y := JToY(j);
    FLenX := FPaintBox.Width div FSizeX;
    FLenY := FPaintBox.Height div FSizeY;
    Canvas.Rectangle(Trunc(x), Trunc(y), Trunc(x + FLenX), Trunc(y + FLenY));
    if FBoard[i, j] <> PIECE_BLANK then
    begin
      if FBoard[i, j] = PIECE_WHITE then
        Canvas.Brush.Color := FWhiteColor
      else if FBoard[i, j] = PIECE_BLACK then
        Canvas.Brush.Color := FBlackColor;
      Canvas.Pen.Color := Canvas.Brush.Color;
      Canvas.Pen.Width := 1;
      x := IToX(i);
      y := JToY(j);
      Canvas.Ellipse(Trunc(x + 5), Trunc(y + 5), Trunc(x + FLenX - 5), Trunc(y + FLenY - 5));
      if (i = FLastMove.x) and (j = FLastMove.y) then
        DrawLastMove();
    end;
  end;
end;

//"data" will contains all available moves for the player who holds the "piece" and the function returns the count of all available moves
function TBlackWhiteGame.GetAllAvailableMove(var data: TListOfPoints; piece: TPiece): Integer;
var
  i, j: integer;
  point: TPoint;
begin
  data := TListOfPoints.Create;
  data.Clear;
  for i := 0 to FSizeX - 1 do
    for j := 0 to FSizeY - 1 do
    begin
      if FBoard[i, j] = PIECE_BLANK then
      begin
        if IsAvailableMove(i, j, piece) then
        begin
          point.x := i;
          point.y := j;
          data.Add(point);
        end;
      end;
    end;
  result := data.Count;
end;

function TBlackWhiteGame.GetResult(i, j: Integer; piece: TPiece): Integer;
var
  num: Integer;
begin
  num := 0;
  //1
  //Up
  num := num + Process(i, j, -1, 0, piece);
  //2
  //UpLeft
  num := num + Process(i, j, -1, -1, piece);
  //3
  //Left
  num := num + Process(i, j, 0, -1, piece);
  //4
  //DownLeft
  num := num + Process(i, j, 1, -1, piece);
  //5
  //Down
  num := num + Process(i, j, 1, 0, piece);
  //6
  //DownRight
  num := num + Process(i, j, 1, 1, piece);
  //7
  //Right
  num := num + Process(i, j, 0, 1, piece);
  //8
  //UpRight
  num := num + Process(i, j, -1, 1, piece);
  result := num;
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
  i, j, k: integer;
begin
  inherited;
  for i := 0 to FSizeX - 1 do
    for j := 0 to FSizeY - 1 do
      FBoard[i, j] := PIECE_BLANK;
  k := NUMBER_X div 2;
  Self.PlayAtMove(k, k, PIECE_WHITE);
  Self.PlayAtMove(k, k + 1, PIECE_BLACK);
  Self.PlayAtMove(k + 1, k + 1, PIECE_WHITE);
  Self.PlayAtMove(k + 1, k, PIECE_BLACK);
  Self.Turn := WHITE;
  Self.IsPlaying := True;
  Self.DrawAllAvailableMoves(WHITE);
end;

procedure TBlackWhiteGame.Print(node: TStateNode);
var
  lvl: Integer;
begin
  lvl := TStateTree.getLevel(node);
  OutputDebugString(PChar(Format('CurrentNode.level: %d', [lvl])));
end;

function TBlackWhiteGame.Process(i, j, k1, k2: Integer; piece: TPiece): Integer;
var
  number, m, n: integer;
begin
  number := 0;
  result := number;
  m := k1;
  n := k2;
  while (i + m < FSizeX) and (i + m >= 0) and (j + n < FSizeY) and (j + n >= 0) do
  begin
    if FBoard[i + m, j + n] <> PIECE_BLANK then
    begin
      if FBoard[i + m, j + n] = piece then
      begin
        result := number;
        break;
      end else begin
        inc(number);
        if m > 0 then
          inc(m)
        else if m < 0 then
          dec(m);
        if n > 0 then
          inc(n)
        else if n < 0 then
          dec(n);
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
  for i := 0 to FSizeX - 1 do
    for j := 0 to FSizeY - 1 do
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
  x, y, z: Integer;
begin
  x := k1;
  y := k2;
  for z := 1 to number do
  begin
    Self.SetPiece(GetPiece(i, j), i + x, j + y);
    Self.DrawPiece(GetPiece(i + x, j + y), i + x, j + y);
    if x > 0 then
      inc(x)
    else if x < 0 then
      dec(x);
    if y > 0 then
      inc(y)
    else if y < 0 then
      dec(y);
  end;
end;

//check whether it is time to end the game and print who wins the game
function TBlackWhiteGame.TimeToCheck: Boolean;
var
  data: TListOfPoints;
begin
  result := false;
  if (GetAllAvailableMove(data, PIECE_WHITE) = 0) and
     (GetAllAvailableMove(data, PIECE_BLACK) = 0) then
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
  i, j, k: Integer;
  point: TPoint;
  x, y, startX, startY, startLenX, startLenY: Double;
begin
  if Self.IsTempGame then Exit;
  for k := 0 to FOldAvailableMoveNumber - 1 do
  begin
    point := FOldAvailableMoveData[k];
    i := point.x;
    j := point.y;
    DrawPiece(GetPiece(i, j), i, j);
  end;
  if not IsPlaying then exit;
  for k := 0 to FAvailableMoveNumber - 1 do
  begin
    point := FAvailableMoveData[k];
    i := point.x;
    j := point.y;
    x := IToX(i);
    y := JToY(j);
    startX := 3;
    startY := 3;
    startLenX := 5;
    startLenY := 5;
    with FPaintBox do
    begin
      if Turn = WHITE then
        Canvas.Pen.Color := COLOR_AVAILABLEMOVE_WHITE
      else
        Canvas.Pen.Color := COLOR_AVAILABLEMOVE_BLACK;
      Canvas.Pen.Width := 1;
      Canvas.MoveTo(Trunc(x + startX), Trunc(y + startY));
      Canvas.LineTo(Trunc(x + startX), Trunc(y + startY + startLenY));
      Canvas.MoveTo(Trunc(x + startX), Trunc(y + startY));
      Canvas.LineTo(Trunc(x + startX + startLenX), Trunc(y + startY));
      Canvas.MoveTo(Trunc(x + startX), Trunc(y + FLenY - startY));
      Canvas.LineTo(Trunc(x + startX), Trunc(y + FLenY - startY - startLenY));
      Canvas.MoveTo(Trunc(x + startX), Trunc(y + FLenY - startY));
      Canvas.LineTo(Trunc(x + startX + startLenX), Trunc(y + FLenY - startY));
      Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + startY));
      Canvas.LineTo(Trunc(x + FLenX - startX - startLenX), Trunc(y + startY));
      Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + startY));
      Canvas.LineTo(Trunc(x + FLenX - startX), Trunc(y + startY + startLenY));
      Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + FLenY - startY));
      Canvas.LineTo(Trunc(x + FLenX - startX - startLenX), Trunc(y + FLenY - startY));
      Canvas.MoveTo(Trunc(x + FLenX - startX), Trunc(y + FLenY - startY));
      Canvas.LineTo(Trunc(x + FLenX - startX), Trunc(y + FLenY - startY - startLenY));
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
  count, i, j: Integer;
begin
  count := 0;
  for i := 0 to FSizeX - 1 do
    for j := 0 to FSizeY - 1 do
    begin
      if FBoard[i, j] = piece then inc(count);
    end;
  result := count;
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
