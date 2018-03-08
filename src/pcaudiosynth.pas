program pcaudiosynth;

{$mode objfpc}{$H+}
   {$DEFINE UseCThreads}
uses
{$IFDEF UNIX}
  cthreads, 
  cwstring, {$ENDIF}
  Classes,
  SysUtils,
  ctypes,
  CustApp,
  pcaudio;

type

  TConsole = class(TCustomApplication)
  private
    procedure ConsolePlay;
  protected
    procedure doRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
  end;

var
freqsine : cfloat = 150.0;
samplerate : cfloat = 44100.0;
audioobj : paudio_object = nil;
lensine, ratio : cfloat;
posine : integer;
ordir, opath, pc_FileName, libname: string;
x : integer = 0;
typformat : integer = 0;
ps : array of cint16;
pl : array of cint32;
pf : array of cfloat; 

procedure ReadSynth;  
var
x2 : integer = 0;
begin
  
   case typformat of
  0: while x2 < length(ps) -1 do
  begin
  ps[x2] := round( Sin((((x2 div 2)+ posine)/ lensine ) * Pi * 2 )* 32767) ;
  ps[x2+1] :=  ps[x2];
     if posine +1 > lensine -1 then posine := 0 else
  posine := posine +1 ;
   x2 := x2 + 2 ;
  end;
  1: while x2 < length(pl) -1 do
  begin
  pl[x2] := round( Sin((((x2 div 2)+ posine)/ lensine ) * Pi * 2 )* 2147483647) ;
  pl[x2+1] :=  pl[x2];
     if posine +1 > lensine -1 then posine := 0 else
  posine := posine +1 ;
   x2 := x2 + 2 ;
  end;
  2: while x2 < length(pf) -1 do
  begin
  pf[x2] := ( Sin((((x2 div 2)+ posine)/ lensine ) * Pi * 2 )) ;
  pf[x2+1] :=  pf[x2];
     if posine +1 > lensine -1 then posine := 0 else
  posine := posine +1 ;
   x2 := x2 + 2 ;
  end;
  end;
   
   end;

  procedure TConsole.ConsolePlay;
  begin
    writeln('Sine Wave test.');
    writeln();
    
    {$IFDEF UNIX}
libname := 'libpcaudio.so.0';
   {$else}
libname := 'pcaudio.dll';
 {$ENDIF}
  
    ordir := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));


 {$IFDEF Windows}
     {$if defined(cpu64)}
    pc_FileName := ordir + 'lib\Windows\64bit\' + libname;
       {$else}
    pc_FileName := ordir + 'lib\Windows\32bit\' + libname;
     {$endif}
 {$ENDIF}

     {$if defined(cpu64) and defined(linux) }
    pc_FileName := ordir + 'lib/Linux/64bit/'+ libname;
    {$ENDIF}
   
   {$if defined(cpu86) and defined(linux)}
 pc_FileName := ordir + 'lib/Linux/32bit/'+ libname;
 {$ENDIF}
 
  {$if defined(linux) and defined(cpuarm)}
    pc_FileName := ordir + 'lib/Linux/arm_rpi/'+ libname;
  {$ENDIF}
 
 {$IFDEF freebsd}
    {$if defined(cpu64)}
    pc_FileName := ordir + 'lib/FreeBSD/64bit/'+ libname;
    {$else}
    pc_FileName := ordir + 'lib/FreeBSD/32bit/'+ libname;
    {$endif}
  {$ENDIF}

 {$IFDEF Darwin}
    opath := ordir;
    opath := copy(opath, 1, Pos('/UOS', opath) - 1);
    pc_FileName := opath + '/lib/Mac/32bit/libpcaudio.dylib';
 {$ENDIF}


   if pc_load(pc_FileName ) then
    writeln( pc_FileName + ' loaded.') else
    writeln(pc_FileName + ' NOT loaded.');
       
   setlength(ps,512*2);
   setlength(pl,512*2);
   setlength(pf,512*2);
   
   typformat := 0;
   
   while typformat < 3 do begin
  
   writeln();
    case typformat of
  0: writeln('Test sine-wave format integer 16 bit...');
  1: writeln('Test sine-wave format integer 32 bit...');
  2: writeln('Test sine-wave format float 32 bit...');
  end;
  
    freqsine := 150.0;
    lensine := samplerate / freqsine *2 ; 
    posine := 0 ;
    x := 0;
    
    {$IFDEF Windows} 
      ratio := 1; 
       {$else}
      if  typformat = 0 then ratio := 1.75 else ratio := 1; // Huh why ???
       {$endif}
   
   audioobj := create_audio_device_object(nil, nil, nil);
   
     if audioobj = nil then
    writeln('audioobj = nil ;(') else
    writeln('audioobj assigned.');

  case typformat of
  0: audio_object_open(audioobj, AUDIO_OBJECT_FORMAT_S16LE, 44100,2);
  1: audio_object_open(audioobj, AUDIO_OBJECT_FORMAT_S32LE, 44100,2);
  2: audio_object_open(audioobj, AUDIO_OBJECT_FORMAT_FLOAT32LE, 44100,2);
  end;

//audio_object_drain(audioobj); 
  {$IFDEF Windows}
   while x < round(2500 * ratio)  do
       {$else}
   while x < round(2700 * ratio)  do
     {$endif}

begin
if freqsine < 5000 then
freqsine := freqsine +1 ;
lensine := samplerate / freqsine *2 ; 
ReadSynth;
 case typformat of
  0: audio_object_write(audioobj,@ps[0], 512 ); 
  1: audio_object_write(audioobj,@pl[0], 512*2 ); 
  2: audio_object_write(audioobj,@pf[0], 512*2 ); 
  end;
inc(x);
end;

// audio_object_flush(audioobj);
// audio_object_drain(audioobj); 
 audio_object_close(audioobj);
 audio_object_destroy(audioobj);
 
 inc(typformat);
 
 sleep(500);
 end;

 end;

  procedure TConsole.doRun;
  begin
    ConsolePlay;
   writeln();
   writeln('Ciao...');
    pc_unload(); // Do not forget this !
    Terminate;   
  end;

constructor TConsole.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

var
  Application: TConsole;
begin
  Application := TConsole.Create(nil);
  Application.Title := 'Sine-Wave and Pcaudiolib';
  Application.Run;
  Application.Free;
end.
