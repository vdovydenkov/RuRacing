unit my_utils;

interface

const
  NumSplitter= ',';

procedure StrToInts(St:  string;var I1,I2,I3:  integer);
procedure StrToSingles(St:  string;var I1,I2,I3:  single);

implementation
uses SysUtils;

procedure StrToInts(St:  string;var I1,I2,I3:  integer);
var
  Posit:  byte;

begin
Posit:= Pos(NumSplitter,St);
if Posit= 0 then exit;
I1:= StrToInt(copy(St,1,Posit-1));
delete(St,1,Posit);

Posit:= Pos(NumSplitter,St);
if Posit= 0 then exit;
I2:= StrToInt(copy(St,1,Posit-1));
delete(St,1,Posit);

I3:= StrToInt(St);
end; // proc StrToInts

procedure StrToSingles(St:  string;var I1,I2,I3:  single);
var
  Posit:  byte;

begin
Posit:= Pos(NumSplitter,St);
if Posit= 0 then exit;
I1:= StrToInt(copy(St,1,Posit-1));
delete(St,1,Posit);

Posit:= Pos(NumSplitter,St);
if Posit= 0 then exit;
I2:= StrToInt(copy(St,1,Posit-1));
delete(St,1,Posit);

I3:= StrToInt(St);
end; // proc StrToSingles

end. // End Of Unit

