@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
cd /D %~dp0

if not exist compressed (
    md compressed
)

set encoder_list=hevc_nvenc hevc_amf hevc_qsv
set "preset=veryslow"

:again
set "input=%~1"
if "%input%"=="" goto end

if not exist "!input!" (
    echo Ошибка: входной файл "!input!" не найден.
    shift
    goto again
)

set "name=%~n1.mp4"
echo.
echo === Обработка: %input% ===

set "encoded=0"

for %%E in (%encoder_list%) do (
    set "encoder=%%E"

     if "!encoder!"=="hevc_nvenc" (
        set "vopts=-c:v hevc_nvenc -preset p7 -rc constqp -qp 27 !vf!"
    ) else if "!encoder!"=="hevc_amf" (
        set "vopts=-c:v hevc_amf -quality quality -qp_p 27 -qp_i 27 -qp_b 27 -pix_fmt yuv420p !vf!"
    ) else if "!encoder!"=="hevc_qsv" (
        set "vopts=-c:v hevc_qsv -global_quality 27 -look_ahead 1 -pix_fmt nv12 !vf!"
    )

    echo Пытаемся использовать: !encoder!
    set "outfile=compressed/!name!"
    ffmpeg.exe -y -hide_banner -loglevel info -i "!input!" !vopts! -movflags +faststart -c:a libopus -ac 2 -b:a 128k "!outfile!"

    if exist "!outfile!" (
        for %%S in ("!outfile!") do set "size=%%~zS"
        if !size! gtr 0 (
            echo Успешно закодировано с помощью: !encoder!
            set "encoded=1"
            goto done
        ) else (
            echo Кодировщик !encoder! создал пустой файл. Пробуем следующий...
            del "!outfile!" >nul 2>&1
        )
    ) else (
        echo Кодировщик !encoder! не создал файл. Пробуем следующий...
    )
)

:done
if "!encoded!"=="0" (
    echo.
    echo === Ошибка: не удалось обработать файл %input% ни с одниим кодировщиком ===
) else (
    echo Готово!
)

shift
goto again

:end
pause