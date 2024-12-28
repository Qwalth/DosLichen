{ BSD 2-Clause License

Copyright (c) 2024, Qwalth, <catchthetortoise@yahoo.com>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. }

program lichen; { lichen.pas }
uses cthreads, ptcCrt, ptcGraph;
const
	DeathColor = $10;
    LifeColor = $2F;
    DeathChance = 8;
    {$IFDEF StatGrowth}
    SourcesCount = 16;
    CyclesMax = 16;
    {$ENDIF}

{$INCLUDE LichensColors.inc}
    
type
    { just for clarity }
    map = ^word;

    {$IFDEF StatGrowth}
    { I want sources of growth fixed while they're not ran out of cycles }
    pGrowthPlace = ^GrowthPlace;
    GrowthPlace = record
        pos: longword; { same type as size } 
        cycles: byte;
        next: pGrowthPlace;
    end;
    {$ENDIF}
var
	{ I made them global because they once 
      will be as lvalue and never more }
	MaxX, MaxY: word;
	size_of_map, size, AllPixels: longword;

{$IFDEF StatGrowth}
procedure NewPos(Grow: pGrowthPlace);
    { get new position if previous one ran out of cycles }
var
    place: longword;
begin
    place := Random(size);
    if place >= 6 then
        Grow^.pos := Random(size)
    else
        Grow^.pos := size div 2;
    Grow^.cycles := Random(CyclesMax)+1;
end;

procedure SetPos(var screen: map; Grow: pGrowthPlace);
    { start growing from these positions }
var
    GrowOrNot: byte;
begin
    while Grow <> nil do
    begin
        { too frequent growth isn't that beautiful }
        GrowOrNot := Random(128)+1;
        if (GrowOrNot = 128) and (Grow^.cycles <> 0) then
        begin
            { reminder: Growth() searches for LifeColor-1}
            screen[Grow^.pos] := LifeColor-1;
            { 1 growth cycle left }
            Grow^.cycles := Grow^.cycles-1
        end;
        { cycles over? }
        if Grow^.cycles = 0 then
            NewPos(Grow);
        Grow := Grow^.next
    end;
end;

procedure DeallocSources(Grow: pGrowthPlace);
    { free mem for sources }
var
    DummyPtr: pGrowthPlace;
begin
    DummyPtr := Grow;
    while Grow <> nil do
    begin
        { firstly, get ptr to next record }
        DummyPtr := Grow^.next;
        { dealloc }
        dispose(Grow);
        { Grow no more exist, we cannot Grow^.next anymore }
        Grow := DummyPtr;
    end;
end;
{$ELSE}
procedure SetRandPos(var screen: map);
var
    position: longword; { same type as size }
begin
    position := Random(size);
    { do not touch the first three londwords! 
      that is an order! }
    if position >= 6 then
        screen[position] := LifeColor-1; 
end;
{$ENDIF}

procedure ShowMap(var screen: map);
begin
	PutImage(0, 0, screen^, CopyPut);
end;

procedure DrawPixel(var screen: map; i: longword);
var
    way: byte;
begin
    { Randomly choose in which way to grow }
    way := Random(4);

    { Left }
	if (way = 0) and (i+1 < AllPixels) and (screen[i+1] = DeathColor) then
        screen[i+1] := LifeColor;

    { Right }
    if (way = 1) and (i-1 >= 6) and (screen[i-1] = DeathColor) then
		screen[i-1] := LifeColor;

    { Upper pixel }
    if (way = 2) and (i > MaxY) and (screen[i-MaxY] = DeathColor) then
		screen[i-MaxY] := LifeColor;

    { Bottom pixel }
    if (way = 3) and (i+MaxY < AllPixels) and (screen[i+MaxY] = DeathColor) then
		screen[i+MaxY] := LifeColor;
end;

procedure DrawPlus(var screen: map; i: longword);
begin
    { Left }
    if (i+1 < AllPixels) and (screen[i+1] = DeathColor) then
    	screen[i+1] := LifeColor;

    { Right }
    if (i-1 >= 6) and (screen[i-1] = DeathColor) then
	    screen[i-1] := LifeColor;

    { Upper pixel }
    if (i > MaxY) and (screen[i-MaxY] = DeathColor) then
	    screen[i-MaxY] := LifeColor;

    { Bottom pixel }
    if (i+MaxY < AllPixels) and (screen[i+MaxY] = DeathColor) then
	    screen[i+MaxY] := LifeColor;
end;

function CountNeighbors(var screen: map; i: longword): byte;
	{ This function counts how many DeathColor cells are nearby }
var
	countme: byte;
begin
    { Do not forget to initialize }
    countme := 0;
    
    { Left }
    if (i+1 < AllPixels) and (screen[i+1] = DeathColor) then
	    countme := countme + 1;

    { Right }
    if (i-1 >= 6) and (screen[i-1] = DeathColor) then
	    countme := countme + 1;

    { Upper pixel }
    if (i > MaxY) and (screen[i-MaxY] = DeathColor) then
	    countme := countme + 1;

    { Bottom pixel }
    if (i+MaxY < AllPixels) and (screen[i+MaxY] = DeathColor) then
	    countme := countme + 1;
 
    { Return count }
	CountNeighbors := countme
end;

procedure DecreaseLife(var screen: map; i: longword);
    { Randomly chooses: decrement or not a cell, which is alive }
var
    ChangeOrNot: byte;
begin
    if screen[i] > DeathColor then
    begin
        { this choose is the main feature of lichen }
        ChangeOrNot := Random(DeathChance)+1;
        if ChangeOrNot = 8 then
            screen[i] := screen[i]-1
    end;
end;

procedure Growth(var screen: map; i: longword);
begin
    if screen[i] = LifeColor-1 then
    begin
    { Two or less neighbors are nearby? }
	if CountNeighbors(screen, i) <= 2 then
        DrawPlus(screen, i)
	else
        DrawPixel(screen, i)
    end;
end;

procedure GrowthAndDeath(var screen: map);
var
    i: longword;
begin
    { Words from 0 to 5 are reserved }
    for i := 6 to size do
    begin
        { Here Lichen will grow }
        Growth(screen, i);
        { Slow death }
        DecreaseLife(screen, i)
    end;
end;

{$IFDEF StatGrowth}
procedure InitValues(Grow: pGrowthPlace);
var
    place: longword;
begin
    { get random position, but be aware of three reserved longwords }
    place := Random(size);
    if place >= 6 then
        Grow^.pos := Random(size)
    else
        Grow^.pos := size div 2;

    { how many cycles of growth }
    Grow^.cycles := Random(CyclesMax)+1;  
end;

procedure InitGrowthSources(var DummyPtr: pGrowthPlace);
    { all random }
var
    Grow: pGrowthPlace;
    HowMany: byte; { not too many sources }
begin
    HowMany := Random(SourcesCount)+1;
    { the first record is always pointing into abyss }
    DummyPtr := nil;
    while HowMany <> 0 do
    begin
        { allocate a new record }
        new(Grow);
        InitValues(Grow);
        { now point on previous record }
        Grow^.next := DummyPtr;
        { remember this record }
        DummyPtr := Grow;
        { loop must be finite, isn't it? }
        HowMany := HowMany-1
    end;
end;
{$ENDIF}

procedure InitMap(var screen: map);
var
    i: longword;
begin
    {
    Words from 0 to 5 reserved by BitMap}
    for i := 6 to size do
        screen[i] := DeathColor
end;

procedure Lichen(var screen: map);
	{ Lichen's life }
{$IFDEF StatGrowth}
var
    Grow: pGrowthPlace;
{$ENDIF}
begin
    { this size means amount of cells. because 
      each cell is a word in ptcGraph, bytes must be divided by two }
    size := size_of_map div 2;

    { fill field with death }
    InitMap(screen);
    {$IFDEF StatGrowth}
    InitGrowthSources(Grow);
    {$ENDIF}
    
    while not keyPressed do
    begin
    	{$IFDEF NoStatGrowth}
    	SetRandPos(screen);
    	{$ELSE}
    	SetPos(screen, Grow);
    	{$ENDIF}
      	GrowthAndDeath(screen);
        ShowMap(screen);
    end;
    {$IFDEF StatGrowth}
    DeallocSources(Grow)
    {$ENDIF}
end;

procedure GiveShape(var screen: map);
begin
    { size of the map in BYTES }
    size_of_map := ImageSize(0, 0, GetMaxX, GetMaxY);

    { Make life map exist }
    getmem(screen, size_of_map);
    if ReturnNilIfGrowHeapFails then
        halt(2);

    writeln('The required size for copying entire screen is ', size_of_map, ' bytes');
    { Copy entire screen in map }
    GetImage(0, 0, GetMaxX, GetMaxY, screen^)
end;

procedure ChangeColors(var screen: map);
var
    Register, i: byte;
begin
    Register := EntryReg;
    i := 1;
    while Register <> 0 do
    begin
        setRGBpalette(Register, Colors[i], Colors[i+1], Colors[i+2]);
        Register := Register-1;
        i := i+3
    end; 
end;

procedure GetRes();
	{ variables used here are global }
begin
	{ GetMaxX/Y are now usable }
	MaxY := GetMaxX+1;
	MaxX := GetMaxY+1;
	AllPixels := MaxY*MaxX;
end;

procedure ModeSearch(var ModeInfo: PModeInfo; var Driver, Mode: SmallInt);
    { obviously, just search }
var
    MaxAxisX: word;
    ModeName: string;
begin
     { only search for mode with VGA 256-colors palette 
       with maximum resolution }
     MaxAxisX := 0;
     while ModeInfo <> nil do
     begin
         if (ModeInfo^.MaxX > MaxAxisX) and (ModeInfo^.MaxColor = 256) then
         begin
             { remember Driver, Mode, resolution... }
             Driver := ModeInfo^.DriverNumber;
             Mode := ModeInfo^.ModeNumber;
             ModeName := ModeInfo^.ModeName;
             { remember new resolution }
             MaxAxisX := ModeInfo^.MaxX;
         end;
         { get next record describing another mode }
         ModeInfo := ModeInfo^.Next;
     end;
	 { set nesessary variables }
  	 writeln('Found: '+ModeName)
end;

procedure Init();
    { init graphical system }
var
    Driver, Mode: integer;
    ModeInfo: PModeInfo;
begin
    { Get pointer to record, describing graphical mode }
    ModeInfo := QueryAdapterInfo;
    if ModeInfo = nil then
    begin
        writeln('Error. Cannot receive videoadapter''s info.');
        halt(1)
    end
    else
        ModeSearch(ModeInfo, Driver, Mode);
    
    { if there is an error, program just crash lol }
    initGraph(Driver, Mode, '');
	{ so now we can get
	  physically nesessary variables: pixels per column and row }
	GetRes();
end;

var
    { The map itself }
    screen: map;
begin
    { Do not forget to randomize! }
    randomize();

    Init;

    ChangeColors(screen);
    GiveShape(screen);
    Lichen(screen);

    { do not forget to free allocated memory }
    freemem(screen, size);
    closeGraph
end.
