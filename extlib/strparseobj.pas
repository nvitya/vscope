(*-----------------------------------------------------------------------------
  This file is a part of the PASUTILS project: https://github.com/nvitya/pasutils
  Copyright (c) 2022 Viktor Nagy, nvitya

  This software is provided 'as-is', without any express or implied warranty.
  In no event will the authors be held liable for any damages arising from
  the use of this software. Permission is granted to anyone to use this
  software for any purpose, including commercial applications, and to alter
  it and redistribute it freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software in
     a product, an acknowledgment in the product documentation would be
     appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.

  3. This notice may not be removed or altered from any source distribution.
  --------------------------------------------------------------------------- */
   file:     strparseobj.pas
   brief:    Helper object for fast linear text parsing
   date:     2022-04-31
   authors:  nvitya
*)

unit strparseobj;

interface

type

  { TStrParseObj }

  TStrParseObj = object  // no heap needed to allocate
  public
    bufstart : PAnsiChar;
    bufend   : PAnsiChar;

    readptr  : PAnsiChar;    // current parsing position

    prevptr  : PAnsiChar;    // usually signs token start
    prevlen  : integer;  // usually signs token length

    commentmarker : AnsiChar;

    procedure Init(const astr : ansistring); overload;
    procedure Init(const buf; buflen : integer); overload;

    procedure SkipSpaces(skiplineend : boolean = true);
    procedure SkipWhite();

    function ReadLine() : boolean;  // sets prevptr, prevlen
    function ReadTo(const checkchars : ansistring) : boolean;  // sets prevptr, prevlen
    function ReadWhile(const checkchars : ansistring) : boolean;  // sets prevptr, prevlen
    function CheckSymbol(const checkstring : shortstring) : boolean;
    function SearchPattern(const checkstring : ansistring) : boolean;  // sets prevptr, prevlen
    function ReadToChar(const achar : ansichar) : boolean;  // sets prevptr, prevlen

    function ReadAlphaNum() : boolean;             // sets prevptr, prevlen
    function ReadIdentifier() : boolean;           // sets prevptr, prevlen
    function ReadQuotedString() : boolean;
    function ReadJsonFieldName() : boolean;

    function PrevStr() : ansistring;
    function UCComparePrev(const checkstring : shortstring) : boolean;
    function PrevToInt() : integer;
    function PrevHexToInt() : integer;

    function GetLineNum() : integer;
  end;

function PCharUCCompare(var ReadPtr : PAnsiChar; len : integer; const checkstring : shortstring) : boolean;
function PCharToInt(ReadPtr : PAnsiChar; len : integer) : integer;
function PCharHexToInt(ReadPtr : PAnsiChar; len : integer) : integer;

implementation

procedure TStrParseObj.Init(const astr : ansistring);
begin
  Init(astr[1], length(astr));
end;

procedure TStrParseObj.Init(const buf; buflen : integer);
begin
  bufstart := @buf;
  bufend := bufstart + buflen;
  ReadPtr := bufstart;
  prevptr := bufstart;
  prevlen := 0;
  commentmarker := '#';
end;

procedure TStrParseObj.SkipSpaces(skiplineend : boolean);
var
  cp : PAnsiChar;
