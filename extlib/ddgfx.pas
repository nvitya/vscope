(* -----------------------------------------------------------------------------
 * This file is a part of the ddgfx project: https://github.com/nvitya/ddgfx
 * Copyright (c) 2022 Viktor Nagy, nvitya
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software. Permission is granted to anyone to use this
 * software for any purpose, including commercial applications, and to alter
 * it and redistribute it freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software in
 *    a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source distribution.
 * --------------------------------------------------------------------------- */
 *  file:     ddgfx.pas
 *  brief:    ddGfx main unit
 *  date:     2022-09-09
 *  authors:  nvitya
*)

unit ddgfx;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, dglOpenGL, OpenGLContext, ddgfx_font, util_nstime;

type
  TddFloat    = TGLfloat;
  TddMatrix   = array[0..5] of TddFloat;  // we leave out the trivial values from this
  TddMatrixGL = array[0..8] of TddFloat;  // GL requires the full matrix format

  TddColorUint = longword;
  TddColorGL = packed record
    r : TddFloat;
    g : TddFloat;
    b : TddFloat;
    a : TddFloat;
  end;


type
  TddVertex = array[0..1] of TddFloat;
  PddVertex = ^TddVertex;

type
  // short aliases
  TMatrix = TddMatrix;
  TMatrixGL = TddMatrixGL;
  TVertex = TddVertex;
  PVertex = PddVertex;
  TColorGL = TddColorGL;
  TColorUint = TddColorUint;
  PColorUint = ^TddColorUint;

type

  { TPrimitive }

  TPrimitive = class // a primitive that can be drawn by the OpenGL directly
  public
    drawmode  : GLint;  // GL_LINES, GL_LINESTRIP, GL_TRIANGLE_STRIP or GL_TRIANGLE_FAN
    vertices  : array of TVertex;
    vertexcount : integer;

    constructor Create(amode : GLint; avertexcount : integer; vertdata : PVertex);
    destructor Destroy; override;

    procedure Draw();

  protected
    vao      : TGLint;  // vertex array object
    vbo      : TGLint;  // vertex buffer object

    bufferok : boolean;

    procedure UpdateBuffer;
  end;

  { TShaderProgram }

  TShaderType = (stVertex, stFragment);

  TShaderProgram = class
  protected
    FPrgHandle : TGLint;
    FVSHandle : TGLint;
    FFSHandle : TGLint;

    procedure CompileShader(shadertype : TShaderType; const src : string);
    procedure LinkProgram;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure Activate;

    property PrgHandle : TGLint read FPrgHandle;
  end;

  { TShaderFixcolor }

  TShaderFixcolor = class(TShaderProgram)
  private
    Fu_MVPMatrix : TGLint;
    Fu_Color : TGLint;
  public
    constructor Create; override;

    procedure SetMVPMatrix(const mat : TMatrix);
    procedure SetColor(r,g,b,a : single); overload;
    procedure SetColor(const glc : TColorGL); overload;
  end;

  { TTextureShaderRgba }

  TTextureShaderRgba = class(TShaderProgram)
  private
    Fu_MVPMatrix : TGLint;
    Fu_Texture   : TGLint;
    Fu_Alpha     : TGLint;
  public
    constructor Create; override;

    procedure SetMVPMatrix(const mat : TMatrix);
    procedure SetTexture(atexid : GLint);
    procedure SetAlpha(aalpha : TddFloat);
  end;

  { TTextureShaderAlpha }

  TTextureShaderAlpha = class(TShaderProgram)
  private
    Fu_MVPMatrix : TGLint;
    Fu_Texture   : TGLint;
    Fu_Color : TGLint;
  public
    constructor Create; override;

    procedure SetMVPMatrix(const mat : TMatrix);
    procedure SetTexture(atexid : GLint);
    procedure SetColor(r,g,b,a : single); overload;
    procedure SetColor(const glc : TColorGL); overload;
  end;

  { TDrawable }

  TDrawGroup = class;

  TDrawable = class  // base of all the visual classes
  public
    parent   : TDrawGroup;

    x        : TddFloat;
    y        : TddFloat;
    scalex   : TddFloat;
    scaley   : TddFloat;
    rotation : TddFloat;
    alpha    : TddFloat;
    matrix   : TMatrix;
    visible  : boolean;

    constructor Create(aparent : TDrawGroup); virtual;
    destructor Destroy; override;

    procedure Draw(const apmatrix : TMatrix; aalpha : TddFloat); virtual; abstract;

    procedure CopyProperties(acopyfrom : TDrawable);

    procedure UpdateMatrix();

  end;

  { TShape }

  TShape = class(TDrawable)
  public
    color : TColorGL;  // white by default
    linewidth : TddFloat;
    primitives : array of TPrimitive;

    constructor Create(aparent : TDrawGroup); override;
    destructor Destroy; override;

    function AddPrimitive(amode : GLint; avertcount : integer; avertdata : PVertex) : TPrimitive;
    procedure Clear(); // removes all primitives

    procedure SetColor(r, g, b : TddFloat); overload;
    procedure SetColor(r, g, b, a : TddFloat); overload;

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;
  end;

  { TPixmap }

  TPixmap = class(TDrawable)
  protected
    texhandle : GLint;

    vao : TGLint;  // vertex array object
    vbo : array[0..1] of TGLint;  // vertex buffer objects: shape, texture

    procedure AllocateTexture;

  public
    width  : integer;
    height : integer;
    needsupdate : boolean;
    data   : PColorUint;

    constructor Create(aparent : TDrawGroup; awidth, aheight : integer); reintroduce;
    destructor Destroy; override;

    procedure Clear(acolor : TColorUint);

    procedure UpdateTexture;

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;

  end;

  { TAlphaMap }

  TAlphaMap = class(TDrawable)
  private
    function GetWidth : TddFloat;
    function GetHeight : TddFloat;
  protected
    texhandle : GLint;

    vao : TGLint;  // vertex array object
    vbo : array[0..1] of TGLint;  // vertex buffer objects: shape, texture

    fwidth        : integer;
    fheight       : integer;
    bmp_width     : integer;
    bmp_height    : integer;

    procedure AllocateTexture;

  public

    needsupdate : boolean;

    color : TColorGL;  // white by default

    data   : PByte;

    constructor Create(aparent : TDrawGroup; awidth, aheight : integer); reintroduce;
    destructor Destroy; override;

    procedure Clear(avalue : byte);

    procedure UpdateTexture;

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;

    procedure SetColor(r, g, b : TddFloat); overload;
    procedure SetColor(r, g, b, a : TddFloat); overload;

    procedure SetSize(awidth, aheight : integer);

    property BmpWidth  : integer  read bmp_width;
    property BmpHeight : integer  read bmp_height;
    property Width     : TddFloat read GetWidth;
    property Height    : TddFloat read GetHeight;

  end;


  { TTextBox }

  TTextBox = class(TAlphaMap)
  private
    procedure SetText(AValue : string);
  protected
    fsface : TSizedFont;

    ftext : string;
    frendertext : boolean;

    procedure DoRenderText;
  public

    constructor Create(aparent : TDrawGroup; afsace : TSizedFont; atext : string); reintroduce;
    destructor Destroy; override;

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;

    property Text : string read ftext write SetText;
    property Font : TSizedFont read fsface;
  end;

  { TClonedShape }

  TClonedShape = class(TDrawable)
  public
    original : TShape;
    color : TColorGL;  // white by default, overrides the originals color

    constructor Create(aparent : TDrawGroup; aoriginal : TShape); reintroduce;
    destructor Destroy; override;

    procedure SetColor(r, g, b : TddFloat); overload;
    procedure SetColor(r, g, b, a : TddFloat); overload;

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;
  end;

  TClonedGroup = class;

  { TDrawGroup }

  TDrawGroup = class(TDrawable)  // owns the children = frees them on destroy
  public
    children : array of TDrawable;

    constructor Create(aparent : TDrawGroup); override;
    destructor Destroy; override;

    procedure AddChild(adr : TDrawable);
    procedure RemoveChild(adr : TDrawable; afreeit : boolean);

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;


    function NewGroup : TDrawGroup;
    function NewShape : TShape;
    function NewPixmap(awidth, aheight : integer) : TPixmap;
    function CloneShape(aoriginal : TShape) : TClonedShape;
    function CloneGroup(aoriginal : TDrawGroup) : TClonedGroup;

    procedure MoveTo(aobj : TDrawable; topos : integer);
    procedure MoveTop(aobj : TDrawable);
    procedure MoveBottom(aobj : TDrawable);

    function FindIndex(aobj : TDrawable) : integer;

  end;

  { TClonedGroup }

  TClonedGroup = class(TDrawable)
  public
    original : TDrawGroup;

    constructor Create(aparent : TDrawGroup; aoriginal : TDrawGroup); reintroduce;
    destructor Destroy; override;

    procedure Draw(const apmatrix : TMatrix; apalpha : TddFloat); override;
  end;

  { TddScene }

  TddScene = class(TOpenGLControl) // scene root, add to the main window
  public // render stats
    render_time_ns : int64;
    swap_time_ns   : int64;
  public

    bgcolor : TColorGL;

    root : TDrawGroup;

    auto_swap_buffer : boolean;

    mat_projection : TMatrix;

    constructor Create(aowner : TComponent; aparent : TWinControl); virtual; reintroduce;
    destructor Destroy; override;

    procedure DoOnPaint; override;

  protected
    procedure DoOnResize; override;

    procedure SetViewPort(awidth, aheight : integer);

  end;



