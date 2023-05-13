unit Unit1;

interface

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
  Vcl.Graphics,
{$ENDIF}
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  FMX.Objects,
  FMX.Utils,
  System.ImageList,
  FMX.ImgList,
  FMX.ListBox,
  FaceLandmarkFMX
  ;

type
  TForm1 = class(TForm)
    ImageMain: TImage;
    btnOpenImage: TButton;
    btnDetect: TButton;
    OpenDialog: TOpenDialog;
    ImageList: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDetectClick(Sender: TObject);
    procedure btnOpenImageClick(Sender: TObject);
  private
    FFaceLandmarkFMX: TFaceLandmarkFMX;
  public
    procedure LoadImage;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}


const
  ModelsPath = '..\..\..\..\..\models\';

procedure TForm1.LoadImage;
begin
{$IFDEF MSWINDOWS}
  if not FileExists(OpenDialog.FileName) then
    Exit;

  if ImageMain.MultiResBitmap.Count > 0 then
    ImageMain.MultiResBitmap[0].Free;

  ImageMain.MultiResBitmap.Add;

  if FileExists(OpenDialog.FileName) then
  begin
    if ImageList.Source[0].MultiResBitmap.Count > 0 then
      ImageList.Source[0].MultiResBitmap[0].Free;

    ImageList.Source[0].MultiResBitmap.Add;
    ImageList.Source[0].MultiResBitmap[0].Bitmap.LoadFromFile(OpenDialog.FileName);
  end;

  ImageMain.Bitmap.Assign(ImageList.Source[0].MultiResBitmap[0].Bitmap);

{$ENDIF MSWINDOWS}
end;

procedure TForm1.btnOpenImageClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    LoadImage;
end;

procedure TForm1.btnDetectClick(Sender: TObject);
var
  I: DWORD;
  LFaceLandmarkData: TFaceLandmarkData;
begin
  LoadImage;

  LFaceLandmarkData := FFaceLandmarkFMX.GetLandmarkData(ImageMain.Bitmap);

  ImageMain.Bitmap.Canvas.BeginScene;
  try
    ImageMain.Bitmap.Canvas.Fill.Color := TAlphaColorRec.White;
    ImageMain.Bitmap.Canvas.Stroke.Color := TAlphaColorRec.White;

    for I := 0 to LFaceLandmarkData.Count - 1 do
    begin
      ImageMain.Bitmap.Canvas.FillRect(
        RectF(
        LFaceLandmarkData.Points[I].X,
        LFaceLandmarkData.Points[I].Y,
        LFaceLandmarkData.Points[I].X + 5,
        LFaceLandmarkData.Points[I].Y + 5),
        0, 0, AllCorners, 1);
    end;

  finally
    ImageMain.Bitmap.Canvas.EndScene;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  SetPriorityClass(GetCurrentProcess, HIGH_PRIORITY_CLASS);

  FFaceLandmarkFMX := TFaceLandmarkFMX.Create(Self);
  FFaceLandmarkFMX.LoadModel(ModelsPath + 'face_landmark.tflite', 8);
{$ENDIF}
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FFaceLandmarkFMX.Destroy;
end;

end.
