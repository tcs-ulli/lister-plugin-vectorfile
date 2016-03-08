library vectorfile;

{$mode objfpc}{$H+}
{$include calling.inc}

uses
  Classes,
  sysutils,
  WLXPlugin,
  fpcanvas, fpvectorial, fpvtocanvas, fpimage, FPImgCanv,dxfvectorialreader{,pdfvectorialreader},
  cdrvectorialreader,docxvectorialwriter,svgvectorialreader,svgzvectorialreader,
  odgvectorialreader,mathmlvectorialreader,epsvectorialreader,lazvectorialreader,
  lasvectorialreader,htmlvectorialreader, fpvectorialpkg_nogui,FPWritePNG;

procedure ListGetDetectString(DetectString:pchar;maxlen:integer); dcpcall;
begin
  //EXT="PDF"|
  StrCopy(DetectString, 'EXT="CDR"|EXT="DOCX"|EXT="DXF"|EXT="SVG"|EXT="SVGZ"|EXT="ODG"|EXT="MML"|EXT="PS"|EXT="LAZ"|EXT="LAS"|EXT="HTML"');
end;

function ListGetPreviewBitmapFile(FileToLoad:pchar;OutputPath:pchar;width,height:integer;
    contentbuf:pchar;contentbuflen:integer):pchar; dcpcall;
const
  FPVVIEWER_MAX_IMAGE_SIZE = 1000;
  FPVVIEWER_MIN_IMAGE_SIZE = 100;
  FPVVIEWER_SPACE_FOR_NEGATIVE_COORDS = 100;
var
  Scale : double = 1.0;
  Vec: TvVectorialDocument = nil;
  CanvasSize: TPoint;
  Drawer: TFPMemoryImage;
  Canvas: TFPImageCanvas;
  DeltaX: Integer;
  DeltaY: Integer;
  aPage: TvVectorialPage;
begin
  Result := '';
  // First check the in input
  //if not CheckInput() then Exit;

  Vec := TvVectorialDocument.Create;
  try
    try
      Vec.ReadFromFile(FileToLoad);
    except
      begin
        FreeAndNil(vec);
        exit;
      end;
    end;

    // We need to be robust, because sometimes the document size won't be given
    // also give up drawing everything if we need more then 4MB of RAM for the image
    // and also give some space in the image to allow for negative coordinates
    if Vec.Width * Scale > FPVVIEWER_MAX_IMAGE_SIZE then CanvasSize.X := FPVVIEWER_MAX_IMAGE_SIZE
    else if Vec.Width < FPVVIEWER_MIN_IMAGE_SIZE then CanvasSize.X := Width
    else CanvasSize.X := Round(Vec.Width * Scale);
    if CanvasSize.X < Width then CanvasSize.X := Width;

    if Vec.Height * Scale > FPVVIEWER_MAX_IMAGE_SIZE then CanvasSize.Y := FPVVIEWER_MAX_IMAGE_SIZE
    else  if Vec.Height < FPVVIEWER_MIN_IMAGE_SIZE then CanvasSize.Y := Height
    else CanvasSize.Y := Round(Vec.Height * Scale);
    if CanvasSize.Y < Height then CanvasSize.Y := Height;

    Drawer := TFPMemoryImage.create(CanvasSize.X,CanvasSize.Y);
    Canvas := TFPImageCanvas.create(Drawer);

    Canvas.Brush.FPColor := colWhite;
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(0, 0, Drawer.Width, Drawer.Height);
    try
      aPage := TvVectorialPage(Vec.GetPage(0));
      aPage.AutoFit(canvas,Drawer.Width,Drawer.Height,Drawer.Height,DeltaX,DeltaY,Scale);
      aPage.Render(Canvas,DeltaX,DeltaY,Scale,Scale);
      Drawer.SaveToFile(OutputPath+'thumb.png');
      Result := PChar(OutputPath+'thumb.png');
    except
      Result := '';
    end;
  finally
    Drawer.Free;
    FreeAndNil(Vec);
  end;
end;

function ListGetText(FileToLoad:pchar;contentbuf:pchar;contentbuflen:integer):pchar; dcpcall;
var
  aPage: TvVectorialPage;
  Vec: TvVectorialDocument = nil;
  tmpRes : string = '';
  i: Integer;
begin
  Result := '';
  // First check the in input
  //if not CheckInput() then Exit;

  Vec := TvVectorialDocument.Create;
  try
    try
      Vec.ReadFromFile(FileToLoad);
    except
      begin
        FreeAndNil(vec);
        exit;
      end;
    end;

    try
      aPage := TvVectorialPage(Vec.GetPage(0));
      for i := 0 to aPage.GetEntitiesCount-1 do
        if aPage.Entities[i] is TvText then
          tmpRes+=TvText(aPage.Entities[i]).Value.Text+' ';
      Result := PChar(tmpRes);
    except
      Result := '';
    end;
  finally
    FreeAndNil(Vec);
  end;
end;

exports
  ListGetDetectString,
  ListGetPreviewBitmapFile,
  ListGetText;

begin
end.

