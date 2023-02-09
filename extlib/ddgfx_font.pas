unit ddgfx_font;

{$mode ObjFPC}{$H+}

interface

{$DEFINE DYNAMIC}

uses
  Classes, SysUtils, fgl, {$IFDEF DYNAMIC}freetypehdyn{$ELSE}freetypeh{$ENDIF};

type

  EFreeType = class(Exception);

  { TGlyphBitmap }

  TGlyphBitmap = class
  public
    charcode : UnicodeChar;

    x        : integer;
    y        : integer;
    width    : integer;
    height   : integer;
    data     : pbyte;
    advanceX : integer;

    bglyph   : PFT_BitmapGlyph;

    constructor Create(acharcode : UnicodeChar; aglyphbmp : PFT_BitmapGlyph);
    destructor Destroy; override;
  end;

  TFontFace = class;

  TGlyphBmpList = specialize TFPGMapObject<UnicodeChar, TGlyphBitmap>;

  { TSizedFont }

  TSizedFont = class
  public
    face : TFontFace;
    size : single;
    metrics : FT_Size_Metrics;

    glyph_list : TGlyphBmpList;

    constructor Create(aface : TFontFace; asize : single);
    destructor Destroy; override;

    function GetGlyphBmp(acharcode : UnicodeChar) : TGlyphBitmap;

    function TextWidth(atxt : UnicodeString) : integer;
    function Height : integer;
    function Ascender : integer;
    function Descender : integer;

    procedure RenderToAlphaBmp(atxt : UnicodeString; x,y : integer;
                               bmp : PByte; bmp_width, bmp_height : integer);
  end;

  TFontSizeList = specialize TFPGMapObject<single, TSizedFont>;

  { TFontFace }

  TFontFace = class
  private
    fface : PFT_Face;
    fcursize : single;

    procedure SetSize(asize : single);
  public
    size_list : TFontSizeList;

    name : string;

    constructor Create(aname : string; aface : PFT_Face);
    destructor Destroy; override;

    function GetSizedFont(asize : single) : TSizedFont;
  end;

  TFontFaceList = specialize TFPGMapObject<string, TFontFace>;

  { TFontManager }

  TFontManager = class
  private
    FTLib : PFT_Library;

  public
    SearchPath : string;
    face_list   : TFontFaceList;

    constructor Create;
    destructor Destroy; override;

    function GetFont(afilename : string) : TFontFace;
  end;

var
  fontmanager : TFontManager;

procedure InitFontManager;
procedure DoneFontManager;

implementation

procedure InitFontManager;
begin
  if fontmanager = nil then
  begin
    fontmanager := TFontManager.Create;
  end;
end;

procedure DoneFontManager;
begin
  if fontmanager <> nil then FreeAndNil(fontmanager);
end;

{ TGlyphBitmap }

constructor TGlyphBitmap.Create(acharcode : UnicodeChar; aglyphbmp : PFT_BitmapGlyph);
begin
  charcode := acharcode;
  bglyph := aglyphbmp;

  y := 1 - bglyph^.top;
  x := bglyph^.left;
  //width  := bglyph^.bitmap.width;
  width  := bglyph^.bitmap.pitch;
  height := bglyph^.bitmap.rows;
  data := bglyph^.bitmap.buffer;
  advanceX := (bglyph^.root.advance.x + 32767) shr 16;
end;

destructor TGlyphBitmap.Destroy;
begin
  FT_Done_Glyph(PFT_Glyph(bglyph));
  inherited;
end;

{ TSizedFont }

constructor TSizedFont.Create(aface : TFontFace; asize : single);
begin
  face := aface;
  size := asize;
  glyph_list := TGlyphBmpList.Create(true);

  metrics := face.fface^.size^.metrics;
end;

destructor TSizedFont.Destroy;
begin
  glyph_list.Free;
  inherited Destroy;
end;

function TSizedFont.GetGlyphBmp(acharcode : UnicodeChar) : TGlyphBitmap;
var
  gidx  : FT_UInt;
  pg : PFT_Glyph;
  pos : FT_Vector;

  r : integer;
begin
  if glyph_list.TryGetData(acharcode, result)
  then
      EXIT;

  result := nil;

  //writeln('rendering: ', acharcode);

  face.SetSize(size);

  pos.x := 0;
  pos.y := 0;

  gidx := FT_Get_Char_Index(face.fface, ord(acharcode));
  r := FT_Load_Glyph(face.fface, gidx, FT_LOAD_DEFAULT);
  if r <> 0
  then
      raise EFreeType.CreateFmt('Error loading glyph(%d): %d', [ord(acharcode), r]);

  try
    r := FT_Get_Glyph(face.fface^.glyph, pg);
    if r <> 0
    then
        raise EFreeType.CreateFmt('Error getting glyph(%d): %d', [ord(acharcode), r]);

    r := FT_Glyph_To_Bitmap(pg, FT_RENDER_MODE_NORMAL, @pos, true);
    if r <> 0
    then
        raise EFreeType.CreateFmt('Error rendering glyph(%d): %d', [ord(acharcode), r]);

  except
    FT_Done_Glyph(pg);
    raise;
  end;

  result := TGlyphBitmap.Create(acharcode, PFT_BitmapGlyph(pg));
  //result.advanceX := pos.x; // shr 6;
  glyph_list.Add(acharcode, result);
