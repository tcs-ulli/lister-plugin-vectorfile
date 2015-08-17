library vectorfile;

{$mode objfpc}{$H+}
{$include calling.inc}

uses
  Classes,
  sysutils,
  WLXPlugin,
  fpcanvas, fpvectorial, fpvtocanvas, fpimage, FPImgCanv,dxfvectorialreader,pdfvectorialreader,
  cdrvectorialreader,docxvectorialwriter,svgvectorialreader,svgzvectorialreader,
  odgvectorialreader,mathmlvectorialreader,epsvectorialreader,lazvectorialreader,
  lasvectorialreader,htmlvectorialreader,Graphics,Forms, Interfaces;

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
  Vec: TvVectorialDocument;
  CanvasSize: TPoint;
  aFile : string;
  Picture : TPicture;
  Canvas: TCanvas;
  aBitmap : TBitmap;
begin
  Result := '';
  // First check the in input
  //if not CheckInput() then Exit;

  Picture := TPicture.Create;
  Vec := TvVectorialDocument.Create;
  try
    Vec.ReadFromFile(FileToLoad);


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

    aBitmap := TBitmap.Create;
    aBitmap.Width:=CanvasSize.x;
    aBitmap.Height:=CanvasSize.y;
    Canvas := aBitmap.Canvas;

    Canvas.Brush.Color := clWhite;
    Canvas.Brush.Style := bsSolid;
    Canvas.FillRect(0, 0, CanvasSize.x, CanvasSize.y);
    try
      DrawFPVectorialToCanvas(
        TvVectorialPage(Vec.GetPage(0)),
        Canvas,
        FPVVIEWER_SPACE_FOR_NEGATIVE_COORDS,
        CanvasSize.y - FPVVIEWER_SPACE_FOR_NEGATIVE_COORDS,
        Scale,
        -1 * Scale);
      Picture.Assign(aBitmap);
      Picture.SaveToFile(OutputPath+'thumb.png');
      aFile := OutputPath+'thumb.png';
      Result := PChar(aFile);
    except
      Result := '';
    end;
  finally
    aBitmap.Free;
    Picture.Free;
    Vec.Free;
  end;
end;

exports
  ListGetDetectString,
  ListGetPreviewBitmapFile;

begin
  Application.Initialize;
end.

