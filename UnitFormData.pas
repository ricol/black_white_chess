unit UnitFormData;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TFormStateTreeData = class(TForm)
    ListBoxMain: TListBox;
    EditSearch: TEdit;
    btnNext: TButton;
    TreeViewMain: TTreeView;
    procedure btnNextClick(Sender: TObject);
    procedure EditSearchChange(Sender: TObject);
  private
    { Private declarations }
    currentMatch: Integer;
  public
    { Public declarations }
  end;

var
  FormStateTreeData: TFormStateTreeData;

implementation

{$R *.dfm}

procedure TFormStateTreeData.btnNextClick(Sender: TObject);
var
  s, item: string;
  i: Integer;
  bFound: Boolean;
begin
  s := EditSearch.Text;
  bFound := false;
  if s <> '' then
  begin
    for i := currentMatch + 1 to ListBoxMain.Items.Count - 1 do
    begin
      item := ListBoxMain.Items[i];
      if Pos(s, item) > 0 then
      begin
        ListBoxMain.ItemIndex := i;
        currentMatch := i;
        bFound := True;
        Break;
      end;
    end;
  end;

  if not bFound then
  begin
    currentMatch := 0;
    Beep;
  end;
end;

procedure TFormStateTreeData.EditSearchChange(Sender: TObject);
begin
  currentMatch := 0;
end;

end.
