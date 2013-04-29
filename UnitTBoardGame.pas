unit UnitTBoardGame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ExtCtrls, ToolWin, UnitCommon;

type
  TBoardGame = class
  protected
    FLastTurn: TTurn;
    FIsTempGame: Boolean;
    FIsPlaying: Boolean;
    FSize: Integer;
    FPaintBox: TPaintBox;
    FLenX, FLenY: Integer;
    FBoard: TBoard;
    FSoundEffect_Regret: string;
    FSoundEffect_Win: string;
    FSoundEffect_Click: string;
    FBackgroundMusic: string;
    FSoundEffect_Lose: string;
    FSoundEffect_Draw: string;
    FBackgroundColor: TColor;
    FDifficulty: TDifficulties;
    procedure SetIsTempGame(const Value: Boolean);
    procedure SetBackgroundColor(const Value: TColor); virtual;
    procedure SetBackgroundMusic(const Value: string); virtual;
    procedure SetDifficulty(const Value: TDifficulties); virtual;
    procedure SetSoundEffect_Click(const Value: string); virtual;
    procedure SetSoundEffect_Draw(const Value: string); virtual;
    procedure SetSoundEffect_Lose(const Value: string); virtual;
    procedure SetSoundEffect_Regret(const Value: string); virtual;
    procedure SetSoundEffect_Win(const Value: string); virtual;
    procedure SetIsPlaying(const Value: Boolean); virtual;
  public
    constructor Create(PaintBox: TPaintBox; size: Integer; TempObject: Boolean); overload;virtual;
    constructor Create(boardGame: TBoardGame); overload; virtual;
    destructor Destroy(); override;
    property Difficulty: TDifficulties read FDifficulty write SetDifficulty;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor;
    property BackgroundMusic: string read FBackgroundMusic write SetBackgroundMusic;
    property SoundEffect_Click: string read FSoundEffect_Click write SetSoundEffect_Click;
    property SoundEffect_Regret: string read FSoundEffect_Regret write SetSoundEffect_Regret;
    property SoundEffect_Win: string read FSoundEffect_Win write SetSoundEffect_Win;
    property SoundEffect_Lose: string read FSoundEffect_Lose write SetSoundEffect_Lose;
    property SoundEffect_Draw: string read FSoundEffect_Draw write SetSoundEffect_Draw;
    property IsPlaying: Boolean read FIsPlaying write SetIsPlaying;
    property IsTempGame: Boolean read FIsTempGame write SetIsTempGame;
    property LastTurn: TTurn read FLastTurn;
    procedure SaveGame(); virtual; abstract;
    procedure LoadGame(); virtual; abstract;
    procedure Swap(); virtual; abstract;
  end;

implementation

{ TBoardGame }

constructor TBoardGame.Create(PaintBox: TPaintBox; size: Integer; TempObject: Boolean);
begin
  inherited Create();
  FSize := size;
  SetLength(Self.FBoard, 0, 0);
  SetLength(Self.FBoard, size, size);
  FSoundEffect_Lose := '';
  FSoundEffect_Draw := '';
  FSoundEffect_Win := '';
  FSoundEffect_Regret := '';
  FBackgroundMusic := '';
  FSoundEffect_Click := '';
  FBackgroundColor := COLOR_BACKGROUND;
  FDifficulty := DIFF_LOW;
  FIsTempGame := TempObject;
  FPaintBox := PaintBox;
  FLenX := PaintBox.ClientWidth div FSize;
  FLenY := PaintBox.ClientHeight div FSize;
end;

constructor TBoardGame.Create(boardGame: TBoardGame);
var
  i: Integer;
  j: Integer;
begin
  inherited Create();
  FIsTempGame := boardGame.FIsTempGame;
  FIsPlaying := boardGame.FIsPlaying;
  FSize := boardGame.FSize;
  FPaintBox := boardGame.FPaintBox;
  FLenX := boardGame.FLenX;
  FLenY := boardGame.FLenY;
  SetLength(Self.FBoard, 0, 0);
  SetLength(Self.FBoard, boardGame.FSize, boardGame.FSize);
  for i := 0 to FSize - 1 do
    for j := 0 to FSize - 1 do
      FBoard[i, j] := boardGame.FBoard[i, j];

  FSoundEffect_Lose := boardGame.FSoundEffect_Lose;
  FSoundEffect_Draw := boardGame.FSoundEffect_Draw;
  FSoundEffect_Win := boardGame.FSoundEffect_Win;
  FSoundEffect_Regret := boardGame.FSoundEffect_Regret;
  FBackgroundMusic := boardGame.FBackgroundMusic;
  FSoundEffect_Click := boardGame.FSoundEffect_Click;
  FBackgroundColor := boardGame.FBackgroundColor;
  FDifficulty := boardGame.FDifficulty;
end;

destructor TBoardGame.Destroy;
begin
  SetLength(Self.FBoard, 0, 0);
  inherited;
end;

procedure TBoardGame.SetBackgroundColor(const Value: TColor);
begin
  FBackgroundColor := Value;
end;

procedure TBoardGame.SetBackgroundMusic(const Value: string);
begin
  FBackgroundMusic := Value;
end;

procedure TBoardGame.SetDifficulty(const Value: TDifficulties);
begin
  FDifficulty := Value;
end;

procedure TBoardGame.SetIsPlaying(const Value: Boolean);
begin
  FIsPlaying := Value;
end;

procedure TBoardGame.SetIsTempGame(const Value: Boolean);
begin
  FIsTempGame := Value;
end;

procedure TBoardGame.SetSoundEffect_Click(const Value: string);
begin
  FSoundEffect_Click := Value;
end;

procedure TBoardGame.SetSoundEffect_Draw(const Value: string);
begin
  FSoundEffect_Draw := Value;
end;

procedure TBoardGame.SetSoundEffect_Lose(const Value: string);
begin
  FSoundEffect_Lose := Value;
end;

procedure TBoardGame.SetSoundEffect_Regret(const Value: string);
begin
  FSoundEffect_Regret := Value;
end;

procedure TBoardGame.SetSoundEffect_Win(const Value: string);
begin
  FSoundEffect_Win := Value;
end;

end.
