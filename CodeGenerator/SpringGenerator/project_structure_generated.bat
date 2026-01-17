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

echo Création de la hiérarchie pour le projet: %PROJECT_NAME%

REM Créer la structure de répertoires
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\exceptions" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\configs" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\controllers" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\dto" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\enums" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\models" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\repository" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\java\com\example\%PROJECT_NAME%\services" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\main\resources" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\test\java\com\example\%PROJECT_NAME%" 2>nul
mkdir "%..\codeGenerator\PROJECT_NAME%\src\test\resources" 2>nul

REM Créer le fichier pom.xml
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<project xmlns="http://maven.apache.org/POM/4.0.0"
echo          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
echo          xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
echo          http://maven.apache.org/xsd/maven-4.0.0.xsd"^>
echo     ^<modelVersion^>4.0.0^</modelVersion^>
echo.    
echo     ^<groupId^>com.example^</groupId^>
echo     ^<artifactId^>%PROJECT_NAME%^</artifactId^>
echo     ^<version^>1.0-SNAPSHOT^</version^>
echo.    
echo     ^<properties^>
echo         ^<maven.compiler.source^>17^</maven.compiler.source^>
echo         ^<maven.compiler.target^>17^</maven.compiler.target^>
echo         ^<project.build.sourceEncoding^>UTF-8^</project.build.sourceEncoding^>
echo         ^<lombok.version^>1.18.30^</lombok.version^>
echo         ^<hibernate.version^>6.3.1.Final^</hibernate.version^>
echo         ^<mysql.version^>8.0.33^</mysql.version^>
echo     ^</properties^>
echo.
echo     ^<dependencies^>
echo         ^<!-- Lombok --^>
echo         ^<dependency^>
echo             ^<groupId^>org.projectlombok^</groupId^>
echo             ^<artifactId^>lombok^</artifactId^>
echo             ^<version^>${lombok.version}^</version^>
echo             ^<scope^>provided^</scope^>
echo         ^</dependency^>
echo.
echo         ^<!-- JPA / Hibernate --^>
echo         ^<dependency^>
echo             ^<groupId^>org.hibernate.orm^</groupId^>
echo             ^<artifactId^>hibernate-core^</artifactId^>
echo             ^<version^>${hibernate.version}^</version^>
echo         ^</dependency^>
echo.
echo         ^<!-- MySQL Connector --^>
echo         ^<dependency^>
echo             ^<groupId^>com.mysql^</groupId^>
echo             ^<artifactId^>mysql-connector-j^</artifactId^>
echo             ^<version^>${mysql.version}^</version^>
echo         ^</dependency^>
echo.
echo         ^<!-- Jakarta Persistence API --^>
echo         ^<dependency^>
echo             ^<groupId^>jakarta.persistence^</groupId^>
echo             ^<artifactId^>jakarta.persistence-api^</artifactId^>
echo             ^<version^>3.1.0^</version^>
echo         ^</dependency^>
echo     ^</dependencies^>
echo.
echo     ^<build^>
echo         ^<plugins^>
echo             ^<plugin^>
echo                 ^<groupId^>org.apache.maven.plugins^</groupId^>
echo                 ^<artifactId^>maven-compiler-plugin^</artifactId^>
echo                 ^<version^>3.11.0^</version^>
echo                 ^<configuration^>
echo                     ^<source^>17^</source^>
echo                     ^<target^>17^</target^>
echo                     ^<annotationProcessorPaths^>
echo                         ^<path^>
echo                             ^<groupId^>org.projectlombok^</groupId^>
echo                             ^<artifactId^>lombok^</artifactId^>
echo                             ^<version^>${lombok.version}^</version^>
echo                         ^</path^>
echo                     ^</annotationProcessorPaths^>
echo                 ^</configuration^>
echo             ^</plugin^>
echo         ^</plugins^>
echo     ^</build^>
echo ^</project^>
) > "%PROJECT_NAME%\pom.xml"

echo.
echo Structure créée avec succès!
echo.
echo Pour ouvrir dans IntelliJ: File -^> Open -^> Sélectionnez le dossier '%..\codeGenerator\PROJECT_NAME%'

endlocal