const
  ShaderTypeName : array[TShaderType] of string = ('vertex', 'fragment');

  SimpleTextureCoordinates : array[1..8] of single = (
    0, 0,
    1, 0,
    1, 1,
    0, 1
  );

  ddcolor_white : TddColorGL = (r:1; g:1; b:1; a:1);
  ddcolor_black : TddColorGL = (r:0; g:0; b:0; a:1);
  ddcolor_red   : TddColorGL = (r:1; g:0; b:0; a:1);
  ddcolor_green : TddColorGL = (r:0; g:1; b:0; a:1);
  ddcolor_blue  : TddColorGL = (r:0; g:0; b:1; a:1);

procedure ddmat_identity(out mat : TMatrix);
procedure ddmat_mul(out mat : TMatrix; const mat1, mat2 : TMatrix); overload; // ensure that mat <> mat1 !!!
procedure ddmat_mul(var mat : TMatrix; const mat2 : TMatrix); overload;

procedure ddmat_scale(var mat : TMatrix; const xscale, yscale : single);
procedure ddmat_translate(var mat : TMatrix; const x, y : single);
procedure ddmat_rotate(var mat : TMatrix; const alpha : single);

procedure ddmat_to_gl(out matout : TMatrixGL; const matin : TMatrix);
procedure ddmat_set_projection(out projmat : TMatrix; awidth, aheight : single);

var
  activeshader    : TShaderProgram;

  shader_fixcolor : TShaderFixcolor;
  texshader_rgba  : TTextureShaderRgba;
  texshader_alpha : TTextureShaderAlpha;

implementation

const
  attrloc_position = 0;
  attrloc_texcoordinate = 1;

procedure ddmat_identity(out mat : TMatrix);
begin
  mat[0] := 1;
  mat[1] := 0;
  mat[2] := 0;
  mat[3] := 1;
  mat[4] := 0;
  mat[5] := 0;
end;

