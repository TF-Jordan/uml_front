#!/bin/bash

#Vérification de la fourniture du paramètre

if [ -z "$1" ]; then
    echo "Erreur: Vous devez fournir un nom de projet"
    echo "Usage: $0 <nom-du-projet>"
    exit 1
fi

#Récuperer le nom du projet depuis le parametre
PROJECT_NAME="$1"

echo "Création de la hiérarchie pour le projet: $PROJECT_NAME"

#Créer la structure de repertoires

mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/exeptions"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/configs"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/controllers"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/dto"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/enums"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/models"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/repository"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/services"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/main/resources"
mkdir -p "../codeGenerator/$PROJECT_NAME/test/java/com/example/$PROJECT_NAME"
mkdir -p "../codeGenerator/$PROJECT_NAME/src/test/resources"


# Créer le fichier pom.xml
cat > "$PROJECT_NAME/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>com.example</groupId>
    <artifactId>$PROJECT_NAME</artifactId>
    <version>1.0-SNAPSHOT</version>
    
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <lombok.version>1.18.30</lombok.version>
        <hibernate.version>6.3.1.Final</hibernate.version>
        <mysql.version>8.0.33</mysql.version>
    </properties>

    <dependencies>
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <version>\${lombok.version}</version>
            <scope>provided</scope>
        </dependency>

        <!-- JPA / Hibernate -->
        <dependency>
            <groupId>org.hibernate.orm</groupId>
            <artifactId>hibernate-core</artifactId>
            <version>\${hibernate.version}</version>
        </dependency>

        <!-- MySQL Connector -->
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <version>\${mysql.version}</version>
        </dependency>

        <!-- Jakarta Persistence API -->
        <dependency>
            <groupId>jakarta.persistence</groupId>
            <artifactId>jakarta.persistence-api</artifactId>
            <version>3.1.0</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.11.0</version>
                <configuration>
                    <source>17</source>
                    <target>17</target>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>\${lombok.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
EOF

echo "✓ Structure créée avec succès!"
echo ""
echo "Structure du projet:"
tree "../codeGenerator/$PROJECT_NAME" 2>/dev/null || find "$PROJECT_NAME" -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
echo ""
echo "Pour ouvrir dans IntelliJ: File → Open → Sélectionnez le dossier '$PROJECT_NAME'"
