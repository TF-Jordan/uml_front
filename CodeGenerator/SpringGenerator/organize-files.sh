#!/bin/bash

# Vérification de la fourniture du paramètre
if [ -z "$1" ]; then
    echo "Erreur: Vous devez fournir un nom de projet"
    echo "Usage: $0 <nom-du-projet>"
    exit 1
fi

# Récupérer le nom du projet
PROJECT_NAME="$1"

# Vérifier que le projet existe
if [ ! -d "$PROJECT_NAME" ]; then
    echo "Erreur: Le projet '$PROJECT_NAME' n'existe pas"
    exit 1
fi

# Définir les catégories de fichiers (singulier dans les noms de fichiers)
declare -A CATEGORIES
CATEGORIES["exception"]="exceptions"
CATEGORIES["config"]="configs"
CATEGORIES["controller"]="controllers"
CATEGORIES["dto"]="dto"
CATEGORIES["enum"]="enums"
CATEGORIES["model"]="models"
CATEGORIES["repository"]="repository"
CATEGORIES["service"]="services"

echo "Organisation des fichiers pour le projet: $PROJECT_NAME"
echo "=========================================="
echo ""

# Compteurs
MOVED_COUNT=0
SKIPPED_COUNT=0

# Parcourir tous les fichiers .java dans le répertoire courant
for file in *.java; do
    # Vérifier si le fichier existe (évite l'erreur si aucun .java n'existe)
    if [ ! -f "$file" ]; then
        echo "Aucun fichier .java trouvé dans le répertoire courant"
        break
    fi
    
    # Extraire le nom du fichier sans extension
    filename=$(basename "$file" .java)
    
    # Variable pour savoir si le fichier a été déplacé
    moved=false
    
    # Vérifier chaque catégorie
    for category_singular in "${!CATEGORIES[@]}"; do
        category_plural="${CATEGORIES[$category_singular]}"
        
        # Vérifier si le nom du fichier se termine par _<catégorie au singulier>
        if [[ "$filename" =~ _${category_singular}$ ]]; then
            # Chemin de destination (avec le nom au pluriel)
            dest_dir="../codeGenerator/$PROJECT_NAME/src/main/java/com/example/$PROJECT_NAME/$category_plural"
            
            # Vérifier que le répertoire de destination existe
            if [ ! -d "$dest_dir" ]; then
                echo "⚠ Attention: Le répertoire $dest_dir n'existe pas"
                continue
            fi
            
            # Déplacer le fichier
            mv "$file" "$dest_dir/"
            echo "✓ Déplacé: $file → $category_plural/"
            MOVED_COUNT=$((MOVED_COUNT + 1))
            moved=true
            break
        fi
    done
    
    # Si le fichier n'a pas été déplacé
    if [ "$moved" = false ]; then
        echo "✗ Ignoré: $file (ne correspond à aucune catégorie)"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    fi
done

echo ""
echo "=========================================="
echo "Résumé:"
echo "  - Fichiers déplacés: $MOVED_COUNT"
echo "  - Fichiers ignorés: $SKIPPED_COUNT"
echo ""
echo "Organisation terminée!"
