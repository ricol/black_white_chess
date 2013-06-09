unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ExtCtrls, ToolWin, UnitTBlackWhiteGame;

type
  TFormMain = class(TForm)
    StatusBar1: TStatusBar;
    MainMenu1: TMainMenu;
    MenuGame: TMenuItem;
    MenuConfig: TMenuItem;
    MenuHelp: TMenuItem;
    MenuHelp_About: TMenuItem;
    MenuGame_NewGame: TMenuItem;
    MenuGame_SaveGame: TMenuItem;
    MenuGame_LoadGame: TMenuItem;
    MenuGame_CloseGame: TMenuItem;
    MenuGame_Seperator1: TMenuItem;
    MenuGame_Seperator2: TMenuItem;
    MenuGame_Exit: TMenuItem;
    MenuConfig_Swap: TMenuItem;
    MenuConfig_Difficulties: TMenuItem;
    MenuConfig_Color: TMenuItem;
    MenuConfig_Music: TMenuItem;
    MenuConfig_SoundEffect: TMenuItem;
    MenuNetwork: TMenuItem;
    MenuNetwork_NewServer: TMenuItem;
    MenuNetwork_ConnectTo: TMenuItem;
    MenuNetwork_Seperator1: TMenuItem;
    MenuNetwork_StartGame: TMenuItem;
    MenuNetwork_CloseGame: TMenuItem;
    MenuNetwork_SendMessage: TMenuItem;
    MenuNetwork_Seperator3: TMenuItem;
    MenuNetwork_AboutNetwork: TMenuItem;
    MenuNetwork_Seperator2: TMenuItem;
    PaintBoxMain: TPaintBox;
    ProgressBar1: TProgressBar;
    AutoplayByLoop: TMenuItem;
    AutoplayByRecursive: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBoxMainPaint(Sender: TObject);
    procedure MenuHelp_AboutClick(Sender: TObject);
    procedure PaintBoxMainMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuGame_NewGameClick(Sender: TObject);
    procedure MenuGame_ExitClick(Sender: TObject);
    procedure MenuGame_CloseGameClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure AutoplayByLoopClick(Sender: TObject);
    procedure Autoplay(way: TWay);
    procedure AutoplayByRecursiveClick(Sender: TObject);
  private
    { Private declarations }
    procedure ProcessMessage_WM_ERASEBKGND(var tmpMessage: TMessage); message WM_ERASEBKGND;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

uses UnitCommon, UnitFormData;

{$R *.dfm}

var
  GGame: TBlackWhiteGame;
  GFormData: TFormStateTreeData;

procedure TFormMain.Autoplay(way: TWay);
var
  i, j, tmpNumber: integer;
  canMove: Boolean;
  tmpData: TListOfPoints;
begin
  if not GGame.IsPlaying then
    Exit;
  if GGame.Turn = WHITE then
  begin
    canMove := GGame.AutoPlay(i, j, PIECE_WHITE, way);
    if canMove then
    begin
      GGame.PlayAtMove(i, j, PIECE_WHITE);
      tmpNumber := GGame.GetAllAvailableMove(tmpData, PIECE_BLACK);
      if tmpNumber = 0 then
      begin
        tmpNumber := GGame.GetAllAvailableMove(tmpData, PIECE_WHITE);
        if tmpNumber = 0 then
        begin
          //if myself can not move either then it is time to check the game
          GGame.EndGameAndPrint;
          GGame.IsPlaying := False;
          MenuGame_NewGame.Enabled := True;
          MenuGame_CloseGame.Enabled := False;
          exit;
        end else begin
          GGame.Turn := WHITE;
          ShowMessage('White Continue.');
        end;
      end else
        GGame.Turn := BLACK;
    end else
    begin
      ShowMessage('No more move for white!');
    end;
  end else begin
    canMove := GGame.AutoPlay(i, j, PIECE_BLACK, way);
    if canMove then
    begin
      GGame.PlayAtMove(i, j, PIECE_BLACK);
      tmpNumber := GGame.GetAllAvailableMove(tmpData, PIECE_WHITE);
      if tmpNumber = 0 then
      begin
        tmpNumber := GGame.GetAllAvailableMove(tmpData, PIECE_BLACK);
        if tmpNumber = 0 then
        begin
          //if myself can not move either then it is time to check the game
          GGame.EndGameAndPrint;
          GGame.IsPlaying := False;
          MenuGame_NewGame.Enabled := True;
          MenuGame_CloseGame.Enabled := False;
          exit;
        end else begin
          GGame.Turn := BLACK;
          ShowMessage('Black continue.');
        end;
      end else
        GGame.Turn := WHITE;
    end else
      ShowMessage('No more move for black!');
  end;

  GGame.DrawAllAvailableMoves(GGame.Turn);
  Application.ProcessMessages;
end;

procedure TFormMain.AutoplayByLoopClick(Sender: TObject);
begin
  self.Autoplay(LOOP);
end;