procedure ddmat_mul(out mat : TMatrix; const mat1, mat2 : TMatrix); // ensure that mat <> mat1 !!!
begin
  mat[0] := mat1[0]*mat2[0] + mat1[1]*mat2[2];
  mat[1] := mat1[0]*mat2[1] + mat1[1]*mat2[3];

  mat[2] := mat1[2]*mat2[0] + mat1[3]*mat2[2];
  mat[3] := mat1[2]*mat2[1] + mat1[3]*mat2[3];

  mat[4] := mat1[4]*mat2[0] + mat1[5]*mat2[2] + mat2[4];
  mat[5] := mat1[4]*mat2[1] + mat1[5]*mat2[3] + mat2[5];
end;

procedure ddmat_mul(var mat : TMatrix; const mat2 : TMatrix);
var
  m0, m2, m4 : single;
begin
  m0 := mat[0];
  mat[0] := m0*mat2[0] + mat[1]*mat2[2];
  mat[1] := m0*mat2[1] + mat[1]*mat2[3];

  m2 := mat[2];
  mat[2] := m2*mat2[0] + mat[3]*mat2[2];
  mat[3] := m2*mat2[1] + mat[3]*mat2[3];

  m4 := mat[4];
  mat[4] := m4*mat2[0] + mat[5]*mat2[2] + mat2[4];
  mat[5] := m4*mat2[1] + mat[5]*mat2[3] + mat2[5];
end;

procedure ddmat_scale(var mat : TMatrix; const xscale, yscale : single);
begin
  mat[0] := mat[0]*xscale;
  mat[1] := mat[1]*yscale;
  mat[2] := mat[2]*xscale;
  mat[3] := mat[3]*yscale;
  mat[4] := mat[4]*xscale;
  mat[5] := mat[5]*yscale;
end;

procedure ddmat_translate(var mat : TMatrix; const x, y : single);
begin
  mat[4] := mat[4] + x;
  mat[5] := mat[5] + y;
end;

procedure ddmat_rotate(var mat : TMatrix; const alpha : single);
var
  cosa : single;
  sina : single;
  m0, m2, m4 : single;
begin
  cosa := cos(alpha);
  sina := sin(alpha);

  m0 := mat[0];
  mat[0] := m0*cosa + mat[1]*sina;
  mat[1] := m0*(-sina) + mat[1]*cosa;

  m2 := mat[2];
  mat[2] := m2*cosa + mat[3]*sina;
  mat[3] := m2*(-sina) + mat[3]*cosa;

  m4 := mat[4];
  mat[4] := m4*cosa + mat[5]*sina;
  mat[5] := m4*(-sina) + mat[5]*cosa;
end;

procedure ddmat_to_gl(out matout : TMatrixGL; const matin : TMatrix);
begin
  matout[0] := matin[0];
  matout[1] := matin[1];
  matout[2] := 0;

  matout[3] := matin[2];
  matout[4] := matin[3];
  matout[5] := 0;

  matout[6] := matin[4];
  matout[7] := matin[5];
  matout[8] := 1;
end;

procedure ddmat_set_projection(out projmat : TMatrix; awidth, aheight : single);
begin
  ddmat_identity(projmat);

  projmat[0] :=  2 / awidth;
  projmat[3] := -2 / aheight;

  projmat[4] := -1;  // translate x
  projmat[5] :=  1;  // translate y
end;

{ TShaderProgram }

constructor TShaderProgram.Create;
begin
  FVSHandle  := 0;
  FFSHandle  := 0;
  FPrgHandle := glCreateProgram();
  if FPrgHandle = 0 then raise Exception.Create('Could not create shader program');
end;

destructor TShaderProgram.Destroy;
begin
  if activeshader = self then activeshader := nil;

  if FVSHandle <> 0 then glDeleteShader(FVSHandle);
  if FFSHandle <> 0 then glDeleteShader(FFSHandle);
  if FPrgHandle <> 0 then glDeleteProgram(FPrgHandle);

  inherited Destroy;
end;

procedure TShaderProgram.CompileShader(shadertype : TShaderType; const src : string);
var
  i : GLint;
  psrc : PChar;
  len : TGLSizei;
  s : string;
  handle : GLint;
begin
  if shadertype = stVertex then
  begin
    handle := glCreateShader(GL_VERTEX_SHADER);
  end
  else
  begin
    handle := glCreateShader(GL_FRAGMENT_SHADER);
  end;

  if handle <= 0 then raise Exception.Create('Error creating '+ShaderTypeName[shadertype]+' shader');

  psrc := PChar(src);
  len := length(src);
  glShaderSource(handle, 1, @psrc, @len);
  glCompileShader(handle);
  glGetShaderiv(handle, GL_COMPILE_STATUS, @i);
  if i = 0 then
  begin
    len := 2048;
    s := '';  // to avoid old FPC warning
    SetLength(s, len);
    //glGetShaderInfoLog(result, length(errorstr), @len, @errorstr[1]);   // gles header difference!
    glGetShaderInfoLog(handle, length(s), @len, @s[1]);
    glDeleteShader(handle);

    raise Exception.create('Error compiling '+ShaderTypeName[shadertype]+' shader: '+s);
  end;

  if shadertype = stVertex then FVSHandle := handle
                           else FFSHandle := handle;

  glAttachShader(FPrgHandle, handle);
end;

procedure TShaderProgram.LinkProgram;
var
  i : integer;
  len : TGLSizei;
  s : string;
begin
  glLinkProgram(FPrgHandle);
  glGetProgramiv(FPrgHandle, GL_LINK_STATUS, @i);
  if i = 0 then
  begin
    len := 2048;
    s := '';
    SetLength(s, len);  // to avoid old FPC warning

    //glGetShaderInfoLog(result, length(s), @len, @s[1]);    // gles header difference!
    glGetShaderInfoLog(FPrgHandle, length(s), @len, @s[1]);
    glDeleteProgram(FPrgHandle);
    FPrgHandle := 0;
    raise Exception.Create('Error linking shader program: ' + s);
  end;
end;

procedure TShaderProgram.Activate;
begin
  glUseProgram(FPrgHandle);
  activeshader := self;
end;

{ TShaderFixcolor }

