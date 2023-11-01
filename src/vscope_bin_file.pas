unit vscope_bin_file;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, vscope_data;

type

  { TVscopeBinRec }

  TVscopeBinRec = class
  public
    marker   :  char;
    len64bit :  cardinal;
    lenbytes :  cardinal;

    addinfo  : uint32;  // additional info right after the 4-byte record head

    startptr : PByte;
    dataptr  : PByte;

    function ReadRecord(aptr : PByte; aendptr : PByte) : boolean;
  end;


  { TVsBinFileChannel }

  TVsBinFileChannel = class
  public
    wd : TWaveData;
    fillpos   : cardinal;
    lastindex : integer;

    datalen   : byte;
    issigned  : boolean;
    isfloat   : boolean;

    constructor Create(awavedata : TWaveData);
  end;

  { TVscopeBinFile }

  TVscopeBinFile = class
  public
    filename  : string;

    fbuf      : array of byte;  // local buffer
    fbinfile  : File;
    fopened   : boolean;
    fbpos     : int64;
    blkpos    : integer;
    blklen    : uint32;
    blkend    : PByte;

    currec    : TVscopeBinRec;

    waves     : array of TVsBinFileChannel;
    wavecnt   : integer;

    // last F-Record:
    chcnt        : byte;
    sample_width : byte;
    chlist       : array of TVsBinFileChannel;

    constructor Create;
    destructor Destroy; override;

    procedure Open(afilename : string);
    procedure Close;

    procedure ClearWaves;
    procedure AddWave(awave : TWaveData);

    procedure LoadWaveData();

    function ReadNextBlock() : boolean;
    function NextRecord() : boolean;

    procedure ProcessFRecord();
    procedure ProcessDataRecord();

  end;

implementation

{ TVsBinFileChannel }

constructor TVsBinFileChannel.Create(awavedata : TWaveData);
begin
  wd := awavedata;
  SetLength(wd.data, 0);
  fillpos := 0;
  lastindex := 0;
  datalen := 0;
end;

{ TVscopeBinRec }

function TVscopeBinRec.ReadRecord(aptr : PByte; aendptr : PByte) : boolean;
begin
  if aptr + 8 > aendptr
  then
      EXIT(false);

  startptr   := aptr;
  marker     := PChar(startptr)^;
  len64bit   := PUint32(startptr)^ shr 8;
  lenbytes   := len64bit shl 3;
  addinfo    := PUint32(startptr + 4)^;
  dataptr    := startptr + 8;

  if aptr + lenbytes > aendptr
  then
      EXIT(false);

  result := (marker = 'J') or (marker = 'F') or (marker = 'D') or (marker = 'S');
end;

{ TVscopeBinFile }

constructor TVscopeBinFile.Create;
begin
  SetLength(fbuf, 256 * 1024); // allocate a static data buffer
  currec := TVscopeBinRec.Create;
  waves := [];
end;

destructor TVscopeBinFile.Destroy;
begin
  SetLength(fbuf, 0);
  currec.Free;
  inherited Destroy;
end;

function TVscopeBinFile.ReadNextBlock : boolean;
var
  rlen : integer;
  pu32 : PUint32;
begin
  result := false;

  System.Seek(fbinfile, fbpos);
  rlen := 0;
  BlockRead(fbinfile, fbuf[0], 8, rlen);

  // check for the 'VSBK' = $4B425356 marker
  pu32 := PUint32(@fbuf[0]);
  if pu32^ <> $4B425356 then // = 'VSBK' ?
  begin
    EXIT;
  end;

  // check block length
  inc(pu32);
  blklen := pu32^ shl 3; // get the length in bytes
  if (blklen > length(fbuf)) or (blklen < 16) then
  begin
    EXIT;
  end;

  System.Seek(fbinfile, fbpos); // go back to block begin again
  BlockRead(fbinfile, fbuf[0], blklen, rlen);
  if rlen <> blklen then
  begin
    EXIT;
  end;

  fbpos := FilePos(fbinfile); // update the file position for the next block

  blkend := @fbuf[blklen]; // mark the end

  currec.startptr := nil;
  result := NextRecord();

  result := true;
end;

function TVscopeBinFile.NextRecord : boolean;
begin
  if currec.startptr = nil then // get the first record
  begin
    result := currec.ReadRecord(@fbuf[8], blkend);
  end
  else
  begin
    result := currec.ReadRecord(currec.startptr + currec.lenbytes, blkend);
  end;
end;

procedure TVscopeBinFile.ProcessFRecord;
var
  pb  : PByte;
  i : integer;
  chidx  : byte;
  chtype : byte;
  ch : TVsBinFileChannel;
