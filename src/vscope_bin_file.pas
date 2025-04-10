unit vscope_bin_file;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, jsontools, vscope_data;

const
  bscope_block_marker = $4B425356; // = 'VSBK'

type

  { TVscopeBinRec }

  TVscopeBinRec = class
  public
    marker   : char;
    bytelen  : cardinal;
    maxbytes : cardinal;  // used only at writes

    addinfo  : uint32;  // additional info right after the 4-byte record head

    startptr : PByte;
    dataptr  : PByte;
    endptr   : PByte;

    function ReadRecord(aptr : PByte; aendptr : PByte) : boolean;
    function CreateRecord(aptr : PByte; amarker : char; abytes : cardinal; aaddinfo : uint32) : PByte;
    procedure SetByteLength(abytelength : cardinal);
    procedure SetAddInfo(aaddinfo : uint32);
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
    blklen    : uint32;  // in bytes
    blkend    : PByte;

    currec    : TVscopeBinRec;

    // full channel list
    channels     : array of TVsBinFileChannel;

    // last F-Record:
    fchcnt        : byte;
    fsample_width : byte;
    fchlist       : array of TVsBinFileChannel;

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

    procedure Save(afilename : string; jroot : TJsonNode);
    procedure BeginWrite(afilename : string; jroot : TJsonNode);
    function NewBlock(ablksize : cardinal) : PByte;
    procedure WriteCurBlock();

  end;

implementation

{ TVsBinFileChannel }

constructor TVsBinFileChannel.Create(awavedata : TWaveData);
begin
  wd := awavedata;
  //SetLength(wd.data, 0);
  fillpos := 0;
  lastindex := 0;
  datalen := 0;
end;

{ TVscopeBinRec }

function TVscopeBinRec.ReadRecord(aptr : PByte; aendptr : PByte) : boolean;
var
  len64bit : uint32;
begin
  if aptr + 8 > aendptr
  then
      EXIT(false);

  startptr   := aptr;
  marker     := PChar(startptr)^;
  len64bit   := PUint32(startptr)^ shr 8;
  bytelen    := len64bit shl 3;
  addinfo    := PUint32(startptr + 4)^;
  dataptr    := startptr + 8;

  if aptr + bytelen > aendptr
  then
      EXIT(false);

  result := (marker = 'J') or (marker = 'F') or (marker = 'D') or (marker = 'S');
end;

function TVscopeBinRec.CreateRecord(aptr : PByte; amarker : char; abytes : cardinal; aaddinfo : uint32) : PByte;
var
  pb : PByte;
  reclen : uint32;
begin
  startptr := aptr;
  marker   := amarker;
  reclen   := 8 + ((abytes + 7) and $FFFFFFF8);
  maxbytes := abytes;
  bytelen  := abytes;
  addinfo  := aaddinfo;

  pb := startptr;
  PUint32(pb + 0)^ := ord(marker) or ((reclen shr 3) shl 8);
  PUint32(pb + 4)^ := addinfo;
  result := pb + 8;
end;

procedure TVscopeBinRec.SetByteLength(abytelength : cardinal);
begin
  bytelen := abytelength;
  PUint32(startptr)^ := ord(marker) or ((bytelen shr 3) shl 8);
end;

procedure TVscopeBinRec.SetAddInfo(aaddinfo : uint32);
begin
  addinfo := aaddinfo;
  PUint32(startptr + 4)^ := addinfo;
end;

{ TVscopeBinFile }

constructor TVscopeBinFile.Create;
begin
  SetLength(fbuf, 128 * 1024); // allocate a static data buffer
  currec := TVscopeBinRec.Create;
  channels := [];
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
  if pu32^ <> bscope_block_marker then // = 'VSBK' ?
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
    result := currec.ReadRecord(currec.startptr + currec.bytelen, blkend);
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
  fchcnt := (currec.addinfo and $FF);
  pb := currec.dataptr;
  fchlist := [];
  fsample_width := 0;
  for i := 0 to fchcnt - 1 do
  begin
    chidx := (pb^ and $3F);
    inc(pb);
    chtype := pb^;
    inc(pb);

    // TODO: handle padding!

    if chidx >= length(channels) then raise EScopeData.Create('Invalid channel index: '+IntToStr(chidx));

    ch := channels[chidx];
    ch.datalen := chtype and $F;
    ch.issigned := ((chtype and $F0) = $10);
    ch.isfloat  := ((chtype and $F0) = $20);
    Insert(ch, fchlist, length(fchlist));

    ch.wd.bin_storage_type := chtype;  // store it for the next save

    fsample_width += ch.datalen;
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

  if swidth < fsample_width
  then
      raise EScopeData.Create('D-Record sample width mismatch');

  padding_bytes := swidth - fsample_width;

  while scnt > 0 do
  begin
    for ch in fchlist do
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
      wd.data[ch.fillpos] := v * wd.raw_data_scale;
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
  for bw in channels do bw.Free;
  channels := [];