constructor TShaderFixcolor.Create;
begin
  inherited;

  CompileShader(stVertex,
     'uniform mat3 u_MVPMatrix;' + #10
   + 'attribute vec2 a_Position;' + #10
   + 'void main()' + #10
   + '{' + #10
   + '  gl_Position = vec4(u_MVPMatrix * vec3(a_Position, 1.0), 1.0);' + #10
   + '}' + #10
  );

  CompileShader(stFragment, ''
   {$ifdef ANDROID} +'precision mediump float;' + #10  {$endif}
   + 'uniform vec4 u_Color;' + #10
   + 'void main()' + #10
   + '{' + #10
   + '  gl_FragColor = u_Color;' + #10
   + '}' + #10
  );

  glBindAttribLocation(FPrgHandle, attrloc_position, 'a_Position');

  LinkProgram;

  Fu_MVPMatrix := glGetUniformLocation(FPrgHandle, 'u_MVPMatrix');
  Fu_Color := glGetUniformLocation(FPrgHandle, 'u_Color');
end;

procedure TShaderFixcolor.SetMVPMatrix(const mat : TMatrix);
var
  matgl : TMatrixGL;
begin
  ddmat_to_gl(matgl, mat);
  glUniformMatrix3fv(Fu_MVPMatrix, 1, false, @matgl);   // gles header difference!
end;

procedure TShaderFixcolor.SetColor(r, g, b, a : single);
begin
  glUniform4f(Fu_Color, r, g, b, a);
end;

procedure TShaderFixcolor.SetColor(const glc: TColorGL);
begin
  SetColor(glc.r, glc.g, glc.b, glc.a);
end;

{ TTextureShaderRgba }

constructor TTextureShaderRgba.Create;
begin
  inherited;

  CompileShader(stVertex,
     'uniform mat3 u_MVPMatrix;' + #10
   + 'attribute vec2 a_Position;' + #10
   + 'attribute vec2 a_TexCoordinate;' + #10
   + 'varying vec2 v_TexCoordinate;' + #10
   + 'void main()' + #10
   + '{' + #10
   + '  v_TexCoordinate = a_TexCoordinate;' + #10
   + '  gl_Position = vec4(u_MVPMatrix * vec3(a_Position, 1.0), 1.0);' + #10
   + '}' + #10
  );

  CompileShader(stFragment, ''
  {$ifdef ANDROID} +'precision mediump float;' + #10  {$endif}
   + 'uniform sampler2D u_Texture;' + #10
   + 'uniform float u_Alpha;' + #10
   + 'varying vec2 v_TexCoordinate;' + #10
   + 'void main()' + #10
   + '{' + #10
   + '  gl_FragColor = (texture2D(u_Texture, v_TexCoordinate));' + #10
   + '  gl_FragColor[3] = gl_FragColor[3] * u_Alpha;' + #10
   + '}' + #10
  );

  glBindAttribLocation(FPrgHandle, attrloc_position, 'a_Position');
  glBindAttribLocation(FPrgHandle, attrloc_texcoordinate, 'a_TexCoordinate');

  LinkProgram;

  Fu_MVPMatrix := glGetUniformLocation(FPrgHandle, 'u_MVPMatrix');
  Fu_Texture := glGetUniformLocation(FPrgHandle, 'u_Texture');
  Fu_Alpha := glGetUniformLocation(FPrgHandle, 'u_Alpha');
end;

procedure TTextureShaderRgba.SetMVPMatrix(const mat : TMatrix);
var
  matgl : TMatrixGL;
begin
  ddmat_to_gl(matgl, mat);
  glUniformMatrix3fv(Fu_MVPMatrix, 1, false, @matgl);
end;

procedure TTextureShaderRgba.SetTexture(atexid : GLint);
begin
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, atexid);
  glUniform1i(Fu_Texture, 0);
end;

procedure TTextureShaderRgba.SetAlpha(aalpha : TddFloat);
begin
  glUniform1f(Fu_Alpha, aalpha);
end;

{ TTextureShaderAlpha }


constructor TTextureShaderAlpha.Create;
begin
  inherited;

  CompileShader(stVertex,
     'uniform mat3 u_MVPMatrix;' + #10
   + 'attribute vec2 a_Position;' + #10
   + 'attribute vec2 a_TexCoordinate;' + #10
   + 'varying vec2 v_TexCoordinate;' + #10
   + 'void main()' + #10
   + '{' + #10
   + '  v_TexCoordinate = a_TexCoordinate;' + #10
   + '  gl_Position = vec4(u_MVPMatrix * vec3(a_Position, 1.0), 1.0);' + #10
   + '}' + #10
  );

  CompileShader(stFragment, ''
  {$ifdef ANDROID} +'precision mediump float;' + #10  {$endif}
   + 'uniform sampler2D u_Texture;' + #10
   + 'uniform vec4 u_Color;' + #10
   + 'varying vec2 v_TexCoordinate;' + #10
   + 'void main()' + #10
   + '{' + #10
   + '  gl_FragColor = u_Color;' + #10
   + '  gl_FragColor[3] = gl_FragColor[3] * texture2D(u_Texture, v_TexCoordinate).r;' + #10
   + '}' + #10
  );

  glBindAttribLocation(FPrgHandle, attrloc_position, 'a_Position');
  glBindAttribLocation(FPrgHandle, attrloc_texcoordinate, 'a_TexCoordinate');

  LinkProgram;

  Fu_MVPMatrix := glGetUniformLocation(FPrgHandle, 'u_MVPMatrix');
  Fu_Texture   := glGetUniformLocation(FPrgHandle, 'u_Texture');
  Fu_Color     := glGetUniformLocation(FPrgHandle, 'u_Color');
end;

procedure TTextureShaderAlpha.SetMVPMatrix(const mat : TMatrix);
var
  matgl : TMatrixGL;
