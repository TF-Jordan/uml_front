@echo off
setlocal enabledelayedexpansion

REM Vérification de la fourniture du paramètre
if "%~1"=="" (
    echo Erreur: Vous devez fournir un nom de projet
    echo Usage: %~nx0 ^<nom-du-projet^>
    exit /b 1
)

REM Récupérer le nom du projet
set PROJECT_NAME=%~1

REM Vérifier que le projet existe
if not exist "%PROJECT_NAME%" (
    echo Erreur: Le projet '%PROJECT_NAME%' n'existe pas
    exit /b 1
)

echo Organisation des fichiers pour le projet: %PROJECT_NAME%
echo ==========================================
echo.

REM Compteurs
set MOVED_COUNT=0
set SKIPPED_COUNT=0

REM Parcourir tous les fichiers .java dans le répertoire courant
for %%f in (*.java) do (
    set "file=%%f"
    set "filename=%%~nf"
    set "moved=false"
    
    REM Vérifier exception
    echo !filename! | findstr /r "_exception$" >nul
    if !errorlevel! equ 0 (
        set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\exceptions"
        if exist "!dest_dir!" (
            move "%%f" "!dest_dir!\" >nul
            echo Déplacé: %%f -^> exceptions/
            set /a MOVED_COUNT+=1
            set "moved=true"
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier config
        echo !filename! | findstr /r "_config$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\configs"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> configs/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier controller
        echo !filename! | findstr /r "_controller$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\controllers"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> controllers/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier dto
        echo !filename! | findstr /r "_dto$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\dto"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> dto/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier enum
        echo !filename! | findstr /r "_enum$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\enums"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> enums/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier model
        echo !filename! | findstr /r "_model$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\models"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> models/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier repository
        echo !filename! | findstr /r "_repository$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\repository"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> repository/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        REM Vérifier service
        echo !filename! | findstr /r "_service$" >nul
        if !errorlevel! equ 0 (
            set "dest_dir=%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\services"
            if exist "!dest_dir!" (
                move "%%f" "!dest_dir!\" >nul
                echo Déplacé: %%f -^> services/
                set /a MOVED_COUNT+=1
                set "moved=true"
            )
        )
    )
    
    if "!moved!"=="false" (
        echo Ignoré: %%f (ne correspond à aucune catégorie)
        set /a SKIPPED_COUNT+=1
    )
)

echo.
echo ==========================================
echo Résumé:
echo   - Fichiers déplacés: %MOVED_COUNT%
echo   - Fichiers ignorés: %SKIPPED_COUNT%
echo.
echo Organisation terminée!

endlocal