begin
  chcnt := (currec.addinfo and $FF);
  pb := currec.dataptr;
  chlist := [];
  sample_width := 0;
  for i := 0 to chcnt - 1 do
  begin
    chidx := (pb^ and $3F);
    inc(pb);
    chtype := pb^;
    inc(pb);

    // TODO: handle padding!

    if chidx >= wavecnt then raise EScopeData.Create('Invalid channel index: '+IntToStr(chidx));

    ch := waves[chidx];
    ch.datalen := chtype and $F;
    ch.issigned := ((chtype and $F0) = $10);
    ch.isfloat  := ((chtype and $F0) = $20);
    Insert(ch, chlist, length(chlist));

    sample_width += ch.datalen;
  end;
end;

procedure TVscopeBinFile.ProcessDataRecord;
var
  pb : PByte;
  swidth : byte;
  scnt : uint32;
  ch : TVsBinFileChannel;
  wd : TWaveData;
  //sample_id : int32;
  padding_bytes : byte;
  v : double;
begin
  swidth    := currec.addinfo and $FF;
  scnt      := PUint32(currec.dataptr)^;   // sample count
  //sample_id := Pint32(currec.dataptr + 4)^;
  pb        := currec.dataptr + 8;
  if pb + scnt * swidth > blkend
  then
      raise EScopeData.Create('D-Record data out of the block boundary');

  if swidth < sample_width
  then
      raise EScopeData.Create('D-Record sample width mismatch');

  padding_bytes := swidth - sample_width;

  while scnt > 0 do
  begin
    for ch in chlist do
    begin
      if ch.isfloat then
      begin
        if 8 = ch.datalen then v := PDouble(pb)^
                          else v := PSingle(pb)^;
      end
      else
      begin
        if ch.issigned then
        begin
          if      2 = ch.datalen then v := PInt16(pb)^
          else if 4 = ch.datalen then v := PInt32(pb)^
          else if 8 = ch.datalen then v := PInt64(pb)^
                                 else v := PInt8(pb)^
        end
        else
        begin
          if      2 = ch.datalen then v := PUInt16(pb)^
          else if 4 = ch.datalen then v := PUInt32(pb)^
          else if 8 = ch.datalen then v := PUInt64(pb)^
                                 else v := PUInt8(pb)^
        end;
      end;
      // store the value

      wd := ch.wd;
      if ch.fillpos >= length(wd.data) then
      begin
        if length(wd.data) = 0 then SetLength(wd.data, 1000000)  // start with one millione
                               else SetLength(wd.data, length(wd.data) * 2); // double it
      end;
      wd.data[ch.fillpos] := v;
      inc(ch.fillpos);

      pb += ch.datalen;
    end;
    pb += padding_bytes;
    dec(scnt);
  end; // while
end;

procedure TVscopeBinFile.Open(afilename : string);
begin
  System.Assign(fbinfile, afilename);
  Reset(fbinfile, 1);
  fopened := true;
  fbpos := FilePos(fbinfile);

  if not ReadNextBlock() then
  begin
    raise EScopeData.Create('Error reading the first binary block.');
  end;
end;

procedure TVscopeBinFile.Close;
begin
  if fopened then System.Close(fbinfile);
  fopened := false;
end;

procedure TVscopeBinFile.ClearWaves;
var
  bw : TVsBinFileChannel;
begin
  for bw in waves do bw.Free;
  waves := [];
  wavecnt := 0;
end;

procedure TVscopeBinFile.AddWave(awave : TWaveData);
var
  bw : TVsBinFileChannel;
begin
  bw := TVsBinFileChannel.Create(awave);
  Insert(bw, waves, length(waves)+1);
  wavecnt := length(waves);
end;

procedure TVscopeBinFile.LoadWaveData;
var
  ch : TVsBinFileChannel;
  wd : TWaveData;
begin
  while ReadNextBlock() do
  begin
    repeat
      if currec.marker = 'F' then
      begin
        ProcessFRecord();
        //raise EScopeData.Create('F-Record found, sample width: '+IntToStr(sample_width));
      end
      else if currec.marker = 'D' then
      begin
        ProcessDataRecord();
        //raise EScopeData.Create('D-Record processing is missing!');
      end
      else
      begin
        raise EScopeData.Create('Unknown record type: '+currec.marker);
      end;
    until not NextRecord();
  end; // while

  // data load finished, trim back the data
  for ch in waves do
  begin
    wd := ch.wd;
    if length(wd.data) <> ch.fillpos then SetLength(wd.data, ch.fillpos);
  end;

end;

end.