begin
  ddmat_to_gl(matgl, mat);
  glUniformMatrix3fv(Fu_MVPMatrix, 1, false, @matgl);
end;

procedure TTextureShaderAlpha.SetTexture(atexid : GLint);
begin
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, atexid);
  glUniform1i(Fu_Texture, 0);
end;

procedure TTextureShaderAlpha.SetColor(r, g, b, a : single);
begin
  glUniform4f(Fu_Color, r, g, b, a);
end;

procedure TTextureShaderAlpha.SetColor(const glc: TColorGL);
begin
  SetColor(glc.r, glc.g, glc.b, glc.a);
end;


{ TPrimitive }

constructor TPrimitive.Create(amode : GLint; avertexcount : integer; vertdata : PVertex);
begin
  drawmode := amode;
  vertexcount := avertexcount;
  SetLength(vertices, vertexcount);
  if (vertexcount > 0) and (vertdata <> nil) then
  begin
    Move(vertdata^, vertices[0], vertexcount * sizeof(TVertex));
  end;
  vao := -1;
  vbo := -1;
  bufferok := false;
end;

destructor TPrimitive.Destroy;
begin
  if vao >= 0 then glDeleteVertexArrays(1, @vao);
  if vbo >= 0 then glDeleteBuffers(1, @vbo);
  SetLength(vertices, 0);

  inherited Destroy;
end;

procedure TPrimitive.Draw;
begin
  if not bufferok then UpdateBuffer();

  glBindVertexArray(vao);
  glDrawArrays(drawmode, 0, vertexcount); // * 2);
end;

procedure TPrimitive.UpdateBuffer;
begin
  if vao < 0 then
  begin
    glGenVertexArrays(1, @vao);
    glGenBuffers(1, @vbo);
  end;

  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  glBufferData(GL_ARRAY_BUFFER, vertexcount * sizeof(TVertex), @vertices[0], GL_STATIC_DRAW);
  glEnableVertexAttribArray(attrloc_position);
  glVertexAttribPointer(attrloc_position, 2, GL_FLOAT, false, 0, nil);

  bufferok := true;
end;

{ TDrawable }

constructor TDrawable.Create(aparent : TDrawGroup);
begin
  parent := aparent;
  if parent <> nil then parent.AddChild(self)
                   else parent := nil;
  x := 0;
  y := 0;
  scalex := 1;
  scaley := 1;
  rotation := 0;
  alpha := 1;
  visible := true;
end;

destructor TDrawable.Destroy;
begin
  if parent <> nil then parent.RemoveChild(self, False);
  inherited Destroy;
end;

procedure TDrawable.CopyProperties(acopyfrom : TDrawable);
begin
  x := acopyfrom.x;
  y := acopyfrom.y;
  scalex := acopyfrom.scalex;
  scaley := acopyfrom.scaley;
  rotation := acopyfrom.rotation;
  alpha := acopyfrom.alpha;
  visible := acopyfrom.visible;
end;

procedure TDrawable.UpdateMatrix;
var
  cosfi, sinfi : TddFloat;
begin
  cosfi := cos(PI * rotation / 180);
  sinfi := sin(PI * rotation / 180);

  matrix[0] := scalex * cosfi;
  matrix[1] := - sinfi * scaley;

  matrix[2] := sinfi * scalex;
  matrix[3] := scaley * cosfi;

  matrix[4] := x;
  matrix[5] := y;
end;

{ TShape }

constructor TShape.Create(aparent : TDrawGroup);
begin
  inherited Create(aparent);

  color := ddcolor_white;  // white is the default color
  linewidth := 1;

  SetLength(primitives, 0);
end;

destructor TShape.Destroy;
begin
  Clear;
  inherited Destroy;
end;

function TShape.AddPrimitive(amode : GLint; avertcount : integer; avertdata : PVertex) : TPrimitive;
begin
  result := TPrimitive.Create(amode, avertcount, avertdata);

  SetLength(primitives, length(primitives) + 1);
  primitives[length(primitives) - 1] := result;
end;

procedure TShape.Clear;
var
  p : TPrimitive;
begin
  for p in primitives do p.Free;
  SetLength(primitives, 0);
end;

procedure TShape.SetColor(r, g, b : TddFloat);
begin
  color.r := r;
  color.b := b;
  color.g := g;
  color.a := 1;
end;

procedure TShape.SetColor(r, g, b, a : TddFloat);
begin
  color.r := r;
  color.b := b;
  color.g := g;
  color.a := a;
end;

procedure TShape.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
var
  rmatrix : TMatrix;
  ralpha  : TddFloat;
  dprim   : TPrimitive;
begin
  UpdateMatrix();  // calculates self.matrix from scale[xy], rotation, +[xy]

  // calculate rmatrix, ralpha
  ddmat_mul(rmatrix, self.matrix, apmatrix);
  ralpha := apalpha * self.alpha;

  // select the proper shader for shape drawing:
  shader_fixcolor.Activate();

  // pass the matrix to the shader
  shader_fixcolor.SetMVPMatrix(rmatrix);
  shader_fixcolor.SetColor(color.r, color.g, color.b, color.a * ralpha);

  glLineWidth(linewidth);

  for dprim in primitives do
  begin
    dprim.Draw();
  end;
end;

{ TClonedShape }

constructor TClonedShape.Create(aparent : TDrawGroup; aoriginal : TShape);
begin
  inherited Create(aparent);

  original := aoriginal;
  if original <> nil then
  begin
    // copy the original color
    color := original.color;
    CopyProperties(original);
  end;
end;

destructor TClonedShape.Destroy;
begin
  inherited Destroy;
end;

procedure TClonedShape.SetColor(r, g, b : TddFloat);
begin
  color.r := r;
  color.b := b;
  color.g := g;
  color.a := 1;
end;

procedure TClonedShape.SetColor(r, g, b, a : TddFloat);
begin
  color.r := r;
  color.b := b;
  color.g := g;
  color.a := a;