end;

function TSizedFont.TextWidth(atxt : UnicodeString) : integer;
var
  i  : integer;
  tx : integer;
  gbmp : TGlyphBitmap;
begin
  tx := 0;
  result := 0; // = maxx
  for i := 1 to length(atxt) do
  begin
    gbmp := GetGlyphBmp(atxt[i]);  // loads from the internal cache if it was requested already
    tx += gbmp.x;
    result := tx + gbmp.width;
    tx += gbmp.advanceX;
  end;
end;

procedure TSizedFont.RenderToAlphaBmp(atxt : UnicodeString; x, y : integer;
                                      bmp : PByte; bmp_width, bmp_height : integer);
var
  i : integer;
  pty, ptx : pbyte;
  pd : pbyte;
  tx, ty : integer;
  dx, dy : integer;
  w, h : integer;
  gbmp : TGlyphBitmap;
begin
  tx := x;
  ty := y + Ascender; // TODO: use the font's ascend

  for i := 1 to length(atxt) do
  begin
    gbmp := GetGlyphBmp(atxt[i]);  // loads from the internal cache if it was requested already

    for h := 0 to gbmp.height-1 do
    begin
      dy := ty + gbmp.y + h;
      if (dy >= 0) and (dy < bmp_height) then
      begin
        pty := bmp + bmp_width * dy;
        for w := 0 to gbmp.width-1 do
        begin
          dx := tx + gbmp.x + w;
          if (dx >= 0) and (dx < bmp_width) then
          begin
            ptx := pty + dx;
            pd := gbmp.data + h * gbmp.width + w;
            ptx^ := pd^;
          end;
        end;
      end;
    end;

    tx += gbmp.advanceX;
  end;
end;

function TSizedFont.Height : integer;
begin
  result := ((metrics.height + 63) shr 6);
end;

function TSizedFont.Ascender : integer;
begin
  result := ((metrics.ascender + 63) shr 6);
end;

function TSizedFont.Descender : integer;
begin
  result := -((metrics.descender + 63) shr 6);
end;

{ TFontFace }

procedure TFontFace.SetSize(asize : single);
var
  r : integer;
begin
  if fcursize = asize then EXIT;

  r := FT_Set_Char_Size(fface, round(asize * 64), round(asize * 64), 96, 96);
  if r <> 0
  then
      raise EFreeType.CreateFmt('Error setting font size: %d', [r]);

  fcursize := asize;
end;

constructor TFontFace.Create(aname : string; aface : PFT_Face);
begin
  name  := aname;
  fface := aface;
  fcursize := 0;
  size_list := TFontSizeList.Create(true);
end;

destructor TFontFace.Destroy;
begin
  size_list.Free;
  FT_Done_Face(fface);
  inherited Destroy;
end;

function TFontFace.GetSizedFont(asize : single) : TSizedFont;
begin
  if size_list.TryGetData(asize, result)
  then
      EXIT;

  SetSize(asize);
  result := TSizedFont.Create(self, asize);
  size_list.Add(asize, result);
end;

{ TFontManager }

constructor TFontManager.Create;
var
  r : integer;
begin
  face_list := TFontFaceList.Create(True);

  {$IFDEF DYNAMIC}
  if Pointer(FT_Init_FreeType) = nil then InitializeFreetype();
  {$ENDIF}
  r := FT_Init_FreeType(FTLib);
  if r <> 0 then
  begin
    FTLib := nil;
    raise EFreeType.CreateFmt('Error initializing FT Library: %d', [r]);
  end;

  {$if defined(Darwin)}
    SearchPath := '/Library/Fonts/';
  {$elseif defined(WINDOWS)}
    SearchPath := '';
  {$else}
    SearchPath := '/usr/share/fonts/truetype';
  {$endif}

end;

destructor TFontManager.Destroy;
begin
  face_list.Free;
  inherited Destroy;
end;

function TFontManager.GetFont(afilename : string) : TFontFace;
var
  pface : PFT_Face = nil;
  r : integer;
begin
  if face_list.TryGetData(afilename, result)
  then
      EXIT;

  result := nil;
  r := FT_New_Face(FTLib, PChar(afilename), 0, pface);
  if r <> 0
  then
      raise EFreeType.CreateFmt('Error opening font "%s": %d', [afilename, r]);

  result := TFontFace.Create(afilename, pface);
  face_list.Add(afilename, result);
end;

initialization
begin
  fontmanager := nil;
end;

end.

