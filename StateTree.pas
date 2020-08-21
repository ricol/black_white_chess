unit StateTree;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Generics.Defaults, Generics.Collections,
  Dialogs, Menus, ComCtrls, ExtCtrls, ToolWin, StdCtrls, Common, BoardGame, StateNode;

type
  TStateTree = class abstract
  private
    FTreeView: TTreeView;
    procedure SetTreeView(const Value: TTreeView);
  protected
    FListBox: TListBox;
    FCurrent: TStateNode;
    FHead: TStateNode;
    function getAllChildrenNodesForTheNode(node: TStateNode; LevelPriority: Boolean): TListOfNodes;
    procedure SetListBox(const Value: TListBox);
    procedure SetCurrent(const Value: TStateNode);
    procedure SetHead(const Value: TStateNode);
    procedure ReleaseNode(var node: TStateNode);
    procedure PrintNode(node: TStateNode; var list: TStringList); virtual; abstract;
    procedure PrintNodeToTreeView(node: TStateNode; var treeNode: TTreeNode; var treeList: TTreeNodes); virtual; abstract;
    procedure PrintRecursively(node: TStateNode; var list: TStringList);
    procedure PrintRecursivelyToTreeView(node: TStateNode; var treeNode: TTreeNode; var treeList: TTreeNodes);
    function getLevelInfor(listOfNodes: TListOfNodes): String;
  public
    constructor Create(var initialGame: TBoardGame);
    destructor Destroy(); override;
    property ListBox: TListBox read FListBox write SetListBox;
    property TreeView: TTreeView read FTreeView write SetTreeView;
    property Head: TStateNode read FHead write SetHead;
    property Current: TStateNode read FCurrent write SetCurrent;
    function getAllLeaves(LevelPriority: Boolean): TListOfNodes;
    function InsertTheNode(ValueForTheNode: TBoardGame; i, j: Integer; InsertUnderTheNode: TStateNode): TStateNode;
    function getAllNodes(LevelPriority: Boolean): TListOfNodes;
    procedure Print;
    procedure PrintToTreeView;
    class function getLevel(node: TStateNode): Integer;
  end;

implementation

{ TStateTree }

function CompareNodes(const node1, node2: TStateNode): Integer;
  var
  lvl1, lvl2: Integer;
begin
  lvl1 := TStateTree.getLevel(node1);
  lvl2 := TStateTree.getLevel(node2);
  result := lvl1 - lvl2;
end;

constructor TStateTree.Create(var initialGame: TBoardGame);
begin
  inherited Create();
  head := TStateNode.Create;
  head.data := initialGame;
  head.step_i := -1;
  head.step_j := -1;
  head.parentNode := nil;
  head.nextNodes := nil;
end;

destructor TStateTree.Destroy;
begin
  ReleaseNode(FHead);
  inherited;
end;

function TStateTree.getAllChildrenNodesForTheNode(node: TStateNode; LevelPriority: Boolean): TListOfNodes;
var
  i, j: Integer;
  nextNode: TListOfNodes;
  nodes: TListOfNodes;
  list: TListOfNodes;
begin
  if node <> nil then
  begin
    if LevelPriority then
    begin
      Result := getAllChildrenNodesForTheNode(node, False);
      Result.Sort(TComparer<TStateNode>.Construct(CompareNodes));
    end else begin
      nextNode := node.nextNodes;
      if nextNode <> nil then
      begin
        list := TList<TStateNode>.Create();
        list.Clear;
        for i := 0 to nextNode.Count - 1 do
        begin
          list.Add(nextNode[i]);  //add the current one to the list
          nodes := getAllChildrenNodesForTheNode(nextNode[i], LevelPriority);
          if nodes <> nil then
          begin
            //add all children nodes to the list
            for j := 0 to nodes.Count - 1 do
            begin
              list.Add(nodes[j]);
            end;
            FreeAndNil(nodes);
          end;
        end;
        Result := list;
        exit;
      end else begin
        result := TListOfNodes.Create;
        exit;
      end;
    end;
  end else begin
    result := TListOfNodes.Create;
    exit;
  end;
end;

function TStateTree.getAllLeaves(LevelPriority: Boolean): TListOfNodes;
var
  allNodes: TListOfNodes;
  i: Integer;
  node: TStateNode;
  nodes: TList<TStateNode>;
begin
  if head <> nil then
  begin
    allNodes := getAllNodes(LevelPriority);

//    OutputDebugString(PChar(getLevelInfor(tmpArray_AllNodes)));

    nodes := TList<TStateNode>.Create();
    for i := 0 to allNodes.Count - 1 do
    begin
      node := allNodes[i];
      if node.nextNodes = nil then
        nodes.Add(node);
    end;

//    OutputDebugString(PChar(getLevelInfor(tmpList)));

    FreeAndNil(allNodes);
    Result := nodes;
    Exit;
  end else begin
    result := TListOfNodes.Create;
    exit;
  end;
end;

function TStateTree.getAllNodes(LevelPriority: Boolean): TListOfNodes;
begin
  if head <> nil then
  begin
    Result := getAllChildrenNodesForTheNode(head, LevelPriority);
    Result.Insert(0, head);
    exit;
  end else
  begin
    result := TListOfNodes.Create;
    exit;
  end;