end;

procedure TClonedShape.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
var
  rmatrix : TMatrix;
  ralpha  : TddFloat;
  dprim   : TPrimitive;
begin
  UpdateMatrix();  // calculates self.matrix from scale[xy], rotation, +[xy]

  // calculate rmatrix, ralpha
  ddmat_mul(rmatrix, self.matrix, apmatrix);
  ralpha := apalpha * self.alpha;

  // select the proper shader for shape drawing:
  shader_fixcolor.Activate();

  // pass the matrix to the shader
  shader_fixcolor.SetMVPMatrix(rmatrix);
  shader_fixcolor.SetColor(color.r, color.g, color.b, color.a * ralpha);

  for dprim in original.primitives do
  begin
    dprim.Draw();
  end;
end;

{ TPixmap }

constructor TPixmap.Create(aparent : TDrawGroup; awidth, aheight : integer);
begin
  inherited Create(aparent);

  texhandle := 0;
  needsupdate := true;
  width := awidth;
  height := aheight;
  vao := -1;
  vbo[0] := -1;
  vbo[1] := -1;

  GetMem(data, width * height * 4);
end;

destructor TPixmap.Destroy;
begin
  if vao >= 0 then
  begin
    glDeleteVertexArrays(1, @vao);
    glDeleteBuffers(2, @vbo);
  end;

  if texhandle <> 0 then glDeleteTextures(1, @texhandle);
  FreeMem(data);
  inherited;
end;

procedure TPixmap.AllocateTexture;
var
  framevert  : array[0..3] of TVertex;
  txtvert    : array[0..3] of TVertex;
begin
  if texhandle <> 0 then Exit;

  glGenTextures(1, @texhandle);

  glBindTexture(GL_TEXTURE_2D, texhandle);

  {$if 1}
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  {$else}
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  {$endif}


  glGenVertexArrays(1, @vao);
  glGenBuffers(2, @vbo);

  framevert[0][0] := 0;
  framevert[0][1] := 0;
  framevert[1][0] := width - 1;
  framevert[1][1] := 0;
  framevert[2][0] := width - 1;
  framevert[2][1] := height - 1;
  framevert[3][0] := 0;
  framevert[3][1] := height - 1;

  glBindVertexArray(vao);

  glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
  glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(TVertex), @framevert[0], GL_STATIC_DRAW);
  glEnableVertexAttribArray(attrloc_position);
  glVertexAttribPointer(attrloc_position, 2, GL_FLOAT, false, 0, nil);

  txtvert[0][0] := 0;
  txtvert[0][1] := 0;
  txtvert[1][0] := 1;
  txtvert[1][1] := 0;
  txtvert[2][0] := 1;
  txtvert[2][1] := 1;
  txtvert[3][0] := 0;
  txtvert[3][1] := 1;

  glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
  glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(TVertex), @txtvert[0], GL_STATIC_DRAW);
  glEnableVertexAttribArray(attrloc_texcoordinate);
  glVertexAttribPointer(attrloc_texcoordinate, 2, GL_FLOAT, false, 0, nil);

end;

procedure TPixmap.Clear(acolor : TColorUint);
begin
  if data = nil then EXIT;
  FillDWord(data^, width * height, acolor);
  needsupdate := true;
end;

procedure TPixmap.UpdateTexture;
begin
  if texhandle = 0 then AllocateTexture;

  glBindTexture(GL_TEXTURE_2D, texhandle);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

  needsupdate := false;
end;

procedure TPixmap.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
var
  rmatrix : TMatrix;
  ralpha  : TddFloat;

begin
  UpdateMatrix();  // calculates self.matrix from scale[xy], rotation, +[xy]

  // calculate rmatrix, ralpha
  ddmat_mul(rmatrix, self.matrix, apmatrix);
  ralpha := apalpha * self.alpha;

  // select the proper shader for texture drawing:
  texshader_rgba.Activate();

  // pass the matrix to the shader
  texshader_rgba.SetMVPMatrix(rmatrix);
  texshader_rgba.SetTexture(texhandle); //SetColor(color.r, color.g, color.b, color.a * ralpha);
  texshader_rgba.SetAlpha(ralpha);

  if needsupdate then UpdateTexture;


  glBindVertexArray(vao);
  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

end;

{ TAlphaMap }

constructor TAlphaMap.Create(aparent : TDrawGroup; awidth, aheight : integer);
begin
  inherited Create(aparent);

  texhandle := 0;
  needsupdate := true;

  color := ddcolor_white;

  vao := -1;
  vbo[0] := -1;
  vbo[1] := -1;

  fwidth := -1;
  bmp_width := -1;
  fheight := -1;
  bmp_height := -1;

  data := nil;

  SetSize(awidth, aheight);
  Clear(0);
end;

destructor TAlphaMap.Destroy;
begin
  if vao >= 0 then
  begin
    glDeleteVertexArrays(1, @vao);
    glDeleteBuffers(2, @vbo);
  end;

  if texhandle <> 0 then glDeleteTextures(1, @texhandle);
  FreeMem(data);
  inherited;
end;

function TAlphaMap.GetHeight : TddFloat;
begin
  result := fheight * scaley;
end;

function TAlphaMap.GetWidth : TddFloat;
begin
  result := fwidth * scalex;
end;

procedure TAlphaMap.AllocateTexture;
begin
  if texhandle <> 0 then Exit;

  glGenTextures(1, @texhandle);

  glBindTexture(GL_TEXTURE_2D, texhandle);

  glGenVertexArrays(1, @vao);
  glGenBuffers(2, @vbo);
end;

procedure TAlphaMap.Clear(avalue : byte);
begin
  if data = nil then EXIT;

  FillByte(data^, bmp_width * bmp_height, avalue);
  needsupdate := true;
end;

procedure TAlphaMap.UpdateTexture;
var
  framevert  : array[0..3] of TVertex;
  txtvert    : array[0..3] of TVertex;
  tw, th, poffs     : single;