begin
  cp := ReadPtr;
  while (cp < bufend) and ( (cp^ = #32) or (cp^ = #9) or (skiplineend and ((cp^ = #13) or (cp^ = #10))) ) do
  begin
    Inc(cp);
  end;
  ReadPtr := cp;
end;

procedure TStrParseObj.SkipWhite;
begin
  while true do
  begin
    SkipSpaces();
    if (readptr < bufend) and (readptr^ = commentmarker) then
    begin
      ReadTo(#10#13);
    end
    else
    begin
      exit;
    end;
  end;
end;

function TStrParseObj.ReadLine() : boolean;
// skips line end too, but LineLength does not contains the line end chars
// bufend shows the end of the buffer (one after the last character)
// so bufend-bufstart = buffer length
// returns false if end of buffer reached without line end
var
  cp : PAnsiChar;
begin
  prevptr := ReadPtr;
  cp := ReadPtr;
  result := (cp < bufend);

  while (cp < bufend) and not (cp^ in [#13,#10]) do
  begin
    Inc(cp);
  end;

  prevlen := cp - ReadPtr;

  // skip the line end, but only one!
  if (cp < bufend) and (cp^ = #13) then Inc(cp);
  if (cp < bufend) and (cp^ = #10) then Inc(cp);

  ReadPtr := cp;
end;

function TStrParseObj.ReadTo(const checkchars : ansistring) : boolean;
// reads until one of the checkchars reached.
var
  ccstart, ccend, ccptr : PAnsiChar;
  cp : PAnsiChar;
begin
  prevptr := ReadPtr;
  cp := ReadPtr;
  ccstart := @ checkchars[1];
  ccend := ccstart + length(checkchars);

  while cp < bufend do
  begin
    // check chars
    ccptr := ccstart;
    while ccptr < ccend do
    begin
      if ccptr^ = cp^ then
      begin
        result := true;
        prevlen := cp - ReadPtr;
        ReadPtr := cp;
        EXIT;
      end;
      Inc(ccptr);
    end;

    Inc(cp);
  end;

  result := false;
  prevlen := cp - ReadPtr;
  ReadPtr := cp;
end;

function TStrParseObj.ReadWhile(const checkchars : ansistring) : boolean;
// reads while the checkchars are found
var
  ccstart, ccend, ccptr : PAnsiChar;
  cp : PAnsiChar;
  //found : boolean;
label
  char_found;
begin
  prevptr := ReadPtr;
  cp := ReadPtr;
  ccstart := @ checkchars[1];
  ccend := ccstart + length(checkchars);
  //found := true;

  while cp < bufend do
  begin
    // check chars
    ccptr := ccstart;
    //found := false;
    while ccptr < ccend do
    begin
      if ccptr^ = cp^ then  // this is ours, check the next char
      begin
        goto char_found;
      end;
      Inc(ccptr);
    end;

    // char not found
    break;

char_found:
    Inc(cp);
  end;

  if 0 = (cp - ReadPtr) then
  begin
    result := false;
    prevlen := 0;
  end
  else
  begin
    prevlen := cp - ReadPtr;
    ReadPtr := cp;
    result := true;
  end;
end;

function TStrParseObj.SearchPattern(const checkstring : ansistring) : boolean;
// tries to find the checkstring
var
  pch, patch, strch, sch, patend : PAnsiChar;
  checkend : PAnsiChar;
begin
  Result := false;
  prevlen := 0;
  prevptr := ReadPtr;
  strch := ReadPtr;
  patch := @checkstring[1];
  patend := patch + length(checkstring);
  checkend := bufend - length(checkstring);  // last valid position

  while (strch <= checkend) do
  begin
    pch := patch;
    sch := strch;

    // try to find the first character
    while (sch <= checkend) and (pch^ <> sch^) do
    begin
      Inc(sch);
    end;

    if sch > checkend then Exit;

    strch := sch;

    Inc(pch);
    Inc(sch);

    while (pch < patend) and (pch^ = sch^) do
    begin
      Inc(pch);
      Inc(sch);
    end;

    if pch >= patend then
    begin
      prevlen := strch - ReadPtr;
      ReadPtr := sch; // point to behind the matchstring
      result := true;
      Exit;
    end;

    Inc(strch);
  end;
end;

function TStrParseObj.ReadToChar(const achar : ansichar) : boolean;
var
  cp : PAnsiChar;
begin
  result := false;
  prevptr := ReadPtr;
  cp := ReadPtr;

  while cp < bufend do
  begin
    if (cp^ = achar) then
    begin
      result := true;
      break;
    end;
    Inc(cp);
  end;
  prevlen := cp - ReadPtr;
  ReadPtr := cp;
end;

function TStrParseObj.CheckSymbol(const checkstring : shortstring) : boolean;
var
  cp, csend, csptr : PAnsiChar;
begin
  cp := ReadPtr;
  csptr := @ checkstring[1];
  csend := csptr + length(checkstring);
  while (csptr < csend) and (cp < bufend) and (csptr^ = cp^) do
  begin
    Inc(csptr);
    Inc(cp);
  end;

  if csptr = csend then
  begin
    result := true;
    ReadPtr := cp;
  end
  else
  begin
    result := false;
  end;
end;

function TStrParseObj.ReadAlphaNum() : boolean;
var
  cp : PAnsiChar;
  c : AnsiChar;
begin
  result := false;
  cp := ReadPtr;
  prevptr := ReadPtr;

  while cp < bufend do
  begin
    c := cp^;

    if ((c >= '0') and (c <= '9')) or ((c >= 'A') and (c <= 'Z')) or ((c >= 'a') and (c <= 'z'))
        or (c = '_')
        or ((c = '-') and (cp = readptr))  // sign: allowed only at the first character
    then
    begin
      result := true;
      Inc(cp);
    end
    else
    begin
      break;
    end;
  end;

  prevlen := cp - readptr;
  readptr := cp;
end;

function TStrParseObj.ReadIdentifier : boolean;
var
  cp : PAnsiChar;
  c : AnsiChar;
begin
  result := false;
  cp := ReadPtr;
  prevptr := ReadPtr;

  while cp < bufend do
  begin
    c := cp^;

    if ((c >= 'A') and (c <= 'Z')) or ((c >= 'a') and (c <= 'z'))
        or (c = '_')
        or ((cp <> readptr) and (c >= '0') and (c <= '9'))
    then
    begin
      result := true;
      Inc(cp);
    end
    else
    begin
      break;
    end;
  end;

  prevlen := cp - readptr;
  readptr := cp;
end;

function TStrParseObj.ReadJsonFieldName: boolean;
begin
  if CheckSymbol('"') then
  begin
    if not ReadToChar('"') then exit(false);
    CheckSymbol('"');
  end
  else
  begin
    if not ReadAlphaNum then exit(false);
  end;
  result := true;
end;

function TStrParseObj.ReadQuotedString() : boolean;
begin
  if readptr >= bufend then exit(false);

  if readptr^ <> '"' then exit(false);

  Inc(readptr);  // skip "

  ReadToChar('"'); // read to line end

  if (readptr < bufend) and (readptr^ = '"') then
  begin
    Inc(readptr);
  end;

  result := true;
end;


function TStrParseObj.PrevStr() : ansistring;
begin
{$HINTS OFF}
  SetLength(result, prevlen);
  if prevlen > 0 then Move(prevptr^, result[1], prevlen);
{$HINTS ON}
end;

function TStrParseObj.UCComparePrev(const checkstring : shortstring) : boolean;
begin
  result := PCharUCCompare(prevptr, prevlen, checkstring);
end;

function TStrParseObj.PrevToInt() : integer;
begin
  result := PCharToInt(prevptr, prevlen);
end;

function TStrParseObj.PrevHexToInt() : integer;
begin
  result := PCharHexToInt(prevptr, prevlen);
end;

function TStrParseObj.GetLineNum : integer;
var
  cp : PAnsiChar;
begin
  result := 1;
  cp := bufstart;
  while (cp < readptr) and (cp < bufend) do
  begin
    if cp^ = #10 then Inc(result);
    Inc(cp);
  end;
end;


function PCharUCCompare(var ReadPtr : PAnsiChar; len : integer; const checkstring : shortstring) : boolean;
var
  csend, csptr : PAnsiChar;
  cp, bufend : PAnsiChar;
  c : ansichar;
begin
  if len <> length(checkstring) then exit(false);

  cp := ReadPtr;
  bufend := cp + len;
  csptr := @ checkstring[1];
  csend := csptr + length(checkstring);

  while (csptr < csend) and (cp < bufend) do
  begin
    c := cp^;
    if c in ['a'..'z'] then c := AnsiChar(ord(c) and $DF);

    if c <> csptr^ then
    begin
      break;
    end;

    Inc(csptr);
    Inc(cp);
  end;

  if csptr = csend then
  begin
    result := true;
    ReadPtr := cp;
  end
  else
  begin
    result := false;
  end;
end;

function PCharToInt(ReadPtr : PAnsiChar; len : integer) : integer;
var
  cp, endp : PAnsiChar;
  num : int64;
begin
  cp := ReadPtr;
  endp := cp + len;
  num := 0;
  while cp < endp do
  begin
    num := num * 10 + ord(cp^) - ord('0');
    Inc(cp);
  end;
  result := integer(num and $FFFFFFFF);
end;

function PCharHexToInt(ReadPtr : PAnsiChar; len : integer) : integer;
var
  cp, endp : PAnsiChar;
  c : ansichar;
  num : int64;
begin
  cp := ReadPtr;
  endp := cp + len;
  num := 0;
  while cp < endp do
  begin
    c := cp^;
    if      c in ['0'..'9'] then num := (num shl 4) + ord(c) - ord('0')
    else if c in ['A'..'F'] then num := (num shl 4) + ord(c) - ord('A') + 10
    else if c in ['a'..'f'] then num := (num shl 4) + ord(c) - ord('a') + 10
    else
      break;

    Inc(cp);
  end;
  result := integer(num and $FFFFFFFF);
end;


end.