end;

function TStateTree.InsertTheNode(ValueForTheNode: TBoardGame; i, j: Integer; InsertUnderTheNode: TStateNode): TStateNode;
var
  nodeNew: TStateNode;
  nextNodes: TListOfNodes;
begin
  nodeNew := TStateNode.Create;
  nodeNew.parentNode := InsertUnderTheNode;
  nodeNew.data := ValueForTheNode;
  nodeNew.step_i := i;
  nodeNew.step_j := j;
  nodeNew.nextNodes := nil;

  nextNodes := InsertUnderTheNode.nextNodes;
  if nextNodes = nil then
    nextNodes := TListOfNodes.Create();
  nextNodes.Add(nodeNew);
  InsertUnderTheNode.nextNodes := nextNodes;
  Result := nodeNew;
end;

procedure TStateTree.Print;
var
  list: TStringList;
begin
  // Print the State Tree
  Exit;
  if not GShowStateTreeInfor then
    Exit;
  if Self.ListBox <> nil then
  begin
    Self.ListBox.Visible := False;
    Application.ProcessMessages;
    list := TStringList.Create;
    PrintRecursively(Head, list);
    Self.ListBox.Items.Clear;
    Self.ListBox.Items.AddStrings(list);
    OutputDebugString(PChar(Format('Print: %d nodes.', [list.Count])));
    FreeAndNil(list);
    Self.ListBox.Visible := True;
  end;
end;

procedure TStateTree.PrintRecursively(node: TStateNode; var list: TStringList);
var
  n: TStateNode;
  nextNodes: TListOfNodes;
  i: Integer;
begin
  if node <> nil then
  begin
    PrintNode(node, list);
    nextNodes := node.nextNodes;
    if nextNodes <> nil then
    begin
      for i := 0 to nextNodes.Count - 1 do
      begin
        n := nextNodes[i];
        PrintRecursively(n, list);
      end;
    end;
  end;
end;

procedure TStateTree.PrintToTreeView;
var
  node: TTreeNode;
  treeList: TTreeNodes;
begin
  TreeView.Items.Clear;
  // Print the State Tree
  if not GShowStateTreeInfor then
    Exit;
  if Self.TreeView <> nil then
  begin
    node := nil;
    Self.TreeView.Visible := False;
    Application.ProcessMessages;
    try
//      tmpTreeList := TTreeNodes.Create(Self.TreeView);
      treeList := Self.TreeView.Items;
      PrintRecursivelyToTreeView(Head, node, treeList);
//      Self.TreeView.Items := tmpTreeList;
    finally
//      FreeAndNil(tmpTreeList);
    end;

    TreeView.FullExpand;
    Self.TreeView.Visible := True;
  end;
end;

procedure TStateTree.PrintRecursivelyToTreeView(node: TStateNode; var treeNode: TTreeNode; var treeList: TTreeNodes);
var
  nextNodes: TListOfNodes;
  i: Integer;
  n: TStateNode;
begin
  if node <> nil then
  begin
    PrintNodeToTreeView(node, treeNode, treeList);
    nextNodes := node.nextNodes;
    if nextNodes <> nil then
    begin
      treeNode := treeList.AddChild(treeNode, '------');
      for i := 0 to nextNodes.Count - 1 do
      begin
        n := nextNodes[i];
        PrintRecursivelyToTreeView(n, treeNode, treeList);
      end;
      treeNode := treeNode.Parent;
    end;
  end;
end;

procedure TStateTree.ReleaseNode(var node: TStateNode);
var
  nextNodes: TListOfNodes;
  i: Integer;
  n: TStateNode;
begin
  if node <> nil then
  begin
    //release children nodes first
    nextNodes := node.nextNodes;
    if nextNodes <> nil then
    begin
      //release each child node one by one
      for i := 0 to nextNodes.Count - 1 do
      begin
        n := nextNodes[i];
        ReleaseNode(n);
      end;
      FreeAndNil(nextNodes);
      node.nextNodes := nil;
    end;
    FreeAndNil(node);
  end;
end;

class function TStateTree.getLevel(node: TStateNode): Integer;
var
  lvl: Integer;
  n: TStateNode;
begin
  lvl := 0;
  if node = nil then
  begin
    Result := -1;
    exit;
  end;
  n := node.parentNode;
  while n <> nil do
  begin
    inc(lvl);
    n := n.parentNode;
  end;
  Result := lvl;
end;

function TStateTree.getLevelInfor(listOfNodes: TListOfNodes): String;
var
  s: string;
  i: Integer;
  currentNode: TStateNode;
begin
  s := Format('(%d) - ', [listOfNodes.Count]);
  for i := 0 to listOfNodes.Count - 1 do
  begin
    currentNode := listOfNodes[i];
    s := s + Format('%d', [getLevel(currentNode)]);
  end;
  Result := s;
end;

procedure TStateTree.SetCurrent(const Value: TStateNode);
begin
  FCurrent := Value;
end;

procedure TStateTree.SetHead(const Value: TStateNode);
begin
  FHead := Value;
end;

procedure TStateTree.SetListBox(const Value: TListBox);
begin
  FListBox := Value;
end;

procedure TStateTree.SetTreeView(const Value: TTreeView);
begin
  FTreeView := Value;
end;

end.