begin
  if texhandle = 0 then AllocateTexture;

  glBindTexture(GL_TEXTURE_2D, texhandle);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, bmp_width, bmp_height, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, data);

  // the whole screen is translated with 0.5 and 0.5 pixels for the shape drawing
  // for the textures this is not good so it should be reveted
  // how the 0.25 comes out I'm not totally sure, but only with this value look the textures pixel aligned.
  poffs := -0.25;
  framevert[0][0] := poffs;
  framevert[0][1] := poffs;
  framevert[1][0] := fwidth + poffs;
  framevert[1][1] := poffs;
  framevert[2][0] := fwidth + poffs;
  framevert[2][1] := fheight + poffs;
  framevert[3][0] := poffs;
  framevert[3][1] := fheight + poffs;

  glBindVertexArray(vao);
  glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
  glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(TVertex), @framevert[0], GL_STATIC_DRAW);

  glEnableVertexAttribArray(attrloc_position);
  glVertexAttribPointer(attrloc_position, 2, GL_FLOAT, false, 0, nil);

  // texture coordinates

  tw := fwidth / bmp_width;  // the bmp_width might be bigger (must be divisible by 4)
  th := fheight / bmp_height;

  txtvert[0][0] := 0;
  txtvert[0][1] := 0;
  txtvert[1][0] := tw;
  txtvert[1][1] := 0;
  txtvert[2][0] := tw;
  txtvert[2][1] := th;
  txtvert[3][0] := 0;
  txtvert[3][1] := th;

  glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
  glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(TVertex), @txtvert[0], GL_STATIC_DRAW);

  glEnableVertexAttribArray(attrloc_texcoordinate);
  glVertexAttribPointer(attrloc_texcoordinate, 2, GL_FLOAT, false, 0, nil);

  needsupdate := false;
end;

procedure TAlphaMap.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
var
  rmatrix : TMatrix;
  ralpha  : TddFloat;
begin
  UpdateMatrix();  // calculates self.matrix from scale[xy], rotation, +[xy]

  // calculate rmatrix, ralpha
  ddmat_mul(rmatrix, self.matrix, apmatrix);
  ralpha := apalpha * self.alpha;

  // select the proper shader for texture drawing:
  texshader_alpha.Activate();

  // pass the matrix to the shader
  texshader_alpha.SetMVPMatrix(rmatrix);
  texshader_alpha.SetTexture(texhandle);
  texshader_alpha.SetColor(color.r, color.g, color.b, color.a * ralpha);

  if needsupdate then UpdateTexture;

  {$if 1}
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  {$else}
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  {$endif}

  glBindVertexArray(vao);
  glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

end;

procedure TAlphaMap.SetColor(r, g, b : TddFloat);
begin
  color.r := r;
  color.b := b;
  color.g := g;
  color.a := 1;
end;

procedure TAlphaMap.SetColor(r, g, b, a : TddFloat);
begin
  color.r := r;
  color.b := b;
  color.g := g;
  color.a := a;
end;

procedure TAlphaMap.SetSize(awidth, aheight : integer);
var
  new_bw, new_bh : integer;
begin
  fwidth  := awidth;
  fheight := aheight;

  new_bw := ((awidth  + 3) and $FFFFC);
  new_bh := ((aheight + 3) and $FFFFC);
  if (new_bw = bmp_width) and (new_bh = bmp_height)
  then
      Exit;

  bmp_width  := new_bw;
  bmp_height := new_bh;

  if data <> nil then FreeMem(data);
  GetMem(data, bmp_width * bmp_height);
end;

{ TTextBox }

procedure TTextBox.SetText(AValue : string);
var
  text_width  : integer;
  text_height : integer;
begin
  if ftext = AValue then Exit;

  ftext := AValue;
  frendertext := true;

  text_width  := fsface.TextWidth(UnicodeString(ftext));
  text_height := fsface.Height;

  SetSize(text_width, text_height);
end;

procedure TTextBox.DoRenderText;
begin

end;

constructor TTextBox.Create(aparent : TDrawGroup; afsace : TSizedFont; atext : string);
begin
  inherited Create(aparent, 4, 4);  // start with some dummy size

  fsface := afsace;

  needsupdate := true;
  frendertext := true;

  ftext := atext + ' ';  // something different
  SetText(atext);
end;

destructor TTextBox.Destroy;
begin
  inherited;
end;

procedure TTextBox.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
begin
  if frendertext then
  begin
    Clear(0);
    fsface.RenderToAlphaBmp(UnicodeString(ftext), 0, 0, data, bmp_width, bmp_height);
    //writeln('Font height: ', fsface.Height);
    //writeln('Font asc   : ', fsface.Ascender);
    //writeln('Font desc  : ', fsface.Descender);
    needsupdate := true;
  end;

  inherited;
end;


{ TDrawGroup }

constructor TDrawGroup.Create(aparent : TDrawGroup);
begin
  SetLength(children, 0);

  inherited Create(aparent);
end;

destructor TDrawGroup.Destroy;
begin
  while length(children) > 0 do
  begin
    children[0].Free;
  end;
  inherited Destroy;
end;

procedure TDrawGroup.AddChild(adr : TDrawable);
begin
  SetLength(children, length(children) + 1);
  children[length(children) - 1] := adr;
  adr.parent := self;
end;

procedure TDrawGroup.RemoveChild(adr : TDrawable; afreeit : boolean);
var
  idx : integer;
begin
  for idx := 0 to length(children) do
  begin
    if children[idx] = adr then
    begin
      delete(children, idx, 1);
      if afreeit then
      begin
        adr.Free;
      end;
      EXIT;
    end;
  end;
end;

procedure TDrawGroup.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
var
  rmatrix : TMatrix;
  ralpha  : TddFloat;
  drobj   : TDrawable;