end;

procedure TVscopeBinFile.AddWave(awave : TWaveData);
var
  bw : TVsBinFileChannel;
begin
  bw := TVsBinFileChannel.Create(awave);
  Insert(bw, channels, length(channels)+1);
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
        //raise EScopeData.Create('F-Record found, sample width: '+IntToStr(fsample_width));
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
  for ch in channels do
  begin
    wd := ch.wd;
    if length(wd.data) <> ch.fillpos then SetLength(wd.data, ch.fillpos);
  end;

end;

procedure TVscopeBinFile.BeginWrite(afilename : string; jroot : TJsonNode);
var
  s  : ansistring;
  pb : PByte;
begin
  blklen := 65536;  // use 64k Blocks

  System.Assign(fbinfile, afilename);
  Rewrite(fbinfile, 1);
  fopened := true;
  fbpos := FilePos(fbinfile);

  // write the J-Block (always the first)

  s := jroot.Value; // get a nice, formatted JSON
  if length(s) > blklen - 16
  then
      raise EScopeData.Create('JSON data too long: '+IntToStr(length(s)));

  pb := NewBlock(blklen);
  pb := currec.CreateRecord(pb, 'J', length(s), length(s));
  move(s[1], pb^, length(s));
  WriteCurBlock();
end;

procedure TVscopeBinFile.Save(afilename : string; jroot : TJsonNode);
var
  s  : ansistring;
  pb : PByte;
  wd : TWaveData;
  ch : TVsBinFileChannel;
  chidx : byte;
  wremaining  : integer;
  blkrembytes : integer;
  blksamples  : integer;
  smpidx, max_smpidx : integer;
  smpidx_offs : integer;
  v : double;
  vint  : int32;
  vuint : uint32;
begin

  BeginWrite(afilename, jroot);

  // write the data blocks
  chidx := 0;
  for ch in channels do
  begin
    wd := ch.wd;
    smpidx := 0;
    smpidx_offs := 0;  // does not matter here anymore

    ch.datalen  := wd.bin_storage_type and $F;
    ch.issigned := ((wd.bin_storage_type and $F0) = $10);
    ch.isfloat  := ((wd.bin_storage_type and $F0) = $20);

    wremaining := length(wd.data);
    while wremaining > 0 do
    begin
      pb := NewBlock(blklen);
      pb := currec.CreateRecord(pb, 'F', 2, 1);  // 2 bytes, 1 channel only

      pb^ := $C0 + chidx;
      pb += 1;
      pb^ := wd.bin_storage_type; // format: double
      pb += 1;

      pb += 6; // skip the padding up to the 64 bit

      // the D-Record has a 16 byte header

      blkrembytes := blkend - pb - 16;
      blksamples  := blkrembytes div ch.datalen;
      if blksamples > wremaining then blksamples := wremaining;

      pb := currec.CreateRecord(pb, 'D', blksamples * ch.datalen, ch.datalen);
      PUint32(pb + 0)^ := blksamples;
      PUint32(pb + 4)^ := smpidx - smpidx_offs;
      pb += 8;

      max_smpidx := smpidx + blksamples;
      while smpidx < max_smpidx do
      begin
        v := wd.data[smpidx] / wd.raw_data_scale;
        if ch.isfloat then
        begin
          if 8 = ch.datalen then PDouble(pb)^ := v
                            else PSingle(pb)^ := v;
        end
        else
        begin
          if ch.issigned then
          begin
            vint := round(v);
            if      2 = ch.datalen then PInt16(pb)^ := vint
            else if 4 = ch.datalen then PInt32(pb)^ := vint
            else if 8 = ch.datalen then PInt64(pb)^ := vint
                                   else PInt8(pb)^  := vint;
          end
          else
          begin
            vuint := round(v);
            if      2 = ch.datalen then PUInt16(pb)^ := vuint
            else if 4 = ch.datalen then PUInt32(pb)^ := vuint
            else if 8 = ch.datalen then PUInt64(pb)^ := vuint
                                   else PUInt8(pb)^  := vuint;
          end;
        end;
        pb += ch.datalen;
        inc(smpidx);
      end;

      //move(wd.data[smpidx], pb^, blksamples * ch.datalen);

      WriteCurBlock();

      wremaining -= blksamples;
    end;
    inc(chidx);
  end;

  Close;
end;

function TVscopeBinFile.NewBlock(ablksize : cardinal) : PByte;
var
  pb : PByte;
begin
  // add block header
  blklen := ablksize;
  pb := @fbuf[0];
  blkend := pb + blklen;

  PUint32(pb)^ := bscope_block_marker;
  pb += 4;
  PUint32(pb)^ := (blklen shr 3);
  pb += 4;

  FillChar(pb^, blklen - 8, 0);  // fill with zeroes

  result := pb;
end;

procedure TVscopeBinFile.WriteCurBlock;
begin
  BlockWrite(fbinfile, fbuf[0], blklen);
end;

end.