procedure TFormMain.AutoplayByRecursiveClick(Sender: TObject);
begin
  self.Autoplay(RECURSIVE);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Randomize;
  GGame := TBlackWhiteGame.Create(Self.PaintBoxMain, NUMBER, False);
  GGame.ProgressBar := Self.ProgressBar1;

  ProgressBar1.Parent := Self.StatusBar1;
  ProgressBar1.Left := 50;
  ProgressBar1.Top := 2;
  ProgressBar1.Width := Self.StatusBar1.Panels[0].Width - 50;
  ProgressBar1.Smooth := True;
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 100;
  ProgressBar1.Position := 0;
  ProgressBar1.Visible := False;

  FreeAndNil(GFormData);
  GFormData := TFormStateTreeData.Create(self);
  GFormData.Show;
  GFormData.Left := Self.Left + Self.Width + 5;
  GFormData.Top := Self.Top;

  GGame.ListBox := GFormData.ListBoxMain;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(GGame);
  FreeAndNil(GFormData);
end;

procedure TFormMain.PaintBoxMainPaint(Sender: TObject);
begin
  GGame.Refresh;
end;

procedure TFormMain.ProcessMessage_WM_ERASEBKGND(var tmpMessage: TMessage);
begin
end;

procedure TFormMain.MenuHelp_AboutClick(Sender: TObject);
begin
  GGame.About;
end;

procedure TFormMain.PaintBoxMainMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, j, tmpNumber: integer;
  tmpPiece: TPiece;
  tmpData: TListOfPoints;
begin
  //check whether the game is playing
  if not GGame.IsPlaying then Exit;
  //get current position
  i := GGame.YToI(Y);
  j := GGame.XToJ(X);
  tmpPiece := PIECE_WHITE;
  if not GGame.IsAvailableMove(i, j, tmpPiece) then
  begin
    //it is not a available move
    Beep;
    Exit;
  end else begin
    //it is a available move
    GGame.PlayAtMove(i, j, tmpPiece);
    StatusBar1.Panels[1].Text := Format('Status: %d(Black) - %d(White)', [GGame.GetPiecesNumber(PIECE_BLACK), GGame.GetPiecesNumber(PIECE_WHITE)]);
    tmpNumber := GGame.GetAllAvailableMove(tmpData, GGame.GetOpponent(tmpPiece));
    if tmpNumber = 0 then
    begin
      Windows.Beep(1000, 50);
      //if the opponent can not move
      tmpNumber := GGame.GetAllAvailableMove(tmpData, tmpPiece);
      if tmpNumber = 0 then
      begin
        //if myself can not move either then it is time to check the game
        GGame.EndGameAndPrint;
        GGame.IsPlaying := False;
        MenuGame_NewGame.Enabled := True;
        MenuGame_CloseGame.Enabled := False;
        exit;
      end;
    end else begin
      //time for the opponent which is the computer to move
      GGame.Turn := BLACK;
      tmpPiece := PIECE_BLACK;
      repeat
        GGame.DrawAllAvailableMoves(GGame.Turn);
        Application.ProcessMessages;
        Sleep(DELAYTIME);
        if GGame.AutoPlay(i, j, tmpPiece, LOOP) then
        begin
          GGame.PlayAtMove(i, j, tmpPiece);
          StatusBar1.Panels[1].Text := Format('Status: %d(Black) - %d(White)', [GGame.GetPiecesNumber(PIECE_BLACK), GGame.GetPiecesNumber(PIECE_WHITE)]);
          //the opponent played, then check whether myself can move
          tmpNumber := GGame.GetAllAvailableMove(tmpData, GGame.GetOpponent(tmpPiece));
          if tmpNumber = 0 then
          begin
            Windows.Beep(2000, 50);
            tmpNumber := GGame.GetAllAvailableMove(tmpData, tmpPiece);
            if tmpNumber = 0 then
            begin
              GGame.EndGameAndPrint;
              GGame.IsPlaying := False;
              MenuGame_NewGame.Enabled := True;
              MenuGame_CloseGame.Enabled := False;
              exit;
            end;
          end else break;
        end else begin
          MessageBox(Self.Handle, 'Should not happen!', 'Warning', MB_OK or MB_ICONINFORMATION);
        end;
      until false;
      GGame.Turn := WHITE;
    end;
  end;
  GGame.DrawAllAvailableMoves(GGame.Turn);
end;

procedure TFormMain.MenuGame_NewGameClick(Sender: TObject);
begin
  GGame.NewGame;
  GGame.Refresh;
  MenuGame_CloseGame.Enabled := true;
  MenuGame_NewGame.Enabled := False;
end;

procedure TFormMain.MenuGame_ExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormMain.MenuGame_CloseGameClick(Sender: TObject);
begin
  if MessageBox(Self.Handle, 'Game is running, confirm to exit?', 'Confirm', MB_OKCANCEL or MB_DEFBUTTON2) = IDOK then
  begin
    GGame.CloseGame;
    MenuGame_NewGame.Enabled := True;
    MenuGame_CloseGame.Enabled := False;
  end;
end;

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  if GGame.IsPlaying then
    GGame.BlinkLastMove;
end;

end.