begin
  UpdateMatrix();  // calculates self.matrix from scale[xy], rotation, +[xy]

  // calculate rmatrix, ralpha
  ddmat_mul(rmatrix, self.matrix, apmatrix);
  ralpha := apalpha * self.alpha;

  for drobj in children do
  begin
    if drobj.visible then
    begin
      drobj.Draw(rmatrix, ralpha);
    end;
  end;
end;

function TDrawGroup.NewGroup : TDrawGroup;
begin
  result := TDrawGroup.Create(self);
end;

function TDrawGroup.NewShape : TShape;
begin
  result := TShape.Create(self);
end;

function TDrawGroup.NewPixmap(awidth, aheight : integer) : TPixmap;
begin
  result := TPixmap.Create(self, awidth, aheight);
end;

function TDrawGroup.CloneShape(aoriginal : TShape) : TClonedShape;
begin
  result := TClonedShape.Create(self, aoriginal);
end;

function TDrawGroup.CloneGroup(aoriginal : TDrawGroup) : TClonedGroup;
begin
  result := TClonedGroup.Create(self, aoriginal);
end;

procedure TDrawGroup.MoveTo(aobj : TDrawable; topos : integer);
var
  si : integer;
begin
  si := FindIndex(aobj);
  if si < 0 then EXIT;
  delete(children, si, 1);
  insert(aobj, children, topos);
end;

procedure TDrawGroup.MoveTop(aobj : TDrawable);
begin
  MoveTo(aobj, length(children));
end;

procedure TDrawGroup.MoveBottom(aobj : TDrawable);
begin
  MoveTo(aobj, 0);
end;

function TDrawGroup.FindIndex(aobj : TDrawable) : integer;
var
  i : integer;
begin
  for i := 0 to length(children) do
  begin
    if children[i] = aobj then EXIT(i);
  end;
  result := -1;
end;

{ TClonedGroup }

constructor TClonedGroup.Create(aparent : TDrawGroup; aoriginal : TDrawGroup);
begin
  inherited Create(aparent);
  original := aoriginal;
  if original <> nil then
  begin
    CopyProperties(original);
  end;
end;

destructor TClonedGroup.Destroy;
begin
  inherited Destroy;
end;

procedure TClonedGroup.Draw(const apmatrix : TMatrix; apalpha : TddFloat);
var
  rmatrix : TMatrix;
  ralpha  : TddFloat;
  drobj   : TDrawable;
begin
  UpdateMatrix();  // calculates self.matrix from scale[xy], rotation, +[xy]

  // calculate rmatrix, ralpha
  ddmat_mul(rmatrix, self.matrix, apmatrix);
  ralpha := apalpha * self.alpha;

  for drobj in original.children do
  begin
    if drobj.visible then
    begin
      drobj.Draw(rmatrix, ralpha);
    end;
  end;
end;

{ TddScene }

constructor TddScene.Create(aowner : TComponent; aparent : TWinControl);
begin
  inherited Create(aowner);
  auto_swap_buffer := true;
  parent := aparent;
  name := 'ddScene';

  ddmat_identity(mat_projection);

  root := TDrawGroup.Create(nil);  // no parent here

  Align := alClient; // fill the client area

  OpenGLMajorVersion := 3;   // This is important in order to use OpenGL Context 3.3
  OpenGLMinorVersion := 3;

  bgcolor.r := 0;
  bgcolor.g := 0;
  bgcolor.b := 0;
  bgcolor.a := 1;

  InitOpenGL;

  MakeCurrent;

  ReadExtensions;
  ReadImplementationProperties;

  glEnable(GL_BLEND);                                // Alphablending an
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // Sortierung der Primitiven von hinten nach vorne.

  //glXSwapIntervalEXT(GetDefaultXDisplay, nil, 0);

  if shader_fixcolor = nil then shader_fixcolor := TShaderFixcolor.Create;
  if texshader_rgba  = nil then texshader_rgba  := TTextureShaderRgba.Create;
  if texshader_alpha = nil then texshader_alpha := TTextureShaderAlpha.Create;

  shader_fixcolor.Activate;
end;

destructor TddScene.Destroy;
begin
  root.Free;

  shader_fixcolor.Free;

  inherited Destroy;
end;

procedure TddScene.DoOnResize;
begin
  inherited DoOnResize;

  // do some resize the scene...
end;

procedure TddScene.SetViewPort(awidth, aheight : integer);
begin
  glViewport(0, 0, awidth, aheight);

  mat_projection[0] := 2 / awidth;
  mat_projection[1] := 0;

  mat_projection[2] := 0;
  mat_projection[3] := -2 / aheight;

  mat_projection[4] := -1 + 0.5 / awidth;   // add half-pixel shift for targeting the middle of the pixels
  mat_projection[5] :=  1 - 0.5 / aheight;  // add half-pixel shift for targeting the middle of the pixels
end;

procedure TddScene.DoOnPaint;
var
  t0, t1, t2 : int64;
begin
  t0 := nstime();

  inherited DoOnPaint;  // calls the OnPaint handler

  if not MakeCurrent() then
  begin
    Exit;  // do not go on on errors
  end;

  // 1. prepare the drawing

  SetViewPort(self.Width, self.Height); // calculates the projection matrix

  glClearColor(bgcolor.r, bgcolor.g, bgcolor.b, bgcolor.a);
  glClear(GL_COLOR_BUFFER_BIT);  // initialize the framebuffer with the background color

  // 2. do the drawing....
  root.Draw(mat_projection, 1);

  t1 := nstime();
  render_time_ns := t1 - t0;

  // 3. show results on the screen. May be synchronized to the refresh rate
  if auto_swap_buffer then
  begin
    SwapBuffers;
  end;

  t2 := nstime();
  swap_time_ns := t2 - t1;
end;

initialization

begin
  activeshader := nil;
  shader_fixcolor := nil;
  texshader_rgba := nil;
  texshader_alpha := nil;
end;

end.

