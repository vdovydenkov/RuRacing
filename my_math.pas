unit my_math;

interface

type
  TCosTable=  array[0..359] of single;
  TSinTable=  array[0..359] of single;

var
  CosTbl:  TCosTable;
  SinTbl:  TSinTable;

implementation
uses math;

var
  I:  integer;

begin
for I:= 0 to 359 do
  CosTbl[I]:= Cos(DegToRad(I));

  for I:= 0 to 359 do
  SinTbl[I]:= Sin(DegToRad(I));
end. // End Of Unit
